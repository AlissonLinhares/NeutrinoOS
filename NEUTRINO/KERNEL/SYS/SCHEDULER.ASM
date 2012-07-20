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
STACK_SIZE             EQU 4096
DYNAMIC_MEM_SIZE       EQU 4096
BCP_SIGNATURE          EQU 'BCP!'
BCP_PTR                EQU STACK_SIZE - bcp_size ;O BCP começa depois da pilha dos processos
KILL_ALL_PROCESS       EQU 0FFFFFFFFh
KILL_CURRENT_PROCESS   EQU 0

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para registros---------------------------------
;@description: Formato do bloco de controle de processo.
struc bcp
	.next               RESD 1  ;Ponteiro para o endereço do próximo processo.
	.prior              RESD 1  ;Ponteiro para o endereço do processo anterior. 
	
	;Dados relativos ao processador.
	.eax                RESD 1  ;Registrador acumulador.
	.ebx                RESD 1  ;Registrador base.
	.ecx                RESD 1  ;Registrador contador.
	.edx                RESD 1  ;Registrador de dados. 
	.edi                RESD 1  ;Registrador de índice de destino.
	.esi                RESD 1  ;Registrador de índice de origem.
	.esp                RESD 1  ;Ponteiro para pilha.
	.ebp                RESD 1  ;Resgistrador base para pilha.
	.code               RESW 1  ;Segmento de código.
	.data               RESW 1  ;Segmento de dados.
	
	;Dados de controle.
	.status             RESD 1  ;Estado do processo.
	.base               RESD 1  ;Endereço de memória do processo.
	.name               RESB 11 ;Nome do processo.

	;Dados relativos ao coprocessador. 
.fpuState:
	.controlWord        RESW 1  ;Registrador de controla da FPU.
	.reserved_0         RESW 1  ;Reservado.
	.statusWord         RESW 1  ;Status da FPU.
	.reserved_1         RESW 1  ;Reservado.
	.tagWord            RESW 1  ;Estado dos registradores da FPU.
	.reserved_2         RESW 1  ;Reservado.
	.ip                 RESD 1  ;Ponteiro para a próxima instrução.
	.cs                 RESW 1  ;Segmento de código usado
	.reserved_3         RESW 1  ;Reservado.
	.operandAddress     RESD 1  ;Endereço dos operandos.
	.ds                 RESW 1  ;Segmento de dados usado.
	.reserved_4         RESW 1  ;Reservado.
	.st0                RESB 10 ;Registrador STR0 da FPU.
	.st1                RESB 10 ;Registrador STR1 da FPU.
	.st2                RESB 10 ;Registrador STR2 da FPU.
	.st3                RESB 10 ;Registrador STR3 da FPU.
	.st4                RESB 10 ;Registrador STR4 da FPU.
	.st5                RESB 10 ;Registrador STR5 da FPU.
	.st6                RESB 10 ;Registrador STR6 da FPU.
	.st7                RESB 10 ;Registrador STR7 da FPU.
	
	;Dados gerenciais.
	.memoryUsage        RESD 1  ;Memória usada pelo processo.
	.heapPtr            RESD 1  ;Ponteiro para área de memória interna do programa.
	.promptPtr          RESD 1  ;Reservado para o modo compatibilidade do prompt.
	.promptPanelPtr     RESD 1  ;Reservado para o modo compatibilidade do prompt.
	.errorListener      RESD 1  ;Ponteiro para um tratador de erros. 
	.signature          RESD 1  ;Assinatura do BCP. "BCP!"
endstruc

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para variáveis--------------------------------- 
scheduler:
.currentProcess  DD 0
.numberOfProcess DD 0

;--------------------------------------------------------------------------------------------	
;@description: Macro para iniciar o escalonador do sistema.
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro scheduler_Start 0
	CMP DWORD[scheduler.numberOfProcess],0
	JE %%abort
		CLI
		DEC BYTE[system.irqsEnabled]
		MOV BYTE[mousePacket.count],MOUSE_MAX_COUNT ;Resetando a contagem de pacotes do mouse. Pode ocorrer algumas interrupções após a configuração

		MOV EAX,DWORD[scheduler.currentProcess]
		MOV EAX,DWORD[EAX + bcp.base]
		MOV WORD[GDT + USER_CODE + 2],AX
		MOV WORD[GDT + USER_DATA + 2],AX
		SHR EAX,16
		MOV BYTE[GDT + USER_CODE + 4],AL
		MOV BYTE[GDT + USER_DATA + 4],AL
		MOV BYTE[GDT + USER_CODE + 7],AH
		MOV BYTE[GDT + USER_DATA + 7],AH

		;Configurando registradores de segmento.
		MOV AX,USER_DATA
		MOV GS,AX
		MOV FS,AX
		MOV SS,AX
		MOV ES,AX
		MOV DS,AX

		;Carregando valores dos registradores
		MOV ESP,DWORD[BCP_PTR + bcp.esp]
		IRETD
	%%abort:

	CALL system_Reboot
