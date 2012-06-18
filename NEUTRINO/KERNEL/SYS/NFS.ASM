; Copyright (C) 2011-2012 Alisson Linhares de Carvalho.
; All rights reserved.
;
; This file is part of the neutrino kernel.
;
; The neutrino kernel is free software: you can redistribute it and/or 
; modify it under the terms of the GNU General Public License as 
; published by the Free Software Foundation, either version 3 of the 
; License, or (at your option) any later version.

; The neutrino kernel is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with the neutrino kernel. If not, see <http://www.gnu.org/licenses/>.
;
;--------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------
;-----------------------------Área reservada para constantes---------------------------------
NFS_TOKEN                   EQU '\'
NFS_NAME_LENGTH             EQU 23
NFS_ROOT_SECTOR_PTR         EQU 2000 
NFS_ROOT_SECTOR_PTR_SIZE    EQU 1

NFS_SUBNODETYPE_INVALID     EQU 0
NFS_SUBNODETYPE_FOLDER      EQU 1
NFS_SUBNODETYPE_BINARY      EQU 2
NFS_SUBNODETYPE_LIBRARY     EQU 3
NFS_SUBNODETYPE_DATA        EQU 4
NFS_SUBNODETYPE_RESERVED    EQU 5

NFS_BOOTSECTOR_SIGNATURE    EQU "NFS!" 
;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para registros---------------------------------
;@description: Formato de um nó em disco.
struc tNode
	.subNodeList            RESD 1
endstruc

;@description: Formato de um subnó em disco.
struc tSubNode
	%macro RES_TSUBNODE 0-1 .
		%1dataPtr      RESD 1
		%1size         RESD 1
		%1type         RESB 1
		%1name         RESB NFS_NAME_LENGTH
	%endmacro
	
	RES_TSUBNODE
endstruc

;@description: Formato do registro de boot do Neutrino O.S.   
struc tBootSector
	.jmpArea                RESB 5                                 
	.signature              RESD 1   ;Assinatura do sistema de arquivos "NFS!" 
	.usedPages              RESD 1   ;Total de páginas em uso        
	.pageList               RESD 1   ;Lista de páginas                                          
	.rootNode:              RES_TSUBNODE .rootNode. ;Diretório raiz
	.code                   RESB 446 - tBootSector.code   ;Código de boot                     
	.bootIndicator          RESB 1   ;80h = botável, 0 = não botável  
	.startHeadNumber        RESB 1   ;0 - CHS 0,0,1
	.startCylinderNumber    RESW 1   ;1 - 0100h
	.descriptor             RESB 1   ;0Bh - FAT 32
	.lastHeadNumber         RESB 1   ;16
	.lastCylinderNumber     RESW 1   ;03FCFh
	.startingSector         RESD 1
	.partitionSize          RESD 1   ;207 * 16 * 63
	.reserved               RESB 510 - tBootSector.reserved
	.bootSignature          RESW 1   ;0AA55h
endstruc

;@description: Arquivo usado para troca de informações entre o kernel e a nlib.
struc tFileController
	.cache                  RESB MEMORY_PAGE_SIZE
	.currentPage            RESD 1
	.storage                RESD 1
	.dataPtr                RESD 1
	.size                   RESD 1
	.type                   RESB 1
	.error                  RESB 1
endstruc

