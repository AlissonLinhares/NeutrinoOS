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
START_PAGE_LIST         EQU 0100000h

MEMORY_SIGNATURE        EQU 0x89ABCDEF
MEMORY_BITS_PER_PAGE    EQU 9
MEMORY_PAGE_SIZE        EQU 1 << MEMORY_BITS_PER_PAGE

MALLOC_BITS_PER_PAGE    EQU 4
MALLOC_PAGE_SIZE        EQU 1 << MALLOC_BITS_PER_PAGE

;--------------------------------------------------------------------------------------------
;-----------------------------Área reservada para registros----------------------------------
;@description: Registro usado no controle dos blocos de páginas.
struc tMemoryPage
	.next           RESD 1
	.size           RESD 1
endstruc

;@description: Registro projetado para troca de informações entre a nlib e o kernel.
struc tMemoryInfo
	.signature      RESD 1
	.usage          RESD 1
	.size           RESD 1
endstruc

;--------------------------------------------------------------------------------------------
;-----------------------------Área reservada para variáveis----------------------------------
memory:
.map                    TIMES 8 DD 0,0 ;Mapa da memória.
.semaphore              DD 0 ;Variável para controle de concorrência.           
.firstBlockFree         DD START_PAGE_LIST ;Ponteiro para o primeiro bloco de memória livre.
.usage                  DD START_PAGE_LIST >> MEMORY_BITS_PER_PAGE ;Memória em uso.
.size                   DD START_PAGE_LIST >> MEMORY_BITS_PER_PAGE ;Memória total.

;--------------------------------------------------------------------------------------------
;@description: Macro projetada para carregar informações da memória e calcular o tamanhos dos blocos livres.
;@remarks: A memória é dividia em áreas, algumas não podem ser usadas.
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro memory_Check 0
	XOR EBX,EBX
	MOV EDI,kernel_Buffer
	MOV ESI,memory.map
	
	%%memLoop:
		MOV EAX,0000E820h
		MOV EDX,0534D4150h ;'SMAP'
		MOV DWORD[ES:EDI + 20],1 ;Forçando uma entrada valida na ACPI 3.X 
		MOV ECX,24
		INT 15h
		
		;Verifica se ocorreu algum erro
		JC %%abort
		CMP EAX,0534D4150h ;Verifica se EAX retornou SMAP 
		JNE %%abort
			
		CMP WORD[ES:EDI + 10h],1h ;1h - memória reservada para o sistema
		JNE %%invalidMemArea
		CMP DWORD[ES:EDI],START_PAGE_LIST
		JB  %%invalidMemArea
			;Montando o mapa de memória
			MOV EAX,DWORD[ES:EDI]
			MOV DWORD[DS:ESI],EAX
			
			MOV EAX,DWORD[ES:EDI + 08h]
			MOV DWORD[DS:ESI + 4],EAX  ;Tamanho da área em bytes
			ADD ESI,8
		%%invalidMemArea:
	TEST EBX,EBX ;Verifica se o mapa terminou          
	JNZ %%memLoop
	%%abort:
%endmacro