%endmacro

;--------------------------------------------------------------------------------------------
;@description: Macro para salvar o estado dos registradores no BCP.
;@input: All
;@output: -
;@author: alisson_linhares@hotmail.com
%macro scheduler_SaveProcessState 0
	MOV DWORD[SS:BCP_PTR + bcp.eax ],EAX
	MOV DWORD[SS:BCP_PTR + bcp.ebx ],EBX
	MOV DWORD[SS:BCP_PTR + bcp.ecx ],ECX
	MOV DWORD[SS:BCP_PTR + bcp.edx ],EDX
	MOV DWORD[SS:BCP_PTR + bcp.esi ],ESI
	MOV DWORD[SS:BCP_PTR + bcp.ebp ],EBP
	MOV DWORD[SS:BCP_PTR + bcp.edi ],EDI
	MOV DWORD[SS:BCP_PTR + bcp.esp ],ESP
	MOV WORD [SS:BCP_PTR + bcp.data],ES
	FSAVE [SS:BCP_PTR + bcp.fpuState]
%endmacro

;--------------------------------------------------------------------------------------------
;@description: Macro para carregar o estado dos registradores.
;@input: EDI << ponteiro para o BCP
;@output: All
;@author: alisson_linhares@hotmail.com
%macro scheduler_LoadProcessState 0
	;Configurando para o segmento de dados do kernel
	MOV AX,KERNEL_DATA
	MOV DS,AX
	
	MOV DWORD[scheduler.currentProcess],EDI
	
	;Configurando base da gdt
	MOV EAX,DWORD[EDI + bcp.base]
	MOV WORD[GDT + USER_CODE + 2],AX
	MOV WORD[GDT + USER_DATA + 2],AX
	SHR EAX,16
	MOV BYTE[GDT + USER_CODE + 4],AL
	MOV BYTE[GDT + USER_DATA + 4],AL
	MOV BYTE[GDT + USER_CODE + 7],AH
	MOV BYTE[GDT + USER_DATA + 7],AH

	;Configurando registradores de segmento.
	MOV AX,USER_DATA
	MOV GS,AX
	MOV FS,AX
	MOV SS,AX
	MOV ES,WORD[SS:BCP_PTR + bcp.data]
	MOV DS,WORD[SS:BCP_PTR + bcp.data]

	;Carregando valores dos registradores
	MOV ESP,DWORD[SS:BCP_PTR + bcp.esp] ;Configurando pilha
	MOV EAX,DWORD[SS:BCP_PTR + bcp.eax]
	MOV EBX,DWORD[SS:BCP_PTR + bcp.ebx]
	MOV ECX,DWORD[SS:BCP_PTR + bcp.ecx]
	MOV EDX,DWORD[SS:BCP_PTR + bcp.edx]
	MOV ESI,DWORD[SS:BCP_PTR + bcp.esi]
	MOV EBP,DWORD[SS:BCP_PTR + bcp.ebp]
	MOV EDI,DWORD[SS:BCP_PTR + bcp.edi]
	FRSTOR [SS:BCP_PTR + bcp.fpuState]
%endmacro

;--------------------------------------------------------------------------------------------
;@description: Escalonador do sistema operacional. Serve para controlar o uso do processador entre os processos.
;@remarks: Essa função é instalada na interrupção 20h "System Timer". A troca de contexto é feita a cada 18.2ms.
;@input: All
;@output: All
;@author: alisson_linhares@hotmail.com
scheduler_IrqHandler:
	;Verifica se o escalonador está ligado
	CMP BYTE[CS:system.irqsEnabled],0
	JA .abort
		CMP DWORD[CS:scheduler.numberOfProcess],1
		JBE .monoTaskMode
			;Salvando os dados do processo atual
			scheduler_SaveProcessState
			