;--------------------------------------------------------------------------------------------	
;@description: Função que procura por um Arquivo ou Pasta em disco usando o NFS¹.
;@input: ESI << String contendo o caminho completo do arquivo;
;@output: EDX >> tStorage, EBX >> página atual, EDI >> página do nó procurado e ESI >> Ponteiro para o final do último elemento encontrado
;@author: alisson_linhares@hotmail.com
nfs_Find:
	PUSH EAX
	PUSH ECX
	PUSH EBP         

	;Verifica se o token de separação está presente
	CMP BYTE[ESI + 1],NFS_TOKEN                 
	JNE .invalidDisk
		;Calculando o número da unidade (Selecionando disco)
		MOVZX EDX,BYTE[ESI]
		
		;Retirando o valor ASCII da letra e multiplicando pelo tamanho de um tStorage_size.
		SUB EDX,'a' 
		SHL EDX,4

		;Verifica se o número da unidade é válido
		CMP EDX,DWORD[storage.lastStorageIndex]               
		JAE .invalidDisk

			;Carregando em EDI o ponteiro para o buffer do disco. O sistema armazena em memória uma cópia do primeiro setor. 
			MOV EDI,DWORD[EDX +  storage.diskList + tStorage.buffer]

			;Verifica se o formato do disco é válido
			CMP DWORD[EDI + tBootSector.signature],NFS_BOOTSECTOR_SIGNATURE
			JNE .invalidDisk
                       
				;Configurando os registradores de retorno.
				MOV EBX,NFS_ROOT_SECTOR_PTR 
				ADD EDI,tBootSector.rootNode
				
				ADD ESI,2 ;Retira os caracteres usados na busca pelo disco
				
				;Ativando o semáforo para esse processo
				LEA EBP,[EDX + storage.diskList + tStorage.semaphore]
				CALL system_SemaphoreLock
				
				;Verifica se terminou a busca
				CMP BYTE[ESI],0
				JE .done
					;Fazendo EBP apontar para o final do buffer do disco.
					MOV EBP,DWORD[EDX +  storage.diskList + tStorage.buffer]
					ADD EBP,MEMORY_PAGE_SIZE
					MOV EAX,NFS_ROOT_SECTOR_PTR + NFS_ROOT_SECTOR_PTR_SIZE
					
					.findLoop:
						XOR ECX,ECX
						.nextByte:
							CMP BYTE[ESI + ECX],NFS_TOKEN
							JE .findNode       ;Procurando pelo token
							CMP BYTE[ESI + ECX],0
							JE .findSubNode    ;Procurando pelo final
							INC ECX
						CMP ECX,NFS_NAME_LENGTH ;Verifica se terminou a string                 
						JB .nextByte
						.findNode:
						
						;Verifica se o caminho é válido. Não pode existir duas barras seguidas "//".
						TEST ECX,ECX
						JZ .invalidPath

						;Fazendo EDI apontar para o final do token atual e limpando o NFS_TOKEN da string contendo o caminho 
						ADD ESI,ECX
						MOV EDI,ESI
						
						;Limpando token que será usado no nfs_FindSubNode. Em caso de erro a string que foi passada por ESI	fica com 0 no final do nó que não foi encontrado.	
						MOV BYTE[ESI],0
						
						;Procurando pelo subnode. Termina caso o sub nó não exista ou se o nó retornado não for do tipo pasta		
						CALL nfs_FindSubNode
						JC .invalidPath
						TEST BYTE[EDI + tSubNode.type],NFS_SUBNODETYPE_FOLDER
						JZ .invalidPath
						
						;Restaurando o valor do token
						MOV BYTE[ESI],NFS_TOKEN
						
						;ESI aponta para o próximo nome do subNode que deverá ser procurado
						INC ESI 
						CMP BYTE[ESI],0                          
						JE .done ;Verifica se terminou a string

						MOV EBX,DWORD[EDI + tSubNode.dataPtr]	 ;Ponteiro para o próximo subnode	
						MOV EAX,EBX
						ADD EAX,DWORD[EDI + tSubNode.size]	 ;EAX é o ponteiro para o final do nó
						JMP .findLoop
	.findSubNode:                        
		ADD ESI,ECX
		MOV EDI,ESI ;EDI aponta para o final do token atual
		;Procurando pelo último subnode
		CALL nfs_FindSubNode                     
		JNC .done ;Verifica se o subnó existe, caso contrario um erro é gerado	
	.invalidPath:
		;Desativando semáforo
		system_SemaphoreUnlock EDX + storage.diskList + tStorage.semaphore	
		
		;Informando ao kernel sobre o erro.
		PUSH DWORD NFS_INVALID_PATH
		CALL error_ThrowException
		JMP .done
	.invalidDisk:
		;Informando ao kernel sobre o erro.
		PUSH DWORD NFS_INVALID_DISK
		CALL error_ThrowException
	.done:

	POP EBP
	POP ECX
	POP EAX
	RET

