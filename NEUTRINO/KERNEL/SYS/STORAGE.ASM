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
STORAGE_INVALID        EQU 0h ;8Bits identificadores de dispositivos
STORAGE_PATA           EQU 1h    
STORAGE_PATAPI         EQU 2h
STORAGE_SATA           EQU 3h
STORAGE_SATAPI         EQU 4h
STORAGE_SCSI           EQU 5h

STORAGE_IDE0_MASTER    EQU 1h ;8Bits complementares         
STORAGE_IDE0_SLAVE     EQU 2h             
STORAGE_IDE1_MASTER    EQU 3h             
STORAGE_IDE1_SLAVE     EQU 4h 

STORAGE_PAGE_SIZE      EQU MEMORY_PAGE_SIZE
STORAGE_SIGNATURE      EQU 0x89ABCDEF
STORAGE_NUM_OF_DISKS   EQU 6

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para registros---------------------------------
;@description: Registro usado para gerenciar as unidades de armazenamento encontradas.
struc tStorage 
	.id            RESW 1
	.reserved      RESW 1
	.semaphore     RESD 1
	.buffer        RESD 1
	.size          RESD 1
endstruc

;@description: Registro usado dentro de tStorageInfo para montar um array de unidades.
struc tDisk
	.type          RESB 1
	.channel       RESB 1
	.size          RESD 1
endstruc

;@description: Modelo do registro usado para troca de informações entre a nlib e o kernel.
struc tStorageInfo
	.signature     RESD 1
	.numberOfDisks RESB 1
	.buffer        RESB tDisk_size * STORAGE_NUM_OF_DISKS
endstruc

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para variáveis---------------------------------                    
storage:
.lastStorageIndex      DD 0
.diskList              TIMES tStorage_size * STORAGE_NUM_OF_DISKS DB 0

;--------------------------------------------------------------------------------------------
;@description: Macro para configurar as unidades de disco.
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro storage_Config 0
	;Carregando informações do disco 0
	MOV DX,ATA_0
	MOV AL,0A0h
	MOV BH,STORAGE_IDE0_MASTER
	CALL storage_Identify

	;Carregando informações do disco 1
	MOV AL,0B0h
	MOV BH,STORAGE_IDE0_SLAVE
	CALL storage_Identify

	;Carregando informações do disco 2 
	MOV DX,ATA_1
	MOV AL,0A0h
	MOV BH,STORAGE_IDE1_MASTER
	CALL storage_Identify

	;Carregando informações do disco 3
	MOV AL,0B0h
	MOV BH,STORAGE_IDE1_SLAVE
	CALL storage_Identify

	;Verifica se a unidade de boot foi configurada como master. Caso contrário, seta como master a primeira unidade bootável no vetor de discos.
	XOR ESI,ESI

	%%nextDisk:
		MOV EDI,DWORD[ESI + storage.diskList + tStorage.buffer] 

		CMP DWORD[EDI + tBootSector.signature],NFS_BOOTSECTOR_SIGNATURE ;Procura pela assinatura do NFS
		JNE %%continue
		CMP BYTE[EDI + tBootSector.bootIndicator],80h ;Verifica se a unidade foi configurada como master.
		JE %%changePosition
		%%continue:
		  
		ADD ESI,tStorage_size
		CMP ESI,DWORD[storage.lastStorageIndex]
		JB %%nextDisk
	%%changePosition:
		;Se a unidade master for a primeira, o disco já estava configurado corretamente.
		TEST ESI,ESI
		JZ %%done
			storage_XCHGDisk 0,ESI ;Trocando as unidades.
	%%done:
%endmacro

;--------------------------------------------------------------------------------------------
;@description: Macro projetada para trocar a posição lógica dos discos.
;@input: %1 << Disco1, %2 << Disco2
;@output: EAX << Lixo
;@author: alisson_linhares@hotmail.com
%macro storage_XCHGDisk 2
	MOV EAX,DWORD[%2 + storage.diskList + tStorage.id]
	XCHG EAX,DWORD[%1 + storage.diskList + tStorage.id]
	MOV DWORD[%2 + storage.diskList + tStorage.id],EAX

	MOV EAX,DWORD[%2 + storage.diskList + tStorage.semaphore]
	XCHG EAX,DWORD[%1 + storage.diskList + tStorage.semaphore]
	MOV DWORD[%2 + storage.diskList + tStorage.semaphore],EAX

	MOV EAX,DWORD[%2 + storage.diskList + tStorage.buffer]
	XCHG EAX,DWORD[%1 + storage.diskList + tStorage.buffer]
	MOV DWORD[%2 + storage.diskList + tStorage.buffer],EAX

	MOV EAX,DWORD[%2 + storage.diskList + tStorage.size]
	XCHG EAX,DWORD[%1 + storage.diskList + tStorage.size]
	MOV DWORD[%2 + storage.diskList + tStorage.size],EAX