;--------------------------------------------------------------------------------------------
;@description: Macro projetada para configurar o gerente de memória. 
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro memory_Config 0
	MOV ESI,memory.map
	MOV EDI,START_PAGE_LIST
	
	;Configurando as áreas de memória que podem ser usadas
	%%readNextArea:
		MOV EBX,DWORD[ESI    ] ;Carregando a base  
		MOV EAX,DWORD[ESI + 4] ;Carregando o tamanho do bloco	
		
		SHR EAX,MEMORY_BITS_PER_PAGE
		TEST EBX,MEMORY_PAGE_SIZE - 1 ;Verifica se existe valores entre 0 e MEMORY_PAGE_SIZE         
		JZ %%continue
			AND EBX,0FFFFFFFFh - (MEMORY_PAGE_SIZE - 1)                
			INC EBX ;Arredondando para o próximo múltiplo de MEMORY_PAGE_SIZE
			DEC EAX
		%%continue:
	
		TEST EAX,EAX ;Se o bloco for menor que uma página ele é descartado 
		JZ %%discardArea
	        ;Configurando o novo bloco de memória
			ADD DWORD[memory.size],EAX ;Calculando a quantidade de memória reconhecida pelo sistema
			MOV DWORD[EBX + tMemoryPage.size],EAX
			MOV DWORD[EDI + tMemoryPage.next],EBX  
			MOV EDI,EBX ;Anterior aponta para atual
		%%discardArea:
		
		ADD ESI,8 ;Incrementa o mapa
	CMP DWORD[ESI + 4],0 ;Verifica se existe mais memória
	JE %%exit
	CMP ESI,memory.map + 64 ;Verifica se o mapa terminou
	JB %%readNextArea
	%%exit:

	MOV DWORD[EBX + tMemoryPage.next],0 ;O último bloco de páginas aponta para 0 
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Procedimento usado para remover blocos de páginas.
;@input: ECX << total de páginas, EDI << Ponteiro para o bloco livre atual, ESI << Ponteiro para o bloco livre anterior
;@output: ALL
;@author: alisson_linhares@hotmail.com
.pageListRemove:
	ADD DWORD[memory.usage],ECX ;Atualizamdo o total de páginas usadas

	;Verifica se existe memória suficiente neste bloco
	CMP DWORD[EDI + tMemoryPage.size],ECX 
	JA .removePage
		MOV EAX,DWORD[EDI + tMemoryPage.next] ;Anterior aponta para o próximo
		JMP .removeBlock
	.removePage:
		MOV EBP,DWORD[EDI + tMemoryPage.size]
		SUB EBP,ECX ;Retirando as páginas do bloco, EBP tem o total de páginas usadas 

		;Calculando o tamanho da página
		MOV EAX,ECX
		SHL EAX,MEMORY_BITS_PER_PAGE ;EAX contem o tamanho do bloco que será removido
		ADD EAX,EDI
		MOV DWORD[EAX + tMemoryPage.size],EBP
	
		;Configurando o ponteiro para próxima página
		MOV EBP,DWORD[EDI + tMemoryPage.next]
		MOV DWORD[EAX + tMemoryPage.next],EBP
	.removeBlock:
	
	TEST ESI,ESI ;Verifica se é o primeiro
	JZ .removeFirstBlock
		;Remove o bloco atual
		MOV DWORD[ESI + tMemoryPage.next],EAX ;O ponteiro anterior aponta para depois das páginas removidas
		RET
	.removeFirstBlock:
		MOV DWORD[memory.firstBlockFree],EAX         
	RET
	