;--------------------------------------------------------------------------------------------	
;@description: Função projetada para procurar um subnó no disco.
;@input: ECX << Tamanho do nome,  EDI << nome do nó procurado, EBP << buffer, EBX << setor do nó, EDX << tStorage, EAX << ponteiro para o final do nó
;@output: EBX >> setor atual, EDI >> posição do subnó  
;@author: alisson_linhares@hotmail.com
nfs_FindSubNode:
	PUSHAD
	
	;Criando um ponteiro para o final da página usada como buffer.
	ADD EBP,MEMORY_PAGE_SIZE
	JMP .readPage
	
	.newInteration:
		STD ;Comparando do final da string até o início
		MOV EAX,EDI
		
		.nextNode:
			CMP DWORD[EAX],0                 
			JE .notFound

			;Total de bytes que será comparado entre o nome do nó e o nome apontado por EDI
			MOV ECX,DWORD[ESP + STACK_ECX]
			MOV ESI,DWORD[ESP + STACK_EDI]
			
			;Ponteiro para o final do nome
			LEA EDI,[EAX + ECX + tSubNode.name]
			INC ECX

			;Verifica se o nome do arquivo é igual ao nome apontado por EDI
			REPE CMPSB
			JE .found

			ADD EAX,tSubNode_size ;Próximo subNode
		CMP EAX,EBP ;Verifica se terminou a página 
		JB .nextNode
	
		INC EBX
		
		;Verificando se terminou o bloco
		CMP EBX,DWORD[ESP + STACK_EAX]
		JAE .notFound
	.readPage:
		;Carregando próxima página do disco
		MOV ECX,1
		LEA EDI,[EBP - MEMORY_PAGE_SIZE]
		CALL storage_ReadSector
	JNC .newInteration
	
	.notFound:
		STC
	.found:
	
	;Retorna o ponteiro para o nó
	MOV DWORD[ESP + STACK_EDI],EAX
	MOV DWORD[ESP + STACK_EBX],EBX
	POPAD
	RET

;--------------------------------------------------------------------------------------------
;@description: Função projetada para criar um nó em disco.
;@input: ESI << String contendo o caminho completo do arquivo, EDI << nome do arquivo, EDX << Tipo do nó, ECX << total de páginas;
;@output: EBX >> tFileController ou 0 em caso de erro;
;@author: alisson_linhares@hotmail.com
nfs_CreateNode:
	PUSHAD

	TEST EDI,EDI ;Termina se o nome for nulo
	JZ .inputError
	CALL nfs_OpenData
	JC .abort
		;Salvando o valor que será retornado quando o procedimento terminar.
		MOV DWORD[ESP + STACK_EBX],EDI

		TEST BYTE[FS:EDI + tFileController.type   ],NFS_SUBNODETYPE_FOLDER
		JZ .invalidPath ;Verifica se retornou um ponteiro para uma pasta
		CMP DWORD[FS:EDI + tFileController.dataPtr],NFS_ROOT_SECTOR_PTR
		JE .invalidPath ;O diretório raiz não pode ser modificado
			MOV EBX,DWORD[FS:EDI + tFileController.dataPtr]
			MOV EBP,DWORD[FS:BCP_PTR + bcp.base]
			ADD EBP,EDI
		
			CLD
			MOV ECX,NFS_NAME_LENGTH
			MOV EDI,DWORD[ESP + STACK_EDI]
			ADD EDI,DWORD[FS:BCP_PTR + bcp.base]
			XOR EAX,EAX
			
			;Verifica se o tamanho do nome é valido. 
			CMP BYTE[EDI],0
			JE .invalidName
			CMP BYTE[EDI],NFS_TOKEN
			JE .invalidName
		
			REPNE SCASB ;Procurando pelo final do nome.                                  
			JNZ .invalidName

			;Calculando o tamanho da string e colcoando em ECX
			SUB ECX,NFS_NAME_LENGTH - 1
			NEG ECX
			DEC EDI
			
			MOV EDX,DWORD[DS:EBP + tFileController.storage]
			
			;Ponteiro para o final do bloco de páginas usadas pelo nó.
			MOV EAX,DWORD[DS:EBP + tFileController.size]
			ADD EAX,EBX
			
			;Procura o local de inserção no bloco e validando se o nome existe.
			CALL nfs_FindSubNode                           
			JNC .invalidName
				;Verifica se terminou o bloco de páginas e informa ao usuário.
				LEA EAX,[EBP + STORAGE_PAGE_SIZE]
				CMP EDI,EAX
				JAE .eof_error
				
				;Salvando a página do pai em ESI.
				MOV ESI,EBX
				MOV ECX,DWORD[ESP + STACK_ECX]
				CALL storage_AllocatePage ;Alocando o total de páginas
				JC .systemError
					MOV EAX,DWORD[ESP + STACK_EDX]
					
					;Configurando o tFileController.
					MOV DWORD[DS:EBP + tFileController.currentPage],0
					MOV DWORD[DS:EBP + tFileController.storage    ],EDX
					MOV DWORD[DS:EBP + tFileController.dataPtr    ],EBX
					MOV DWORD[DS:EBP + tFileController.size       ],ECX
					MOV BYTE [DS:EBP + tFileController.type       ],AL
					MOV BYTE [DS:EBP + tFileController.error      ],NO_ERROR

					;Configurando o novo registro
					MOV DWORD[EDI + tSubNode.dataPtr              ],EBX
					MOV DWORD[EDI + tSubNode.size                 ],ECX
					MOV BYTE [EDI + tSubNode.type                 ],AL
					
					;Restaurando a página do pai.
					MOV EBX,ESI
				
					CLD
					MOV ESI,DWORD[ESP + STACK_EDI]
					ADD ESI,DWORD[FS:BCP_PTR + bcp.base]
					ADD EDI,tSubNode.name
					MOV ECX,NFS_NAME_LENGTH
					REP MOVSB ;Movendo o nome para o bloco
					
					MOV ECX,1
					
					;Verifica se está no final da página.
					SUB EDI,EBP
					CMP EDI,STORAGE_PAGE_SIZE
					JB .updateParentPage
						MOV EDI,EBP
						CALL storage_WriteSector ;Atualizando o nó pai.
						
						INC EBX
						
						MOV DWORD[EDI],0 ;Marcando o final do bloco.
						JMP .continue
					.updateParentPage:
						MOV DWORD[DS:EDI + EBP],0 ;Marcando o final do bloco.
						MOV EDI,EBP
					.continue:

					;Atualizando o nó pai
					CALL storage_WriteSector

					CMP AL,NFS_SUBNODETYPE_FOLDER
					JNE .done
						;Marcando o final da pasta
						MOV DWORD[EDI],0
						MOV EBX,DWORD[DS:EBP + tFileController.dataPtr]
						CALL storage_WriteSector ;Salvando novo registro em disco
			JMP .done
	.inputError:
		PUSH NFS_INVALID_NAME
		CALL error_ThrowException
		JMP .abort
	.eof_error:
		PUSH DWORD NFS_EOF_ERROR
		JMP .sendNotification
	.invalidPath:
		PUSH DWORD NFS_INVALID_PATH
		JMP .sendNotification
	.invalidName:
		PUSH DWORD NFS_INVALID_NAME
	.sendNotification:
		CALL error_ThrowException
	.systemError:
		MOV EDI,DWORD[ESP + STACK_EBX]
		CALL memory_Free
	.abort:
		;Retornando o buffer nulo
		MOV DWORD[ESP + STACK_EBX],0
	.done:

	POPAD
	RET
	