.LOADER_PROCESS_STATE__: ;Label global usada por scheduler_KillProcess
			MOV EDI,DWORD[SS:BCP_PTR + bcp.next]

			;Carregando os dados do novo processo
			scheduler_LoadProcessState
		.monoTaskMode:
		
		;Verifica se o processo atual deve executar algum evento.
		CMP BYTE[SS:EVENT_PTR + tEvent.status],0
		JA .skipEventCall
		CMP BYTE[SS:EVENT_PTR + tEvent.bufferSize],0
		JE .skipEventCall
			INC BYTE[SS:EVENT_PTR + tEvent.status]
			
			;Inserindo a chamada na pilha do processo. 
			SUB ESP,12
			MOV DWORD[ESP    ],EVENT_PTR + tEvent.code
			MOV DWORD[ESP + 4],USER_CODE
			MOV DWORD[ESP + 8],2097734
		.skipEventCall:
	.abort:
	
	;Agendando uma nova chamada para essa função.
	PUSH AX
	MOV AL,020h
	OUT 020h,AL
	POP AX
	IRETD

;--------------------------------------------------------------------------------------------
;@description: Procedimento para inserir um bcp na lista de processos.
;@input: EDI << ponteiro para o bcp
;@output: -
;@author: alisson_linhares@hotmail.com
scheduler_InsertProcess:
	system_Lock ;Controle de concorrência.
	
	;Verifica se o processo é válido
	CMP DWORD[EDI + bcp.signature],BCP_SIGNATURE
	JNE .abort	
		
		;Verifica se existe algum elemento na lista
		CMP DWORD[scheduler.numberOfProcess],0
		JA .insertNewBcp
			;A cabeça da lista aponta para o primeiro elemento
			MOV DWORD[scheduler.currentProcess],EDI
			MOV DWORD[EDI + bcp.next   ],EDI
			MOV DWORD[EDI + bcp.prior  ],EDI
			JMP .continue
		.insertNewBcp:
			PUSH ESI
			PUSH EAX
			
			MOV EAX,DWORD[scheduler.currentProcess]
			MOV ESI,DWORD[EAX + bcp.next]
			MOV DWORD[EDI + bcp.next ],ESI
			MOV DWORD[ESI + bcp.prior],EDI

			MOV DWORD[EAX + bcp.next],EDI
			MOV DWORD[EDI + bcp.prior],EAX

			POP EAX
			POP ESI
		.continue:

		;Incrementa o total de processos
		INC DWORD[scheduler.numberOfProcess]
		JMP .done
	.abort:		
		PUSH DWORD SCHEDULER_INVALID_PROCESS
		CALL error_ThrowException ;Retornando erro
	.done:
	
	system_Unlock
	RET

