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
;-----------------------------�rea reservada para constantes---------------------------------
START_PAGE_LIST         EQU 0100000h

MEMORY_SIGNATURE        EQU 0x89ABCDEF
MEMORY_BITS_PER_PAGE    EQU 9
MEMORY_PAGE_SIZE        EQU 1 << MEMORY_BITS_PER_PAGE

MALLOC_BITS_PER_PAGE    EQU 4
MALLOC_PAGE_SIZE        EQU 1 << MALLOC_BITS_PER_PAGE

;--------------------------------------------------------------------------------------------
;-----------------------------�rea reservada para registros----------------------------------
;@description: Registro usado no controle dos blocos de p�ginas.
struc tMemoryPage
	.next           RESD 1
	.size           RESD 1
endstruc

;@description: Registro projetado para troca de informa��es entre a nlib e o kernel.
struc tMemoryInfo
	.signature      RESD 1
	.usage          RESD 1
	.size           RESD 1
endstruc

;--------------------------------------------------------------------------------------------
;-----------------------------�rea reservada para vari�veis----------------------------------
memory:
.map                    TIMES 8 DD 0,0 ;Mapa da mem�ria.
.semaphore              DD 0 ;Vari�vel para controle de concorr�ncia.           
.firstBlockFree         DD START_PAGE_LIST ;Ponteiro para o primeiro bloco de mem�ria livre.
.usage                  DD START_PAGE_LIST >> MEMORY_BITS_PER_PAGE ;Mem�ria em uso.
.size                   DD START_PAGE_LIST >> MEMORY_BITS_PER_PAGE ;Mem�ria total.

;--------------------------------------------------------------------------------------------
;@description: Macro projetada para carregar informa��es da mem�ria e calcular o tamanhos dos blocos livres.
;@remarks: A mem�ria � dividia em �reas, algumas n�o podem ser usadas.
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
		MOV DWORD[ES:EDI + 20],1 ;For�ando uma entrada valida na ACPI 3.X 
		MOV ECX,24
		INT 15h
		
		;Verifica se ocorreu algum erro
		JC %%abort
		CMP EAX,0534D4150h ;Verifica se EAX retornou SMAP 
		JNE %%abort
			
		CMP WORD[ES:EDI + 10h],1h ;1h - mem�ria reservada para o sistema
		JNE %%invalidMemArea
		CMP DWORD[ES:EDI],START_PAGE_LIST
		JB  %%invalidMemArea
			;Montando o mapa de mem�ria
			MOV EAX,DWORD[ES:EDI]
			MOV DWORD[DS:ESI],EAX
			
			MOV EAX,DWORD[ES:EDI + 08h]
			MOV DWORD[DS:ESI + 4],EAX  ;Tamanho da �rea em bytes
			ADD ESI,8
		%%invalidMemArea:
	TEST EBX,EBX ;Verifica se o mapa terminou          
	JNZ %%memLoop
	%%abort:
%endmacro

