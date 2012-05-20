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
NO_ERROR                     EQU 0

DIVIDE_BY_ZERO_EXCEPTION     EQU 1
DEBUG_EXCEPTION              EQU 2
NMI_EXCEPTION                EQU 3 ;Nonmaskable interrupt exceptions
BREAKPOINT_EXCEPTION         EQU 4
OVERFLOW_EXCEPTION           EQU 5
BOUNDS_CHECK_EXCEPTION       EQU 6
INVALID_OPCODE_EXCEPTION     EQU 7
COPROCESSOR_NOT_AVAILABLE    EQU 8
DOUBLE_FAULT_EXCEPTION       EQU 9
COPROCESSOR_SEGMENT_OVERRUN  EQU 10
INVALID_TSS                  EQU 11
SEGMENT_NOT_PRESENT          EQU 12
STACK_EXCEPTION              EQU 13
GENERAL_PROTECTION_EXCEPTION EQU 14
PAGE_FAULT_EXCEPTIONS        EQU 15
COPRECESSOR_ERROR            EQU 16

MEMORY_PAGE_FAULT            EQU 17 
STORAGE_PAGE_FAULT           EQU 18
STORAGE_INVALID_ID           EQU 19
NFS_INVALID_DISK             EQU 20
NFS_INVALID_PATH             EQU 21
NFS_WRITE_ERROR              EQU 22
NFS_INVALID_SUBNODE          EQU 23
NFS_READ_ERROR               EQU 24
NFS_INVALID_NAME             EQU 25
NFS_EOF_ERROR                EQU 26
NFS_OPEN_ERROR               EQU 27
NFS_MAKE_ERROR               EQU 28
ATA_COMMAND_ERROR            EQU 29
ATAPI_COMMAND_ERROR          EQU 30
SYSTEM_REBOOT_ERROR          EQU 31
SCHEDULER_INVALID_PROCESS    EQU 32
EVENT_BUFFER_VIOLATION       EQU 33

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para tratar falhas do sistema.
;@input: EDI << Código do erro.
;@output: -
;@author: alisson_linhares@hotmail.com
error_IsrExceptionHandler:
	;Reconfigurando os principais registradores.
	MOV AX,KERNEL_DATA
	MOV DS,AX
	MOV FS,AX
	MOV ES,AX
	MOV GS,AX
	
	MOV AX,USER_DATA
	MOV SS,AX
	MOV ESP,1024
	
	;Notificando o kernel sobre o erro
	MOV DWORD[system.status],EDI
	
	;Matando o processo
	XOR EDI,EDI
	CALL scheduler_KillProcess
	
	;Reseta o sistema em caso de falha ao matar o processo
	CALL system_Reboot
	JMP $

;--------------------------------------------------------------------------------------------	
;@description: Macro responsável por informar ao kernel e aos programas sobre a ocorrência de uma falha.
;@input: %1 << Código do erro.
;@output: -
;@author: alisson_linhares@hotmail.com
%macro error_Notification 1
	MOV DWORD[SS:BCP_PTR + bcp.status],%1
	MOV DWORD[system.status],%1
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para notificar falhas de serviços aos programas. 
;@input: DWORD[ESP + 12] << Código do erro.
;@output: -
;@author: alisson_linhares@hotmail.com
error_ThrowException:
	CMP DWORD[SS:BCP_PTR + bcp.signature],BCP_SIGNATURE
	JNE .abort
		;Agendando função de erro
		PUSH EDX
		PUSH EAX

		MOV EAX,DWORD[ESP + 12] ;Carregando valor da pilha
		
		;Informando ao sistema e ao kernel sobre o erro
		error_Notification EAX
		
		MOV EDX,DWORD[SS:BCP_PTR + bcp.errorListener]
		MOV EAX,DWORD[scheduler.currentProcess]
		CALL event_CallProcessHandler
		
		POP EAX
		POP EDX
		
		;FC sempre é modificado em caso de erro
		STC
	.abort:
	RET 4 ;Remove os 4 bytes alocados na pilha
	
;--------------------------------------------------------------------------------------------	
;@description: Macro responsável por informar ao kernel sobre uma exceção.
;@input: %1 << Número da irq
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro isr_ExceptionHandler 1
	MOV EDI,%1
	JMP error_IsrExceptionHandler
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Conjunto de isr de erros para o sistema.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
error_Isr0:  isr_ExceptionHandler DIVIDE_BY_ZERO_EXCEPTION
error_Isr1:  isr_ExceptionHandler DEBUG_EXCEPTION
error_Isr2:  isr_ExceptionHandler NMI_EXCEPTION  ;Nonmaskable interrupt exceptions
error_Isr3:  isr_ExceptionHandler BREAKPOINT_EXCEPTION
error_Isr4:  isr_ExceptionHandler OVERFLOW_EXCEPTION
error_Isr5:  isr_ExceptionHandler BOUNDS_CHECK_EXCEPTION
error_Isr6:  isr_ExceptionHandler INVALID_OPCODE_EXCEPTION
error_Isr7:  isr_ExceptionHandler COPROCESSOR_NOT_AVAILABLE
error_Isr8:  isr_ExceptionHandler DOUBLE_FAULT_EXCEPTION
error_Isr9:  isr_ExceptionHandler COPROCESSOR_SEGMENT_OVERRUN
error_IsrA:  isr_ExceptionHandler INVALID_TSS
error_IsrB:  isr_ExceptionHandler SEGMENT_NOT_PRESENT
error_IsrC:  isr_ExceptionHandler STACK_EXCEPTION
error_IsrD:  isr_ExceptionHandler GENERAL_PROTECTION_EXCEPTION
error_IsrE:  isr_ExceptionHandler PAGE_FAULT_EXCEPTIONS
error_IsrF:  isr_ExceptionHandler NO_ERROR ;Reservado
error_Isr10: isr_ExceptionHandler COPRECESSOR_ERROR