%endmacro

;--------------------------------------------------------------------------------------------
;@description: Procedimento para retornar informações das unidades de armazenamento detectadas.
;@remarks: No momento o sistema só é capaz de detectar unidades IDE.
;@input: EDI << tStorageInfo
;@output: -
;@author: alisson_linhares@hotmail.com
storage_GetInfo:
	CMP DWORD[SS:EDI + tStorageInfo.signature],STORAGE_SIGNATURE
	JNE .abort
		PUSHAD

		ADD EDI,DWORD[SS:BCP_PTR + bcp.base]
		ADD EDI,tStorageInfo.numberOfDisks
		CLD

		;Retornando o total de unidades encontradas.
		MOV EAX,DWORD[storage.lastStorageIndex]
		SHR EAX,4
		STOSB
		
		;Copiando dados importantes do storage.diskList para o buffer do usuário.
		MOV EBX,storage.diskList
		JMP .startLoop

		.nextStorage:
			LEA ESI,[EBX + tStorage.id  ]
			MOVSW

			LEA ESI,[EBX + tStorage.size]
			MOVSD

			ADD EBX,tStorage_size
		.startLoop:
			DEC EAX
		JGE .nextStorage

		POPAD
	.abort:
	RET

;--------------------------------------------------------------------------------------------	
;@description: Macro para identificar e configurar as unidades de disco.
;@input: DX << ATA_1 || ATA_0, AL << 0A0h || 0B0h, BH << STORAGE_IDE0_MASTER || STORAGE_IDE0_SLAVE || STORAGE_IDE1_MASTER || STORAGE_IDE1_SLAVE
;@output: -
;@author: alisson_linhares@hotmail.com
storage_Identify:   
	PUSHAD

	;Escolhendo o drive Master "0A0h" ou Slave "0B0h"
	OR DX,6
	OUT DX,AL   

	;Limpando portas "1F2h/172h, 1F3h/173h, 1F4h/174h, 1F5h/175h" da controladora 
	XOR AL,AL
	DEC DX
	OUT DX,AL
	
	DEC DX
	OUT DX,AL

	DEC DX
	OUT DX,AL

	DEC DX
	OUT DX,AL

	;Enviado o comando de identificação para controladora "1F7h/177h"
	ADD DX,5
	MOV AL,ATA_IDENTIFY
	OUT DX,AL
	
	;Espera a controladora ficar pronta
	MOV CX,0FFFFh
	.ataIsBusy:
		IN AL,DX
	
		;Verifica se deu time out
		DEC CX
		JZ .invalidDisk
	TEST AL,AL
	JZ  .invalidDisk
	TEST AL,10000000b
	JNZ .ataIsBusy
	
	;Lendo portas 1F4/174 e 1F5/175 da controladora
	SUB DX,2
	IN AL,DX
	MOV AH,AL
	DEC DX
	IN AL,DX
	
	;Verifica o tipo do dispositivo conectado a controladora "Sata, Pata, Satapi, Patapi ou inválido"
	TEST AX,AX
	JZ .pata
	CMP AX,0C33Ch
	JE .sata
	CMP AX,0EB14h
	JE .patapi
	CMP AX,09669h
	JNE .invalidDisk
	
	.satapi:
		MOV BL,STORAGE_SATAPI
		JMP .atapi_config
	.patapi:
		MOV BL,STORAGE_PATAPI
		JMP .atapi_config
	.sata:
		MOV BL,STORAGE_SATA
		JMP .ata_config
	.pata:
		MOV BL,STORAGE_PATA
		JMP .ata_config
	.atapi_config:
		XOR EAX,EAX
		MOV ECX,(ATAPI_BLOCK_SIZE * 2) / MEMORY_PAGE_SIZE
		JMP .continue
	.ata_config:
		ADD DX,3
		
		;Verifica se o drive está pronto para enviar informações sobre o disco
		.ataIsReady:
			IN AL,DX
		TEST AL,00000001b
		JNZ  .invalidDisk
		TEST AL,00001000b 
		JZ .ataIsReady

		;Carregando informações para o buffer de sistema
		CLD
		SUB DX,7
		MOV ECX,256
		MOV EDI,kernel_Buffer
		REP INSW
		
		;Configurando registro de controle do disco
		MOV EAX,DWORD[kernel_Buffer + 120]
		MOV ECX,(ATA_BLOCK_SIZE * 2) / MEMORY_PAGE_SIZE
	.continue:
		CALL memory_AllocatePage
		JC .invalidDisk
			MOV EDX,DWORD[storage.lastStorageIndex]
			MOV DWORD[EDX + storage.diskList + tStorage.semaphore],0
			MOV DWORD[EDX + storage.diskList + tStorage.buffer   ],EDI
			MOV DWORD[EDX + storage.diskList + tStorage.size     ],EAX
			MOV WORD [EDX + storage.diskList + tStorage.id       ],BX
			ADD DWORD[storage.lastStorageIndex],tStorage_size
			
			;Carregando o setor de boot para memória
			MOV ECX,1                ;Total de setores
			XOR EBX,EBX              ;Setor
			CALL storage_ReadSector
	.invalidDisk:
	
	POPAD
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para detectar a configuração de uma unidade com base no ID.
;@input: DX << tStorage.id
;@output: EDX >> ATA_0 | ATA_1, AL >> ATA_MASTER | ATA_SLAVE, AH >>  ATAPI_MASTER | ATAPI_SLAVE 
;@author: alisson_linhares@hotmail.com
storage_DetectAtaConfig:
	CMP DH,STORAGE_IDE0_MASTER
	JE .pata0Master
	CMP DH,STORAGE_IDE0_SLAVE
	JE .pata0Slave
	CMP DH,STORAGE_IDE1_MASTER
	JE .pata1Master
	CMP DH,STORAGE_IDE1_SLAVE
	JNE .done

	.pata1Slave:
		MOV EDX,ATA_1  
		MOV AX,ATA_SLAVE  + (ATAPI_SLAVE  << 8)
		JMP .done
	.pata0Master:
		MOV EDX,ATA_0 
		MOV AX,ATA_MASTER + (ATAPI_MASTER << 8)
		JMP .done
	.pata0Slave:
		MOV EDX,ATA_0  
		MOV AX,ATA_SLAVE  + (ATAPI_SLAVE  << 8)
		JMP .done
	.pata1Master:
		MOV EDX,ATA_1  
		MOV AX,ATA_MASTER + (ATAPI_MASTER << 8)
	.done:
	RET