;--------------------------------------------------------------------------------------------
;@description: Macro projetada para configurar o gerente de mem�ria. 
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro memory_Config 0
	MOV ESI,memory.map
	MOV EDI,START_PAGE_LIST
	
	;Configurando as �reas de mem�ria que podem ser usadas
	%%readNextArea:
		MOV EBX,DWORD[ESI    ] ;Carregando a base  
		MOV EAX,DWORD[ESI + 4] ;Carregando o tamanho do bloco	
		
		SHR EAX,MEMORY_BITS_PER_PAGE
		TEST EBX,MEMORY_PAGE_SIZE - 1 ;Verifica se existe valores entre 0 e MEMORY_PAGE_SIZE         
		JZ %%continue
			AND EBX,0FFFFFFFFh - (MEMORY_PAGE_SIZE - 1)                
			INC EBX ;Arredondando para o pr�ximo m�ltiplo de MEMORY_PAGE_SIZE
			DEC EAX
		%%continue:
	
		TEST EAX,EAX ;Se o bloco for menor que uma p�gina ele � descartado 
		JZ %%discardArea
	        ;Configurando o novo bloco de mem�ria
			ADD DWORD[memory.size],EAX ;Calculando a quantidade de mem�ria reconhecida pelo sistema
			MOV DWORD[EBX + tMemoryPage.size],EAX
			MOV DWORD[EDI + tMemoryPage.next],EBX  
			MOV EDI,EBX ;Anterior aponta para atual
		%%discardArea:
		
		ADD ESI,8 ;Incrementa o mapa
	CMP DWORD[ESI + 4],0 ;Verifica se existe mais mem�ria
	JE %%exit
	CMP ESI,memory.map + 64 ;Verifica se o mapa terminou
	JB %%readNextArea
	%%exit:

	MOV DWORD[EBX + tMemoryPage.next],0 ;O �ltimo bloco de p�ginas aponta para 0 
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Procedimento usado para remover blocos de p�ginas.
;@input: ECX << total de p�ginas, EDI << Ponteiro para o bloco livre atual, ESI << Ponteiro para o bloco livre anterior
;@output: ALL
;@author: alisson_linhares@hotmail.com
.pageListRemove:
	ADD DWORD[memory.usage],ECX ;Atualizamdo o total de p�ginas usadas

	;Verifica se existe mem�ria suficiente neste bloco
	CMP DWORD[EDI + tMemoryPage.size],ECX 
	JA .removePage
		MOV EAX,DWORD[EDI + tMemoryPage.next] ;Anterior aponta para o pr�ximo
		JMP .removeBlock
	.removePage:
		MOV EBP,DWORD[EDI + tMemoryPage.size]
		SUB EBP,ECX ;Retirando as p�ginas do bloco, EBP tem o total de p�ginas usadas 

		;Calculando o tamanho da p�gina
		MOV EAX,ECX
		SHL EAX,MEMORY_BITS_PER_PAGE ;EAX contem o tamanho do bloco que ser� removido
		ADD EAX,EDI
		MOV DWORD[EAX + tMemoryPage.size],EBP
	
		;Configurando o ponteiro para pr�xima p�gina
		MOV EBP,DWORD[EDI + tMemoryPage.next]
		MOV DWORD[EAX + tMemoryPage.next],EBP
	.removeBlock:
	
	TEST ESI,ESI ;Verifica se � o primeiro
	JZ .removeFirstBlock
		;Remove o bloco atual
		MOV DWORD[ESI + tMemoryPage.next],EAX ;O ponteiro anterior aponta para depois das p�ginas removidas
		RET
	.removeFirstBlock:
		MOV DWORD[memory.firstBlockFree],EAX         
	RET
	