;--------------------------------------------------------------------------------------------	
;@description: Função projetada para deletar arquivos;
;@input: -
;@output: -
;@author: -
nfs_DeleteNode:

	RET

;--------------------------------------------------------------------------------------------
;@description: Função projetada para carregar um arquivo do disco. Uso exclusivo do kernel.
;@input: ESI << string contendo o caminho do arquivo;
;@output: EDI >> Ponteiro para os dados, ECX >> o total de páginas usadas pelo arquivo.
;@author: alisson_linhares@hotmail.com
nfs_LoadFile:
	PUSHAD
	
	;Procurando pelo arquivo. Em caso de falha aborta o procedimento.
	CALL nfs_Find
	JC .loadError
		MOV ECX,DWORD[EDI + tSubNode.size   ]
		MOV EBX,DWORD[EDI + tSubNode.dataPtr]
		
		;Desativando semáforo
		system_SemaphoreUnlock EDX + storage.diskList + tStorage.semaphore
		
		;Alocando o tamanho do arquivo "tSubNode.size" em memória.
		CALL memory_AllocatePage                        
		JC .loadError
			;Salvando dados na pilha de retorno.
			MOV DWORD[ESP + STACK_ECX],ECX ;Total de páginas alocadas.
			MOV DWORD[ESP + STACK_EDI],EDI ;Ponteiro para área de memória do processo.
			
			;Carregando arquivo para memória.
			CALL storage_ReadSector
	.loadError:

	POPAD
	RET