;--------------------------------------------------------------------------------------------
;@description: Procedimento para ler setore de um dispositivo de armazenamento secundário.
;@input: EDX << diskList index, EBX << page, EDI << buffer, ECX << total de setores
;@output: -
;@author: alisson_linhares@hotmail.com
storage_ReadSector:
	PUSHAD
	
	;Verificando se a unidade é válida.
	CMP EDX,DWORD[storage.lastStorageIndex]               
	JAE .abort
		MOV DX,WORD[EDX + storage.diskList + tStorage.id]
		
		CMP DL,STORAGE_PATA
		JE .pata
		CMP DL,STORAGE_PATAPI
		JE .patapi
		CMP DL,STORAGE_SATA
		JE .sata
		CMP DL,STORAGE_SATAPI
		JNE .abort

		.satapi:
			;Reservado para dispositivos satapi
			JMP .done
		.sata:
			;Reservado para dispositivos sata
			JMP .done
		.patapi:
			CALL storage_DetectAtaConfig
			atapi_Read EBX,DX,AH,EDI ;PAGE_ADDRESS, ATA_0 || ATA_1, ATAPI_MASTER || ATAPI_SLAVE, EBX + tATA_LBA28.buffer
			JMP .done
		.pata:
			CALL storage_DetectAtaConfig
			ata_Read EBX,DX,AL,EDI,ECX ;PAGE_ADDRESS, ATA_0 || ATA_1, ATA_MASTER || ATA_SLAVE,tATA_LBA28.buffer,tATA_LBA28.totalOfBlocks
			JMP .done
	.abort:
		PUSH DWORD STORAGE_INVALID_ID
		CALL error_ThrowException ;Informando ao núcleo sobre o erro.
	.done:

	POPAD
	RET