;--------------------------------------------------------------------------------------------	
;@description: Procedimento para retornar informa��es do gerente de mem�ria.
;@input: EDI << tMemoryInfo
;@output: -
;@author: alisson_linhares@hotmail.com
memory_GetInfo:
	;Verifica se o registro enviado � v�lido.
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
;@description: Procedimento para alocar p�ginas de mem�ria.
;@input: ECX << total de p�ginas
;@output: EDI >> ponteiro para mem�ria
;@author: alisson_linhares@hotmail.com
memory_AllocatePage:
	PUSH EBP
	PUSH ESI
	PUSH EAX
	
	MOV EBP,memory.semaphore
	CALL system_SemaphoreLock
	
	;Prote��o contra aloca��o inv�lida de mem�ria.
	TEST ECX,ECX
	JZ .pageNotFound

	XOR ESI,ESI
	MOV EDI,DWORD[memory.firstBlockFree] ;Ponteiro para o primeiro bloco de p�ginas
	JMP .startLoop              
	
	;Procurando por uma p�gina livre de tamanho suficiente
	.nextBlock:
		MOV ESI,EDI ;ESI � o ponteiro para o bloco anterior
		MOV EDI,DWORD[EDI + tMemoryPage.next]
	.startLoop:
	TEST EDI,EDI ;EDI retorna 0 em caso de erro   
	JZ .pageNotFound 
	CMP DWORD[EDI + tMemoryPage.size],ECX ;Verifica se existe mem�ria suficiente neste bloco 
	JB .nextBlock
		
	.pageFound:
		CALL memory.pageListRemove ;Removendo da lista a quantidade de p�ginas
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
;@description: Procedimento para desalocar p�ginas de mem�ria.
;@input: ECX << total de p�ginas, EDI << Ponteiro para mem�ria
;@output: -
;@author: alisson_linhares@hotmail.com
memory_DeallocatePage:
	PUSH EBP
	
	MOV EBP,memory.semaphore
	CALL system_SemaphoreLock
	
	CMP DWORD[memory.firstBlockFree],0 ;Verifica se existe blocos de mem�ria livres
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
		
		;Procurando o bloco de p�ginas que est� na frente do apontado por EDI
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
				
			CMP EBP,EDI ;Verifica se o final do bloco � igual ao in�cio do bloco desalocado
			JE .addPages
				MOV DWORD[EDI + tMemoryPage.next],0 ;Marcando como �ltima p�gina
				MOV DWORD[EDI + tMemoryPage.size],ECX
				MOV DWORD[ESI + tMemoryPage.next],EDI
				JMP .done
			.addPages:
				ADD DWORD[ESI + tMemoryPage.size],ECX ;Inserindo o total de p�ginas do bloco
				JMP .done
		.insertMiddle:
			MOV EBP,ECX ;Ponteiro para o final do bloco que ser� desalocado
			SHL EBP,MEMORY_BITS_PER_PAGE               
			ADD EBP,EDI                             
			
			CMP EBP,EBX ;Verifica se o final do bloco � igual ao in�cio do pr�ximo bloco
			JNE .addNext
				MOV EBP,DWORD[EBX + tMemoryPage.next]
				MOV DWORD[EDI + tMemoryPage.next],EBP ;Setando o ponteiro para o pr�ximo elemento da lista
				
				;Somando as p�ginas
				MOV EBP,DWORD[EBX + tMemoryPage.size]
				ADD EBP,ECX
				MOV DWORD[EDI + tMemoryPage.size],EBP
				JMP .continue	
			.addNext:
				MOV DWORD[EDI + tMemoryPage.size],ECX ;Inserindo o total de p�ginas do bloco
				MOV DWORD[EDI + tMemoryPage.next],EBX ;Ponteiro para p�gina seguinte
			.continue:

			CMP EDI,DWORD[memory.firstBlockFree]
			JB .newFirstPage
				;Criando um ponteiro para o bloco de p�ginas anterior
				MOV EBP,DWORD[ESI + tMemoryPage.size]
				SHL EBP,MEMORY_BITS_PER_PAGE
				ADD EBP,ESI
				
				;Verifica se o final do bloco � igual ao in�cio do bloco desalocado
				CMP EBP,EDI 
				JNE .addPrior
					MOV EBP,DWORD[EDI + tMemoryPage.size] ;Somando as duas p�ginas
					ADD DWORD[ESI + tMemoryPage.size],EBP ;
					MOV EBP,DWORD[EDI + tMemoryPage.next]
					MOV DWORD[ESI + tMemoryPage.next],EBP
					JMP .done
				.addPrior:
					MOV DWORD[ESI + tMemoryPage.next],EDI ;Ponteiro para p�gina desalocada
					JMP .done
			.newFirstPage:
				MOV DWORD[memory.firstBlockFree],EDI ;Nova p�gina inicial
		.done:

		POP ESI
		POP EBX
	.deallocated:

	SUB DWORD[memory.usage],ECX ;Atualiza o total de p�ginas usadas

	system_SemaphoreUnlock memory.semaphore

	POP EBP
	RET