;--------------------------------------------------------------------------------------------	
;@description: Função projetada para abrir um arquivo para leitura ou escrita;
;@input: EDI << string contendo o caminho do arquivo;
;@output: EDI >> tFileController ou 0 em caso de erro;
;@author: alisson_linhares@hotmail.com
nfs_OpenData:
	PUSHAD
	
	;Convertendo a string contendo o caminho do arquivo. Colocando a mesma na área de dados do kernel
	ADD ESI,DWORD[FS:BCP_PTR + bcp.base]  
	MOV DWORD[ESP + STACK_EDI],0 ;Retorna 0 em caso de erro.
	
	;Procurando pelo nó. Em caso de falha aborta o procedimento.
	CALL nfs_Find
	JC .openError
		;EDI contem o ponteiro para a pasta do arquivo em memória. EDI será modificado por memory_Malloc
		MOV ESI,EDI
		
		;Alocando um tFileController para o processo
		MOV ECX,tFileController_size
		CALL memory_Malloc
		JC .memory_Fault
			;Salvando na pilha de retorno, o ponteiro para o tFileController
			MOV DWORD[ESP + STACK_EDI],EDI
			
			;Configurando o tFileController com os dados recebidos pelo nfs_Find
			MOV DWORD[FS:EDI + tFileController.currentPage],0
			MOV DWORD[FS:EDI + tFileController.storage    ],EDX
			
			MOV EAX,DWORD[ESI + tSubNode.dataPtr       ]
			MOV DWORD[FS:EDI + tFileController.dataPtr ],EAX
			
			MOV EAX,DWORD[ESI + tSubNode.size          ]
			MOV DWORD[FS:EDI + tFileController.size    ],EAX
			
			MOV AL,BYTE[ESI + tSubNode.type            ]
			MOV BYTE [FS:EDI + tFileController.type    ],AL

			MOV BYTE[FS:EDI + tFileController.error    ],NO_ERROR
		.memory_Fault:
		
		;Desativando semáforo
		system_SemaphoreUnlock EDX + storage.diskList + tStorage.semaphore
	.openError:
	
	POPAD
	RET

;--------------------------------------------------------------------------------------------	
;@description: Função projetada para ler dados do disco.
;@input: EDI << tFileController;
;@output: -
;@author: alisson_linhares@hotmail.com
nfs_ReadData: 
	;Se o controller for nulo aborta a função.                                           	
	TEST EDI,EDI
	JZ .abort
		PUSHAD
		
		;Colocando EDI na área de endereçamento do kernel.
		ADD EDI,DWORD[FS:BCP_PTR + bcp.base]
		CMP DWORD[EDI + tFileController.dataPtr],0
		JE .readError
		
			;Verifica se o arquivo terminou.
			MOV EBX,DWORD[EDI + tFileController.currentPage]
			CMP DWORD[EDI + tFileController.size],EBX
			JBE .readError
				MOV ECX,1 ;Lendo uma página do disco.
				ADD EBX,DWORD[EDI + tFileController.dataPtr]
				MOV EDX,DWORD[EDI + tFileController.storage]
				CALL storage_ReadSector ;Carregando dados no tFileController.buffer.
				JC .returnError
					MOV BYTE[EDI + tFileController.error],NO_ERROR
					JMP .done
		.readError:
			;Notificando o kernel sobre o erro de leitura.
			PUSH DWORD NFS_READ_ERROR
			CALL error_ThrowException
		.returnError:
			;Retornando erro para o programa.
			MOV BYTE[EDI + tFileController.error],NFS_READ_ERROR
		.done:
		
		POPAD
	.abort:
	RET
	
;--------------------------------------------------------------------------------------------	
;@description: Função projetada para escrever dados no disco.
;@input: EDI << tFileController;
;@output: -
;@author: alisson_linhares@hotmail.com
nfs_WriteData:
	;Se o controller for nulo aborta a função.
	TEST EDI,EDI
	JZ .abort
		PUSHAD
		
		;Colocando EDI na área de endereçamento do kernel.
		ADD EDI,DWORD[FS:BCP_PTR + bcp.base]
		CMP DWORD[EDI + tFileController.dataPtr],0
		JE .writeError
		
			;Verifica se a página é válida.
			MOV EBX,DWORD[EDI + tFileController.currentPage]
			CMP DWORD[EDI + tFileController.size],EBX
			JBE .writeError
				MOV ECX,1 ;Escrevendo uma página em disco
				ADD EBX,DWORD[EDI + tFileController.dataPtr]
				MOV EDX,DWORD[EDI + tFileController.storage]
				CALL storage_WriteSector ;Salvando página em disco
				JC .returnError
					MOV BYTE[EDI + tFileController.error],NO_ERROR
					JMP .done
		.writeError:
			;Notificando o kernel sobre o erro na escrita
			PUSH DWORD NFS_WRITE_ERROR
			CALL error_ThrowException
		.returnError:
			;Retornando erro para o programa.
			MOV BYTE[EDI + tFileController.error],NFS_WRITE_ERROR
		.done:

		POPAD
	.abort:
	RET

;--------------------------------------------------------------------------------------------
;[1] NFS - Neutrino File System: It's a file system designed by Alisson Linhares de Carvalho for the neutrino kernel.
;NFS - Neutrino File System Copyright (C) 2011-2012 Alisson Linhares de Carvalho. All rights reserved.