;--------------------------------------------------------------------------------------------
;@description: Procedimento para escrever dados em um dispositivos de armazenamento secundário.
;@input: EDX << diskList index, EBX << page, EDI << buffer, ECX << total de setores
;@output: -
;@author: alisson_linhares@hotmail.com
storage_WriteSector:
	PUSHAD
	
	;Verificando se a unidade é válida.
	CMP EDX,DWORD[storage.lastStorageIndex]               
	JAE .abort
		MOV DX,WORD[EDX + storage.diskList + tStorage.id]
		
		CMP DL,STORAGE_PATA
		JE .pata
		CMP DL,STORAGE_PATAPI
		JE .patapi
		CMP DL,STORAGE_SATA
		JE .sata
		CMP DL,STORAGE_SATAPI
		JNE .abort

		.satapi:
			;Reservado para dispositivos satapi
			JMP .done
		.sata:
			;Reservado para dispositivos sata
			JMP .done
		.patapi:
			;Resevado para dispositivos patapi
			JMP .done
		.pata:
			CALL storage_DetectAtaConfig
			ata_Write EBX,DX,AL,EDI,ECX ;PAGE_ADDRESS, ATA_0 || ATA_1, ATA_MASTER || ATA_SLAVE,tATA_LBA28.buffer,tATA_LBA28.totalOfBlocks
			JMP .done
	.abort:
		PUSH DWORD STORAGE_INVALID_ID
		CALL error_ThrowException ;Informando ao núcleo sobre o erro.
	.done:

	POPAD
	RET