;--------------------------------------------------------------------------------------------
;@description: Procedimento para remover um bcp da lista de processos.
;@input: EDI << Ponteiro para o bcp
;@output: -
;@author: alisson_linhares@hotmail.com
scheduler_RemoverProcess:	
	system_Lock ;Controle de concorrência.
	
	;Verifica se o processo é válido
	CMP DWORD[EDI + bcp.signature],BCP_SIGNATURE
	JNE .abort
		PUSH EDI
		PUSH EAX
		
		MOV EAX,DWORD[EDI + bcp.next ]    ;Pegando o próximo
		MOV EDI,DWORD[EDI + bcp.prior]    ;Pegando o anterior 
		MOV DWORD[EDI + bcp.next ],EAX    ;Anterior.próximo = próximo
		MOV DWORD[EAX + bcp.prior],EDI    ;Próximo.anterior = anterior
		
		POP EAX
		POP EDI

		;Decrementa o total de processos
		DEC DWORD[scheduler.numberOfProcess]
		JMP .done
	.abort:	
		PUSH DWORD SCHEDULER_INVALID_PROCESS
		CALL error_ThrowException ;Retornando erro
	.done:	
	
	system_Unlock
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para configurar um processo para que o mesmo possa ser executado.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
scheduler_ConfigProcess:
	PUSHAD

	;Configurando registradores
	FSAVE [EDI + BCP_PTR + bcp.fpuState] ;Salvando no BCP do novo processo o estado da FPU.
	MOV DWORD[EDI + BCP_PTR + bcp.esp ],BCP_PTR - 12 ;Configurando pilha para antes do BCP
	MOV WORD [EDI + BCP_PTR + bcp.code],USER_CODE ;Segmento de código
	MOV WORD [EDI + BCP_PTR + bcp.data],USER_DATA ;Segmento de dados

	MOV DWORD[EDI + BCP_PTR + bcp.base],EDI ;Configurando Base do Sistema
	MOV DWORD[EDI + BCP_PTR + bcp.status],0
	MOV DWORD[EDI + BCP_PTR + bcp.errorListener],0

	;Configurando área de controle	
	MOV DWORD[EDI + BCP_PTR + bcp.memoryUsage],ECX
	MOV DWORD[EDI + BCP_PTR + bcp.signature  ],BCP_SIGNATURE

	;Configurando memória dinâmica
	SHL ECX,MEMORY_BITS_PER_PAGE
	SUB ECX,DYNAMIC_MEM_SIZE  ;ECX é um ponteiro para o inicio da lista dinâmica

	MOV DWORD[EDI + BCP_PTR + bcp.heapPtr],ECX	
	MOV DWORD[EDI + ECX + tMemoryPage.next],0
	MOV DWORD[EDI + ECX + tMemoryPage.size],DYNAMIC_MEM_SIZE/ MALLOC_PAGE_SIZE

	;Configurando pilha 
	MOV DWORD[EDI + BCP_PTR - 4 ],2097734         
	MOV DWORD[EDI + BCP_PTR - 8 ],USER_CODE
	MOV DWORD[EDI + BCP_PTR - 12],STACK_SIZE

	;Configurando prompt do sistema
	MOV DWORD[EDI + BCP_PTR + bcp.promptPtr     ],0
	MOV DWORD[EDI + BCP_PTR + bcp.promptPanelPtr],0

	;Configurando Nome do processo 
	CLD
	LEA EDI,[EDI + BCP_PTR + bcp.name]
	MOV ECX,5 ;Movendo 10 bytes para o BCP
	REP MOVSW
	MOV BYTE[EDI],0 ;Marcando final do nome

	;Inserindo o ponteiro na fila de processos	
	MOV EDI,DWORD[ESP + STACK_EDI] ;Recuperando o valor de EDI
	ADD EDI,BCP_PTR ;EDI aponta para o bcp
	CALL scheduler_InsertProcess

	POPAD
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para iniciar um processo.
;@input: ESI << Cominho para o arquivo.
;@output: -
;@author: alisson_linhares@hotmail.com
scheduler_StartProcess:
	PUSHAD

	;Convertendo a string contendo o caminho do arquivo. Colocando a mesma na área de dados do kernel.
	ADD ESI,DWORD[SS:BCP_PTR + bcp.base]    

	;Procurando pelo arquivo em disco
	CALL nfs_Find
	JC .abort
		;Verifica se o nó retornado é binário
		TEST BYTE[EDI + tSubNode.type],NFS_SUBNODETYPE_BINARY
		JZ .invalidType
			LEA ESI,[EDI + tSubNode.name]             ;Ponteiro para o nome do processo
			MOV EBX,DWORD[EDI + tSubNode.dataPtr]     ;Setor do programa
			MOV ECX,DWORD[EDI + tSubNode.size]        ;Total de páginas que devem ser alocadas
			;Reservando o espaço da pilha
			ADD ECX,(STACK_SIZE + DYNAMIC_MEM_SIZE)/MEMORY_PAGE_SIZE

			;Alocando memória para o processo.
			CALL memory_AllocatePage                        
			JC .done
				;Carregando o programa para depois da pilha
				ADD EDI,STACK_SIZE
				SUB ECX,(STACK_SIZE + DYNAMIC_MEM_SIZE)/MEMORY_PAGE_SIZE
				
				CALL storage_ReadPage
				JC .storageError
					SUB EDI,STACK_SIZE
					ADD ECX,(STACK_SIZE + DYNAMIC_MEM_SIZE)/MEMORY_PAGE_SIZE
					;Configurando o processo e inserindo na lista do escalonador
					CALL scheduler_ConfigProcess            
					JMP .done
				.storageError:
				
				;Desalocando memória
				SUB EDI,STACK_SIZE
				ADD ECX,(STACK_SIZE + DYNAMIC_MEM_SIZE)/MEMORY_PAGE_SIZE
				CALL memory_DeallocatePage 
				JMP .done
	.invalidType:		
		;Notificando o kernel sobre o erro
		PUSH DWORD NFS_INVALID_SUBNODE
		CALL error_ThrowException
	.done:
		;Desativando semáforo
		system_SemaphoreUnlock EDX + storage.diskList + tStorage.semaphore	
	.abort:
	
	POPAD
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para finalizar um processo.
;@input: EDI << (base do processo || 0 - Mata o processo atual || FFFFFFFF - Mata todos os processos, menos o atual)
;@output: -
;@author: alisson_linhares@hotmail.com
scheduler_KillProcess:
	PUSH EDI
	
	system_Lock  ;Travando o escalonador.

	;Verifica qual porcesso deve ser removido. 
	CMP EDI,KILL_ALL_PROCESS ;FFFFFFFF - Mata todos os processos.
	JE .killAllProcess
	TEST EDI,EDI             ;0 - Mata o processo atual.
	JZ .killCurrentProcess
		ADD EDI,BCP_PTR  ;Criando um ponteiro para o BCP
		
		;Verifica se o processo que será morto é o atual.
		CMP EDI,DWORD[scheduler.currentProcess]
		JE .killCurrentProcess

		;Desalocando o processo passado por parâmetro
		CALL scheduler_Deallocate
		JMP .done
	.killAllProcess:
		;Carrega o bcp do processo atual.
		MOV EDI,DWORD[scheduler.currentProcess]
		
		.nextProcess:
			;Termina se o próximo processo for o atual. 
			MOV EDI,DWORD[EDI + bcp.next]
			CMP EDI,DWORD[scheduler.currentProcess]
			JE .done
			
			;Matando o processo.
			CALL scheduler_Deallocate	
		JMP .nextProcess
	.killCurrentProcess:
		;Desalocando o processo atual
		MOV EDI,DWORD[scheduler.currentProcess]
		CALL scheduler_Deallocate
		
		MOV EDI,DWORD[EDI + bcp.next]
		MOV DWORD[scheduler.currentProcess],EDI

		CLI ;Desativa interrupções
		system_Unlock ;Ativa o escalonador, eventos e interrupções
		;Carrega o estado de um novo processo
		JMP scheduler_IrqHandler.LOADER_PROCESS_STATE__         
	.done:
	
	system_Unlock ;Destravando o escalonador
	
	POP EDI
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para desalocar um processo.
;@input: EDI << bcp do processo
;@output: -
;@author: alisson_linhares@hotmail.com
scheduler_Deallocate:
	system_Lock
	
	CMP DWORD[EDI + bcp.signature],BCP_SIGNATURE
	JNE .abort
		PUSH EAX
		PUSH ECX
		PUSH EDI
		
		;Desativando os semáforos usados pelo processo
		XOR EAX,EAX
		CALL system_SemaphoresDisarm
		
		;Desalocando painel e componentes usados pelo processo
		CALL panel_Deallocate
		
		;Desalocando memória usada pelo processo
		MOV ECX,DWORD[EDI + bcp.memoryUsage]
		SUB EDI,BCP_PTR
		CALL memory_DeallocatePage
		
		;Matando o processo
		ADD EDI,BCP_PTR
		CALL scheduler_RemoverProcess
		
		;Verifica se existe algum elemento na lista
		CMP DWORD[scheduler.numberOfProcess],0;Verifica se existem processos a serem removidos
		JA .skipReboot
			JMP system_Reboot.REBOOT_NOW__ ;O sistema reinicia se o número de processo chegar a 0!
		.skipReboot:
		
		POP EDI
		POP ECX
		POP EAX
		JMP .done
	.abort:	
		PUSH DWORD SCHEDULER_INVALID_PROCESS
		CALL error_ThrowException
	.done:
	
	system_Unlock
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento que retorna informações relativas aos processos.
;@input: -
;@output: EDI >> Memória contendo informações dos processos, 0 em caso de erro.
;@author: alisson_linhares@hotmail.com
scheduler_GetInfo:
	PUSHAD
	
	system_Lock
	
	;Calculando o total de memória que será alocada para o retorno da função.
	MOV EAX,DWORD[scheduler.numberOfProcess]
	MOV ECX,EAX

	;Multiplicando por 24 e somando com o total de processos.
	SHL EAX,4 ;EAX *= 16
	LEA ECX,[EAX + ECX * 8 + 4]

	;Alocando memória.
	CALL memory_Malloc
	JC .abort
		MOV DWORD[ESP + STACK_EDI],EDI ;Valor que será retornado para o programa.

		ADD EDI,DWORD[FS:BCP_PTR + bcp.base]
		MOV ESI,DWORD[scheduler.currentProcess]
		
		;Alocando o número de processos no primeiro elemento do bloco retornado.
		MOV EAX,DWORD[scheduler.numberOfProcess]
		STOSD
		
		.loadNextProcess:
			;Retornando pilha do processo.
			MOV EAX,[ESI + bcp.esp        ]
			STOSD
			
			;Retornando base do processo.
			MOV EAX,[ESI + bcp.base       ]
			STOSD
			
			;Retornando memória usada pelo processo.
			MOV EAX,[ESI + bcp.memoryUsage]
			STOSD
			
			;Retornando o nome do processo.
			MOV EAX,[ESI + bcp.name       ]
			STOSD
			MOV EAX,[ESI + bcp.name + 4   ]
			STOSD
			MOV EAX,[ESI + bcp.name + 8   ]
			STOSD
			
			;Muda para o próximo processo.
			MOV ESI,DWORD[ESI + bcp.next]
		CMP ESI,DWORD[scheduler.currentProcess]
		JNE .loadNextProcess
	.abort:
	
	system_Unlock
	
	POPAD
	RET