;--------------------------------------------------------------------------------------------	
;@description: Procedimento para retornar informações do gerente de memória.
;@input: EDI << tMemoryInfo
;@output: -
;@author: alisson_linhares@hotmail.com
memory_GetInfo:
	;Verifica se o registro enviado é válido.
	CMP DWORD[SS:EDI + tMemoryInfo.signature],MEMORY_SIGNATURE
	JNE .abort
		PUSH EAX
		
		;Inserindo valores no registro de troca.
		MOV EAX,DWORD[memory.usage]
		MOV DWORD[SS:EDI + tMemoryInfo.usage],EAX

		MOV EAX,DWORD[memory.size]
		MOV DWORD[SS:EDI + tMemoryInfo.size],EAX

		POP EAX
	.abort:
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para alocar páginas de memória.
;@input: ECX << total de páginas
;@output: EDI >> ponteiro para memória
;@author: alisson_linhares@hotmail.com
memory_AllocatePage:
	PUSH EBP
	PUSH ESI
	PUSH EAX
	
	MOV EBP,memory.semaphore
	CALL system_SemaphoreLock
	
	;Proteção contra alocação inválida de memória.
	TEST ECX,ECX
	JZ .pageNotFound

	XOR ESI,ESI
	MOV EDI,DWORD[memory.firstBlockFree] ;Ponteiro para o primeiro bloco de páginas
	JMP .startLoop              
	
	;Procurando por uma página livre de tamanho suficiente
	.nextBlock:
		MOV ESI,EDI ;ESI é o ponteiro para o bloco anterior
		MOV EDI,DWORD[EDI + tMemoryPage.next]
	.startLoop:
	TEST EDI,EDI ;EDI retorna 0 em caso de erro   
	JZ .pageNotFound 
	CMP DWORD[EDI + tMemoryPage.size],ECX ;Verifica se existe memória suficiente neste bloco 
	JB .nextBlock
		
	.pageFound:
		CALL memory.pageListRemove ;Removendo da lista a quantidade de páginas
		JMP .done
	.pageNotFound:
		PUSH DWORD MEMORY_PAGE_FAULT
		CALL error_ThrowException
	.done:
	
	system_SemaphoreUnlock memory.semaphore
	
	POP EAX
	POP ESI
	POP EBP
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para desalocar páginas de memória.
;@input: ECX << total de páginas, EDI << Ponteiro para memória
;@output: -
;@author: alisson_linhares@hotmail.com
memory_DeallocatePage:
	PUSH EBP
	
	MOV EBP,memory.semaphore
	CALL system_SemaphoreLock
	
	CMP DWORD[memory.firstBlockFree],0 ;Verifica se existe blocos de memória livres
	JNE .insertFirstBlock
		MOV DWORD[EDI + tMemoryPage.next],0
		MOV DWORD[EDI + tMemoryPage.size],ECX
		MOV DWORD[memory.firstBlockFree],EDI ;Configurando o ponteiro
		JMP .deallocated
	.insertFirstBlock:
		PUSH EBX
		PUSH ESI
		
		MOV EBX,DWORD[memory.firstBlockFree] ;Ponteiro para o primeiro bloco 
		MOV ESI,EBX
		
		;Procurando o bloco de páginas que está na frente do apontado por EDI
		JMP .startLoop
		.nextBlock:
			MOV ESI,EBX
			MOV EBX,DWORD[EBX + tMemoryPage.next]	
		.startLoop:
		CMP EDI,EBX 
		JB .insertMiddle
		CMP DWORD[EBX + tMemoryPage.next],0
		JA .nextBlock
		
		.insertFront:
			;Criando o ponteiro para o final do bloco
			MOV EBP,DWORD[ESI + tMemoryPage.size]
			SHL EBP,MEMORY_BITS_PER_PAGE
			ADD EBP,ESI
				
			CMP EBP,EDI ;Verifica se o final do bloco é igual ao início do bloco desalocado
			JE .addPages
				MOV DWORD[EDI + tMemoryPage.next],0 ;Marcando como última página
				MOV DWORD[EDI + tMemoryPage.size],ECX
				MOV DWORD[ESI + tMemoryPage.next],EDI
				JMP .done
			.addPages:
				ADD DWORD[ESI + tMemoryPage.size],ECX ;Inserindo o total de páginas do bloco
				JMP .done
		.insertMiddle:
			MOV EBP,ECX ;Ponteiro para o final do bloco que será desalocado
			SHL EBP,MEMORY_BITS_PER_PAGE               
			ADD EBP,EDI                             
			
			CMP EBP,EBX ;Verifica se o final do bloco é igual ao início do próximo bloco
			JNE .addNext
				MOV EBP,DWORD[EBX + tMemoryPage.next]
				MOV DWORD[EDI + tMemoryPage.next],EBP ;Setando o ponteiro para o próximo elemento da lista
				
				;Somando as páginas
				MOV EBP,DWORD[EBX + tMemoryPage.size]
				ADD EBP,ECX
				MOV DWORD[EDI + tMemoryPage.size],EBP
				JMP .continue	
			.addNext:
				MOV DWORD[EDI + tMemoryPage.size],ECX ;Inserindo o total de páginas do bloco
				MOV DWORD[EDI + tMemoryPage.next],EBX ;Ponteiro para página seguinte
			.continue:

			CMP EDI,DWORD[memory.firstBlockFree]
			JB .newFirstPage
				;Criando um ponteiro para o bloco de páginas anterior
				MOV EBP,DWORD[ESI + tMemoryPage.size]
				SHL EBP,MEMORY_BITS_PER_PAGE
				ADD EBP,ESI
				
				;Verifica se o final do bloco é igual ao início do bloco desalocado
				CMP EBP,EDI 
				JNE .addPrior
					MOV EBP,DWORD[EDI + tMemoryPage.size] ;Somando as duas páginas
					ADD DWORD[ESI + tMemoryPage.size],EBP ;
					MOV EBP,DWORD[EDI + tMemoryPage.next]
					MOV DWORD[ESI + tMemoryPage.next],EBP
					JMP .done
				.addPrior:
					MOV DWORD[ESI + tMemoryPage.next],EDI ;Ponteiro para página desalocada
					JMP .done
			.newFirstPage:
				MOV DWORD[memory.firstBlockFree],EDI ;Nova página inicial
		.done:

		POP ESI
		POP EBX
	.deallocated:

	SUB DWORD[memory.usage],ECX ;Atualiza o total de páginas usadas

	system_SemaphoreUnlock memory.semaphore

	POP EBP
	RET