;--------------------------------------------------------------------------------------------
;@description: Função para desalocar páginas em disco.
;@remarks: Não é permitida a desalocação de páginas em unidades de CD e DVD.
;@input: EDX << tStorage, EBX << setor, ECX << total de páginas
;@output: -
;@author: alisson_linhares@hotmail.com
storage_DeallocatePage:
	PUSHAD
	
	;Verificando se a unidade é válida.
	CMP EDX,DWORD[storage.lastStorageIndex]       
	JAE .invalidId
		MOV EDI,DWORD[EDX + storage.diskList + tStorage.buffer]
		CMP DWORD[EDI + tBootSector.signature],NFS_BOOTSECTOR_SIGNATURE
		JNE .invalidDiskFormat
			;Travando o semáforo para essa unidade.
			LEA EBP,[EDX + storage.diskList + tStorage.semaphore]
			CALL system_SemaphoreLock

			;Salvando em EBP o total de páginas.
			MOV EBP,ECX
			MOV ECX,1 ;ECX tem a unidade de alocação para storage_WriteSector e storage_ReadSector.
			
			;Fazendo EDI apontar para o buffer em memória.
			ADD EDI,MEMORY_PAGE_SIZE
			
			;Verifica se existe espaço disponível em disco.
			CMP DWORD[EDI - MEMORY_PAGE_SIZE + tBootSector.pageList],0
			JNE .findSpace
				;Liberando o bloco de páginas
				MOV DWORD[EDI + tMemoryPage.next],0 
				MOV DWORD[EDI + tMemoryPage.size],EBP
				CALL storage_WriteSector
				
				;Salvando o setor de boot no disco
				MOV DWORD[EDI - MEMORY_PAGE_SIZE + tBootSector.pageList],EBX
				JMP .updateBootSector
			.findSpace:
				MOV EBX,DWORD[EDI - MEMORY_PAGE_SIZE + tBootSector.pageList] 
			
				MOV EAX,EBX ;EAX é um ponteiro para o bloco anterior.
				JMP .startFindLoop
				
				;Procurando o local onde deve ser inserido o bloco de páginas
				.findLoop:
					MOV EAX,EBX
					MOV EBX,DWORD[EDI + tMemoryPage.next] ;Move para o próximo setor
					
				;Verifica se o setor atual é menor que o setor passado por parâmetro
				.startFindLoop:
				CMP DWORD[ESP + STACK_EBX],EBX 
				JB .insertMiddle
					CALL storage_ReadSector ;Lendo o próximo setor
					JC .done
				CMP DWORD[EDI + tMemoryPage.next],0
				JA .findLoop

				.insertFront: ;Inserindo bloco de páginas na frente do bloco atual
					MOV EBX,EAX
					CALL storage_ReadSector
					
					ADD EAX,DWORD[EDI + tMemoryPage.size] ;Ponteiro para o final do bloco anterior

			
					;Verifica se o final do bloco anterior é igual ao início do bloco desalocado
					CMP EAX,DWORD[ESP + STACK_EBX]
					JE .addPages
						;O anterior aponta para o início do bloco inserido.
						MOV EAX,DWORD[ESP + STACK_EBX]
						MOV DWORD[EDI + tMemoryPage.next],EAX
						CALL storage_WriteSector ;Salvando o bloco anterior.
						
						MOV DWORD[EDI + tMemoryPage.next],0 ;Marcando como última página.
						MOV DWORD[EDI + tMemoryPage.size],EBP
						MOV EBX,EAX
						CALL storage_WriteSector ;Salvando o bloco atual
						JMP .updateBootSector
					.addPages:
						;Inserindo o total de páginas do bloco e salvando o bloco anterior
						ADD DWORD[EDI + tMemoryPage.size],EBP
						CALL storage_WriteSector
						JMP .updateBootSector
				.insertMiddle:
					MOV ESI,DWORD[ESP + STACK_EBX]
					ADD ESI,EBP
					
					;Verifica se o final do bloco anterior é igual ao início do próximo bloco
					CMP ESI,EBX 
					JNE .addNext
						CALL storage_ReadSector
						ADD DWORD[EDI + tMemoryPage.size],EBP ;Somando as duas páginas
						JMP .continue
					.addNext:
						MOV DWORD[EDI + tMemoryPage.next],EBX ;Ponteiro para página seguinte
						MOV DWORD[EDI + tMemoryPage.size],EBP ;Inserindo o total de páginas do bloco
					.continue:
					
					MOV EBX,DWORD[ESP + STACK_EBX]
					CALL storage_WriteSector
					
					;Verifica se existe algum bloco de páginas abaixo do bloco atual.
					CMP EBX,DWORD[EDI - MEMORY_PAGE_SIZE + tBootSector.pageList]
					JB .newFirstPage
						MOV EBX,EAX
						MOV EAX,DWORD[EDI + tMemoryPage.next] ;Salvando em EAX o ponteiro para a próxima página.
						MOV EBP,DWORD[EDI + tMemoryPage.size] ;Salvando em EBP o total de páginas do bloco. 
						CALL storage_ReadSector
						
						MOV ESI,DWORD[EDI + tMemoryPage.size]
						ADD ESI,EBX
						
						;Verifica se o final do bloco é igual ao início do bloco desalocado
						CMP ESI,DWORD[ESP + STACK_EBX]
						JNE .addPrior
							ADD DWORD[EDI + tMemoryPage.size],EBP
							MOV DWORD[EDI + tMemoryPage.next],EAX ;Inserindo o ponteiro para depois desse bloco
							CALL storage_WriteSector
							JMP .updateBootSector
						.addPrior:
							MOV EAX,DWORD[ESP + STACK_EBX] 
							MOV DWORD[EDI + tMemoryPage.next],EAX  ;Ponteiro para página desalocada
							CALL storage_WriteSector
							JMP .updateBootSector
					.newFirstPage:
						MOV DWORD[EDI - MEMORY_PAGE_SIZE + tBootSector.pageList],EBX
	.updateBootSector:
		;EDI agora aponta para a cópia em memória do primeiro setor da unidade.
		SUB EDI,MEMORY_PAGE_SIZE
		
		;Retirando o total de páginas desalocadas.
		MOV EAX,DWORD[ESP + STACK_ECX]
		SUB DWORD[EDI + tBootSector.usedPages],EAX
		
		XOR EBX,EBX
		CALL storage_WriteSector
	.done:
		;Destravando o semáforo
		system_SemaphoreUnlock EDX + storage.diskList + tStorage.semaphore
		JMP .abort
	.invalidDiskFormat:
		PUSH DWORD NFS_INVALID_DISK
		JMP .sendNotification
	.invalidId:
		PUSH DWORD STORAGE_INVALID_ID
	.sendNotification:
		CALL error_ThrowException
	.abort:

	POPAD
	RET