;--------------------------------------------------------------------------------------------	
;@description: Macro para mover dados do processo atual para uma nova �rea de mem�ria.
;@input: EDI << nova �rea
;@output: -
;@author: alisson_linhares@hotmail.com
memory_MoveCurrentData:
	PUSHAD
	
	;Salvando base em EBX e o total de p�ginas em EDX
	MOV EBX,EDI
	MOV EDX,ECX
	
	;Movendo conteudo do processo para nova �rea de mem�ria
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
		
	;Reconfigurando sem�foros usados pelo processo
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
		
	;Reconfigurando a GDT para a nova �rea
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
;@description: Procedimento para for�ar a aloca��o de mais mem�ria para o processo atual
;@input: ECX << total de p�ginas
;@output: -
;@author: alisson_linhares@hotmail.com
memory_ExtendBlock:
	PUSHAD
	
	MOV EBP,memory.semaphore
	CALL system_SemaphoreLock

	CMP DWORD[memory.firstBlockFree],0
	JE .abort
		;Pegando o total de p�ginas usadas pelo processo
		MOV EAX,DWORD[SS:BCP_PTR + bcp.memoryUsage]
		SHL EAX,MEMORY_BITS_PER_PAGE
		
		;EAX � um ponteiro para o final do processo
		ADD EAX,DWORD[SS:BCP_PTR + bcp.base]
		
		XOR ESI,ESI
		MOV EDI,DWORD[memory.firstBlockFree] 
		JMP .startFindLoop

		.findLoop:
			MOV ESI,EDI ;ESI � o ponteiro para o bloco anterior
			MOV EDI,DWORD[EDI + tMemoryPage.next]
		
		;Procura pela pr�xima p�gina dispon�vel
		.startFindLoop:
		TEST EDI,EDI
		JZ .allocateNewBlock
		CMP EDI,EAX
		JB .findLoop

		;Verifica se existe um bloco livre posterior ao final do bloco usado pelo programa
		JNE .allocateNewBlock
		;Verifica se existe o espa�o que o programa necessita
		CMP DWORD[EDI + tMemoryPage.size],ECX
		JB .allocateNewBlock       
			;Allocando mem�ria
			ADD DWORD[SS:BCP_PTR + bcp.memoryUsage],ECX
			CALL memory.pageListRemove
			JMP .done
		.allocateNewBlock:
			;For�ando a aloca��o de mais mem�ria
			ADD ECX,DWORD[SS:BCP_PTR + bcp.memoryUsage]
			CALL memory_AllocatePage
			JC .done
				MOV ESI,DWORD[SS:BCP_PTR + bcp.base]
				;Movendo os dados do processo para o endere�o de EDI 
				CALL memory_MoveCurrentData
				
				;Deletando o bloco de p�ginas anteriormente usado pelo processo
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
;@description: Procedimento para alocar mem�ria para o processo atual.
;@input: ECX << total de bytes
;@output: EDI >> ponteiro para mem�ria alocada
;@author: alisson_linhares@hotmail.com
memory_Malloc:
	PUSHAD
	
	;Verifica se o tamanho da aloca��o � v�lido.
	TEST ECX,ECX 
	JZ .abort
	
	;Calculando o total de p�ginas que ser� alocado para o processo.
	ADD ECX,4 ;Total reseravado para o tamanho de bytes usados.                             
	SHR ECX,MALLOC_BITS_PER_PAGE
	INC ECX ;Arredondando o total de p�ginas

	XOR ESI,ESI
	MOV EDI,DWORD[SS:BCP_PTR + bcp.heapPtr]
	JMP .startLoop

	.nextBlock:                              
		MOV ESI,EDI
		MOV EDI,DWORD[SS:EDI + tMemoryPage.next]
	;Procurando por uma p�gina livre de tamanho suficiente
	.startLoop:
	TEST EDI,EDI  ;Verifica se terminou a lista
	JZ .pageNotFound 
	CMP DWORD[SS:EDI + tMemoryPage.size],ECX 
	JB .nextBlock ;Verifica se existe mem�ria suficiente neste bloco

	.pageFound:
		;Verifica se o tamanho do bloco � maior que a necessidade do programa
		CMP DWORD[SS:EDI + tMemoryPage.size],ECX 
		JA .removePage
			;O bloco anterior apontar� para o pr�ximo
			MOV EBX,DWORD[SS:EDI + tMemoryPage.next]
			JMP .removeBlock
		.removePage:
			;Retirando as p�ginas do bloco
			MOV EAX,DWORD[SS:EDI + tMemoryPage.size]
			SUB EAX,ECX
			
			;Calculando o tamanho do bloco que ser� removido
			MOV EBX,ECX
			SHL EBX,MALLOC_BITS_PER_PAGE             		
			ADD EBX,EDI
			MOV DWORD[SS:EBX + tMemoryPage.size],EAX
		
			;Configurando o ponteiro para a pr�xima p�gina	
			MOV EAX,DWORD[SS:EDI + tMemoryPage.next]	  
			MOV DWORD[SS:EBX + tMemoryPage.next],EAX 
		.removeBlock:
		
		;Verifica se � o primeiro bloco de p�ginas.
		TEST ESI,ESI
		JZ .removeFirstBlock
			;O bloco anterior aponta para o depois das p�ginas removidas
			MOV DWORD[SS:ESI + tMemoryPage.next],EBX 
			JMP .setBlockSize
		.removeFirstBlock:
			MOV DWORD[SS:BCP_PTR + bcp.heapPtr],EBX 
		.setBlockSize:
		
		MOV DWORD[SS:EDI],ECX	
		ADD EDI,4
		JMP .done
	.pageNotFound:
		;Calculando o total de p�ginas de mem�ria que o processo necessita.
		SHR ECX,MEMORY_BITS_PER_PAGE - MALLOC_BITS_PER_PAGE
		ADD ECX,2 ;Alocando uma p�gina extra de mem�ria.
		
		CALL memory_ExtendBlock
		JC .abort
			;Calculando o ponteiro para o final do bloco de p�ginas e salvando em EDX
			MOV EDI,DWORD[SS:BCP_PTR + bcp.memoryUsage]
			SHL EDI,MEMORY_BITS_PER_PAGE		
			MOV EDX,EDI
			
			;Calculando o tamanho da mem�ria antes do memory_ExtendBlock
			SHL ECX,MEMORY_BITS_PER_PAGE
			SUB EDI,ECX
			
			;Recuperando o total de bytes requeridos pelo processo
			MOV ECX,DWORD[ESP + STACK_ECX]           
			SHR ECX,MALLOC_BITS_PER_PAGE ;Arredondando para o tamanho usado pelo malloc
			INC ECX                      ;			
			
			;Salvando o total de p�ginas usadas nesse bloco
			MOV DWORD[SS:EDI],ECX                    	
			
			;Calculando um ponteiro para depois do bloco alocado
			SHL ECX,MALLOC_BITS_PER_PAGE
			LEA EAX,[EDI + ECX]                      
			
			TEST ESI,ESI
			JZ .firstBlock
				MOV DWORD[SS:ESI + tMemoryPage.next],EAX;Fazendo o ponteiro anterior apontar para a nova �rea de mem�ria livre
				JMP .continue
			.firstBlock:
				MOV DWORD[SS:BCP_PTR + bcp.heapPtr],EAX
			.continue:
			
			;Convertendo o resto de mem�ria que sobrou para p�ginas do malloc
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
;@description: Procedimento para desalocar mem�ria dos programas.
;@input: EDI << ponteiro para mem�ria
;@output: -
;@author: alisson_linhares@hotmail.com
memory_Free:
	TEST EDI,EDI ;Se o ponteiro for nulo o procedimento retorna para o programa.
	JZ .abort
		PUSHAD

		SUB EDI,4
		MOV ECX,DWORD[SS:EDI] ;Passando para ECX o total de p�ginas usadas pelo processo
		
		;Verifica se existe algum bloco de mem�ria livre
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
			
			;Procurando o bloco de p�ginas que est� na frente do apontado por EDI
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
				;Criando um ponteiro para o final do bloco de p�ginas
				MOV EAX,DWORD[SS:ESI + tMemoryPage.size]
				SHL EAX,MALLOC_BITS_PER_PAGE
				ADD EAX,ESI
					
				CMP EAX,EDI ;Verifica se o final do bloco � igual ao in�cio do bloco desalocado
				JE .addPages
					MOV DWORD[SS:EDI + tMemoryPage.next],0 ;Marcando como �ltima p�gina
					MOV DWORD[SS:EDI + tMemoryPage.size],ECX
					MOV DWORD[SS:ESI + tMemoryPage.next],EDI
					JMP .done
				.addPages:
					ADD DWORD[SS:ESI + tMemoryPage.size],ECX ;Inserindo o total de p�ginas do bloco
					JMP .done
			.insertMiddle:
				;Criando um ponteiro para o final do bloco que ser� desalocado
				MOV EAX,ECX
				SHL EAX,MALLOC_BITS_PER_PAGE               
				ADD EAX,EDI                             
				
				;Verifica se o final do bloco � igual ao in�cio do pr�ximo bloco de p�ginas
				CMP EAX,EBX
				JNE .addNext
					MOV EAX,DWORD[SS:EBX + tMemoryPage.next]
					MOV DWORD[SS:EDI + tMemoryPage.next],EAX ;Setando o ponteiro para o pr�ximo elemento da lista
					
					;Somando as p�ginas
					MOV EAX,DWORD[SS:EBX + tMemoryPage.size]  
					ADD EAX,ECX
					MOV DWORD[SS:EDI + tMemoryPage.size],EAX
					JMP .continue
				.addNext:
					MOV DWORD[SS:EDI + tMemoryPage.size],ECX ;Inserindo o total de p�ginas do bloco
					MOV DWORD[SS:EDI + tMemoryPage.next],EBX ;Ponteiro para p�gina seguinte
				.continue:
				
				CMP EDI,DWORD[SS:BCP_PTR  + bcp.heapPtr] ;Verifica se existe p�gina anterior
				JB .newFirstPage
					;Criando um ponteiro para o bloco de p�ginas anterior
					MOV EAX,DWORD[SS:ESI + tMemoryPage.size]
					SHL EAX,MALLOC_BITS_PER_PAGE
					ADD EAX,ESI
					 
					;Verifica se o final do bloco anterior � igual ao in�cio do bloco desalocado
					CMP EAX,EDI
					JNE .addPrior
						;Somando as p�ginas
						MOV EAX,DWORD[SS:EDI + tMemoryPage.size] 
						ADD DWORD[SS:ESI + tMemoryPage.size],EAX
						MOV EAX,DWORD[SS:EDI + tMemoryPage.next]
						MOV DWORD[SS:ESI + tMemoryPage.next],EAX
						JMP .done
					.addPrior:
						MOV DWORD[SS:ESI + tMemoryPage.next],EDI ;Ponteiro para p�gina desalocada
						JMP .done
				.newFirstPage:
					MOV DWORD[SS:BCP_PTR + bcp.heapPtr],EDI ;Nova p�gina inicial
			.done:
		.deallocated:
		
		POPAD
	.abort:
	RET
	
;--------------------------------------------------------------------------------------------
;[1] NMM - Neutrino Memory Management: It's a memory management system designed by Alisson Linhares de Carvalho for the neutrino kernel.
;NMM - Neutrino Memory Management Copyright (C) 2011-2012 Alisson Linhares de Carvalho. All rights reserved.