;--------------------------------------------------------------------------------------------	
;@description: Macro para mover dados do processo atual para uma nova área de memória.
;@input: EDI << nova área
;@output: -
;@author: alisson_linhares@hotmail.com
memory_MoveCurrentData:
	PUSHAD
	
	;Salvando base em EBX e o total de páginas em EDX
	MOV EBX,EDI
	MOV EDX,ECX
	
	;Movendo conteudo do processo para nova área de memória
	CLD
	MOV ESI,DWORD[SS:BCP_PTR + bcp.base       ]
	MOV ECX,DWORD[SS:BCP_PTR + bcp.memoryUsage]
	SHL ECX,MEMORY_BITS_PER_PAGE - 2
	REP MOVSD                              
	
	;Travando o escalonador
	system_Lock
	
	MOV EAX,EBX
	CALL panel_ResetBase
	
	;Criando um ponteiro para o BCP do processo atual
	ADD EAX,BCP_PTR
		
	;Reconfigurando semáforos usados pelo processo
	MOV EDI,DWORD[scheduler.currentProcess]
	CALL system_SemaphoresDisarm
	
	;Reconfigura o processo atual
	MOV DWORD[scheduler.currentProcess],EAX
	
	;Configurando BCP do processo
	MOV DWORD[EAX + bcp.memoryUsage],EDX
	MOV DWORD[EAX + bcp.base       ],EBX
		
	CMP DWORD[scheduler.numberOfProcess],1
	JA .reconfigList
		;Reconfigurando o processo atual
		MOV DWORD[EAX + bcp.prior],EAX
		MOV DWORD[EAX + bcp.next ],EAX
		JMP .done
	.reconfigList:
		;Reconfigurando a lista de processos
		MOV EDI,DWORD[SS:BCP_PTR + bcp.next ]
		MOV ESI,DWORD[SS:BCP_PTR + bcp.prior]
		MOV DWORD[EDI + bcp.prior],EAX
		MOV DWORD[ESI + bcp.next ],EAX
	.done:	
		
	;Reconfigurando a GDT para a nova área
	MOV WORD[GDT + USER_CODE + 2],BX
	MOV WORD[GDT + USER_DATA + 2],BX
	SHR EBX,16		
	MOV BYTE[GDT + USER_CODE + 4],BL
	MOV BYTE[GDT + USER_DATA + 4],BL
	MOV BYTE[GDT + USER_CODE + 7],BH
	MOV BYTE[GDT + USER_DATA + 7],BH
	
	MOV AX,USER_DATA
	MOV FS,AX
	MOV SS,AX
	MOV GS,AX
	
	;Destravando o escalonador
	system_Unlock
	
	POPAD
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para forçar a alocação de mais memória para o processo atual
;@input: ECX << total de páginas
;@output: -
;@author: alisson_linhares@hotmail.com
memory_ExtendBlock:
	PUSHAD
	
	MOV EBP,memory.semaphore
	CALL system_SemaphoreLock

	CMP DWORD[memory.firstBlockFree],0
	JE .abort
		;Pegando o total de páginas usadas pelo processo
		MOV EAX,DWORD[SS:BCP_PTR + bcp.memoryUsage]
		SHL EAX,MEMORY_BITS_PER_PAGE
		
		;EAX é um ponteiro para o final do processo
		ADD EAX,DWORD[SS:BCP_PTR + bcp.base]
		
		XOR ESI,ESI
		MOV EDI,DWORD[memory.firstBlockFree] 
		JMP .startFindLoop

		.findLoop:
			MOV ESI,EDI ;ESI é o ponteiro para o bloco anterior
			MOV EDI,DWORD[EDI + tMemoryPage.next]
		
		;Procura pela próxima página disponível
		.startFindLoop:
		TEST EDI,EDI
		JZ .allocateNewBlock
		CMP EDI,EAX
		JB .findLoop

		;Verifica se existe um bloco livre posterior ao final do bloco usado pelo programa
		JNE .allocateNewBlock
		;Verifica se existe o espaço que o programa necessita
		CMP DWORD[EDI + tMemoryPage.size],ECX
		JB .allocateNewBlock       
			;Allocando memória
			ADD DWORD[SS:BCP_PTR + bcp.memoryUsage],ECX
			CALL memory.pageListRemove
			JMP .done
		.allocateNewBlock:
			;Forçando a alocação de mais memória
			ADD ECX,DWORD[SS:BCP_PTR + bcp.memoryUsage]
			CALL memory_AllocatePage
			JC .done
				MOV ESI,DWORD[SS:BCP_PTR + bcp.base]
				;Movendo os dados do processo para o endereço de EDI 
				CALL memory_MoveCurrentData
				
				;Deletando o bloco de páginas anteriormente usado pelo processo			
				MOV ECX,DWORD[ESI + BCP_PTR + bcp.memoryUsage]
				MOV EDI,ESI
				CALL memory_DeallocatePage
				JMP .done
	.abort:
		PUSH DWORD MEMORY_PAGE_FAULT
		CALL error_ThrowException
	.done:
	
	system_SemaphoreUnlock memory.semaphore
	POPAD
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para alocar memória para o processo atual.
;@input: ECX << total de bytes
;@output: EDI >> ponteiro para memória alocada
;@author: alisson_linhares@hotmail.com
memory_Malloc:
	PUSHAD
	
	;Verifica se o tamanho da alocação é válido.
	TEST ECX,ECX 
	JZ .abort
	
	;Calculando o total de páginas que será alocado para o processo.
	ADD ECX,4 ;Total reseravado para o tamanho de bytes usados.                             
	SHR ECX,MALLOC_BITS_PER_PAGE
	INC ECX ;Arredondando o total de páginas

	XOR ESI,ESI
	MOV EDI,DWORD[SS:BCP_PTR + bcp.heapPtr]
	JMP .startLoop

	.nextBlock:                              
		MOV ESI,EDI
		MOV EDI,DWORD[SS:EDI + tMemoryPage.next]
	;Procurando por uma página livre de tamanho suficiente
	.startLoop:
	TEST EDI,EDI  ;Verifica se terminou a lista
	JZ .pageNotFound 
	CMP DWORD[SS:EDI + tMemoryPage.size],ECX 
	JB .nextBlock ;Verifica se existe memória suficiente neste bloco

	.pageFound:
		;Verifica se o tamanho do bloco é maior que a necessidade do programa
		CMP DWORD[SS:EDI + tMemoryPage.size],ECX 
		JA .removePage
			;O bloco anterior apontará para o próximo
			MOV EBX,DWORD[SS:EDI + tMemoryPage.next]
			JMP .removeBlock
		.removePage:
			;Retirando as páginas do bloco
			MOV EAX,DWORD[SS:EDI + tMemoryPage.size]
			SUB EAX,ECX
			
			;Calculando o tamanho do bloco que será removido
			MOV EBX,ECX
			SHL EBX,MALLOC_BITS_PER_PAGE             		
			ADD EBX,EDI
			MOV DWORD[SS:EBX + tMemoryPage.size],EAX
		
			;Configurando o ponteiro para a próxima página	
			MOV EAX,DWORD[SS:EDI + tMemoryPage.next]	  
			MOV DWORD[SS:EBX + tMemoryPage.next],EAX 
		.removeBlock:
		
		;Verifica se é o primeiro bloco de páginas.
		TEST ESI,ESI
		JZ .removeFirstBlock
			;O bloco anterior aponta para o depois das páginas removidas
			MOV DWORD[SS:ESI + tMemoryPage.next],EBX 
			JMP .setBlockSize
		.removeFirstBlock:
			MOV DWORD[SS:BCP_PTR + bcp.heapPtr],EBX 
		.setBlockSize:
		
		MOV DWORD[SS:EDI],ECX	
		ADD EDI,4
		JMP .done
	.pageNotFound:
		;Calculando o total de páginas de memória que o processo necessita.
		SHR ECX,MEMORY_BITS_PER_PAGE - MALLOC_BITS_PER_PAGE
		ADD ECX,2 ;Alocando uma página extra de memória.
		
		CALL memory_ExtendBlock
		JC .abort
			;Calculando o ponteiro para o final do bloco de páginas e salvando em EDX
			MOV EDI,DWORD[SS:BCP_PTR + bcp.memoryUsage]
			SHL EDI,MEMORY_BITS_PER_PAGE		
			MOV EDX,EDI
			
			;Calculando o tamanho da memória antes do memory_ExtendBlock
			SHL ECX,MEMORY_BITS_PER_PAGE
			SUB EDI,ECX
			
			;Recuperando o total de bytes requeridos pelo processo
			MOV ECX,DWORD[ESP + STACK_ECX]           
			SHR ECX,MALLOC_BITS_PER_PAGE ;Arredondando para o tamanho usado pelo malloc
			INC ECX                      ;			
			
			;Salvando o total de páginas usadas nesse bloco
			MOV DWORD[SS:EDI],ECX                    	
			
			;Calculando um ponteiro para depois do bloco alocado
			SHL ECX,MALLOC_BITS_PER_PAGE
			LEA EAX,[EDI + ECX]                      
			
			TEST ESI,ESI
			JZ .firstBlock
				MOV DWORD[SS:ESI + tMemoryPage.next],EAX;Fazendo o ponteiro anterior apontar para a nova área de memória livre
				JMP .continue
			.firstBlock:
				MOV DWORD[SS:BCP_PTR + bcp.heapPtr],EAX
			.continue:
			
			;Convertendo o resto de memória que sobrou para páginas do malloc
			SUB EDX,EAX                              
			SHR EDX,MALLOC_BITS_PER_PAGE
			
			MOV DWORD[SS:EAX + tMemoryPage.next],0 ;Apontando para o final
			MOV DWORD[SS:EAX + tMemoryPage.size],EDX
			ADD EDI,4
			JMP .done
	.abort:
		;Retorna um ponteiro null e CF=1 em caso de falha 
		XOR EDI,EDI
		STC
	.done:
	
	;Retornando EDI
	MOV DWORD[ESP + STACK_EDI],EDI                   
	POPAD
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para desalocar memória dos programas.
;@input: EDI << ponteiro para memória
;@output: -
;@author: alisson_linhares@hotmail.com
memory_Free:
	TEST EDI,EDI ;Se o ponteiro for nulo o procedimento retorna para o programa.
	JZ .abort
		PUSHAD

		SUB EDI,4
		MOV ECX,DWORD[SS:EDI] ;Passando para ECX o total de páginas usadas pelo processo
		
		;Verifica se existe algum bloco de memória livre
		CMP DWORD[SS:BCP_PTR + bcp.heapPtr],0
		JNE .insertFirstBlock
			;Inserindo o primeiro bloco
			MOV DWORD[SS:EDI + tMemoryPage.next],0 
			MOV DWORD[SS:EDI + tMemoryPage.size],ECX
			MOV DWORD[SS:BCP_PTR  + bcp.heapPtr],EDI ;Configurando o ponteiro
			JMP .deallocated
		.insertFirstBlock:
			MOV EBX,DWORD[SS:BCP_PTR  + bcp.heapPtr] ;Ponteiro para o primeiro bloco 
			MOV ESI,EBX
			
			;Procurando o bloco de páginas que está na frente do apontado por EDI
			JMP .startLoop
			.nextBlock:
				MOV ESI,EBX
				MOV EBX,DWORD[SS:EBX + tMemoryPage.next]
			.startLoop:
			CMP EDI,EBX 
			JB .insertMiddle
			CMP DWORD[SS:EBX + tMemoryPage.next],0
			JA .nextBlock
			
			.insertFront:
				;Criando um ponteiro para o final do bloco de páginas
				MOV EAX,DWORD[SS:ESI + tMemoryPage.size]
				SHL EAX,MALLOC_BITS_PER_PAGE
				ADD EAX,ESI
					
				CMP EAX,EDI ;Verifica se o final do bloco é igual ao início do bloco desalocado
				JE .addPages
					MOV DWORD[SS:EDI + tMemoryPage.next],0 ;Marcando como última página
					MOV DWORD[SS:EDI + tMemoryPage.size],ECX
					MOV DWORD[SS:ESI + tMemoryPage.next],EDI
					JMP .done
				.addPages:
					ADD DWORD[SS:ESI + tMemoryPage.size],ECX ;Inserindo o total de páginas do bloco
					JMP .done
			.insertMiddle:
				;Criando um ponteiro para o final do bloco que será desalocado
				MOV EAX,ECX
				SHL EAX,MALLOC_BITS_PER_PAGE               
				ADD EAX,EDI                             
				
				;Verifica se o final do bloco é igual ao início do próximo bloco de páginas
				CMP EAX,EBX
				JNE .addNext
					MOV EAX,DWORD[SS:EBX + tMemoryPage.next]
					MOV DWORD[SS:EDI + tMemoryPage.next],EAX ;Setando o ponteiro para o próximo elemento da lista
					
					;Somando as páginas
					MOV EAX,DWORD[SS:EBX + tMemoryPage.size]  
					ADD EAX,ECX
					MOV DWORD[SS:EDI + tMemoryPage.size],EAX
					JMP .continue
				.addNext:
					MOV DWORD[SS:EDI + tMemoryPage.size],ECX ;Inserindo o total de páginas do bloco
					MOV DWORD[SS:EDI + tMemoryPage.next],EBX ;Ponteiro para página seguinte
				.continue:
				
				CMP EDI,DWORD[SS:BCP_PTR  + bcp.heapPtr] ;Verifica se existe página anterior
				JB .newFirstPage
					;Criando um ponteiro para o bloco de páginas anterior
					MOV EAX,DWORD[SS:ESI + tMemoryPage.size]
					SHL EAX,MALLOC_BITS_PER_PAGE
					ADD EAX,ESI
					 
					;Verifica se o final do bloco anterior é igual ao início do bloco desalocado
					CMP EAX,EDI
					JNE .addPrior
						;Somando as páginas
						MOV EAX,DWORD[SS:EDI + tMemoryPage.size] 
						ADD DWORD[SS:ESI + tMemoryPage.size],EAX
						MOV EAX,DWORD[SS:EDI + tMemoryPage.next]
						MOV DWORD[SS:ESI + tMemoryPage.next],EAX
						JMP .done
					.addPrior:
						MOV DWORD[SS:ESI + tMemoryPage.next],EDI ;Ponteiro para página desalocada
						JMP .done
				.newFirstPage:
					MOV DWORD[SS:BCP_PTR + bcp.heapPtr],EDI ;Nova página inicial
			.done:
		.deallocated:
		
		POPAD
	.abort:
	RET
	
;--------------------------------------------------------------------------------------------
;[1] NMM - Neutrino Memory Management: It's a memory management system designed by Alisson Linhares de Carvalho for the neutrino kernel.
;NMM - Neutrino Memory Management Copyright (C) 2011-2012 Alisson Linhares de Carvalho. All rights reserved.