;--------------------------------------------------------------------------------------------
;@description: Função para alocar blocos de páginas em disco.
;@remarks: Não é permitida a alocação de páginas em unidades de CD e DVD.
;@input: EDX << tStorage, ECX << total de páginas
;@output: EBX >> setor
;@author: alisson_linhares@hotmail.com
storage_AllocatePage:
	XOR EBX,EBX ;EBX retorna 0 em caso de erro.
	PUSHAD

	;Verificando se a unidade é válida.
	CMP EDX,DWORD[storage.lastStorageIndex]               
	JAE .invalidId
		MOV EDI,DWORD[EDX + storage.diskList + tStorage.buffer]
		CMP DWORD[EDI + tBootSector.signature],NFS_BOOTSECTOR_SIGNATURE
		JNE .invalidDiskFormat
			LEA EBP,[EDX + storage.diskList + tStorage.semaphore]
			CALL system_SemaphoreLock
			
			MOV EBX,DWORD[EDI + tBootSector.pageList]
			
			;EDI é o Ponteiro para o buffer depois do setor de boot.
			LEA EDI,[EDI + STORAGE_PAGE_SIZE]
			
			MOV EBP,ECX ;Salvando em EBP o total de páginas
			MOV ECX,1   ;Total de páginas lidas e escritas pelas funções storage_ReadSector e storage_WriteSector
			
			XOR EAX,EAX
			JMP .startFindLoop
			
			.findLoop:
				MOV EAX,EBX
				MOV EBX,DWORD[EDI + tMemoryPage.next]
			.startFindLoop:
				TEST EBX,EBX 
				JZ .pageFaultError
				CALL storage_ReadSector
				JC .pageFaultError
			CMP DWORD[EDI + tMemoryPage.size],EBP
			JB .findLoop
			
			.spaceFound:
				;Retornando o setor encontrado.
				MOV DWORD[ESP + STACK_EBX],EBX 
				
				;Verifica se o bloco de páginas é maior que a necessidade de alocação.
				JA .removePage
					;Removendo bloco inteiro se igual "Anterior aponta para o próximo".
					MOV EBX,DWORD[EDI + tMemoryPage.next]
					JMP .removeBlock
				.removePage:
					;Alocando parte das páginas.
					SUB DWORD[EDI + tMemoryPage.size],EBP
					ADD EBX,EBP
					CALL storage_WriteSector ;Salvando nova página em disco.
				.removeBlock:
				
				;Verifica se o bloco removido é o primeiro.
				TEST EAX,EAX
				JZ .firstBlock ;Remove o bloco atual
					;Salvando em EBX o ponteiro para o bloco de páginas anterior e em EAX o ponteiro para o próximo bloco. 
					XCHG EAX,EBX
					CALL storage_ReadSector ;Carregando o bloco anterior.

					;O bloco anterior aponta para o depois das páginas removidas.
					MOV DWORD[EDI + tMemoryPage.next],EAX 
					CALL storage_WriteSector ;Salvando setor
					JMP .continueRemove
				.firstBlock:
					MOV DWORD[EDI - STORAGE_PAGE_SIZE + tBootSector.pageList],EBX
				.continueRemove:
				
				;Atualizando o setor de boot
				XOR EBX,EBX
				SUB EDI,MEMORY_PAGE_SIZE
				ADD DWORD[EDI + tBootSector.usedPages],EBP ;Total de páginas usadas
				CALL storage_WriteSector
				
				;Desativando semáforo.
				system_SemaphoreUnlock EDX + storage.diskList + tStorage.semaphore
				JMP .done
	.pageFaultError:
		system_SemaphoreUnlock EDX + storage.diskList + tStorage.semaphore
		PUSH DWORD STORAGE_PAGE_FAULT
		JMP .sendNotification
	.invalidDiskFormat:
		PUSH DWORD NFS_INVALID_DISK
		JMP .sendNotification
	.invalidId:
		PUSH DWORD STORAGE_INVALID_ID
	.sendNotification:
		CALL error_ThrowException
	.done:

	POPAD
	RET