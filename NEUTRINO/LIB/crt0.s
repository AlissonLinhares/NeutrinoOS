; Copyright (C) 2011-2012 Alisson Linhares de Carvalho.
; All rights reserved.
;
; This file is part of the neutrino lib.
;
; The neutrino lib is free software: you can redistribute it and/or 
; modify it under the terms of the GNU Lesser General Public License as 
; published by the Free Software Foundation, either version 3 of the 
; License, or (at your option) any later version.
;
; The neutrino lib is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU Lesser General Public License for more details.
;
; You should have received a copy of the GNU Lesser General Public License
; along with the neutrino lib. If not, see <http://www.gnu.org/licenses/>.
;
;--------------------------------------------------------------------------------------------

[BITS 32]
[global __start]
[extern main   ]

;--------------------------------------------------------------------------------------------
;Área reservada para constantes
EVENT_BUFFER_SIZE EQU 5

;--------------------------------------------------------------------------------------------
;@description: Procedimento responsável por iniciar um programa.
;@input: [EAX,EBX,ECX,EDX,EDI,ESI,EBP] << 0, ESP << 4096 - BCP_size, EIP << 4096, [DS,ES,SS,FS,GS] << USER_DATA, CS << USER_CODE 
;@output: ALL
;@author: alisson_linhares@hotmail.com;
__start:
	CALL main
	
	;Desalocando recursos usados pelo programa
	XOR EDI,EDI
	MOV EAX,37 ;Matando o processo
	INT 30h

;--------------------------------------------------------------------------------------------
;@description: Procedimento responsável por controlar eventos do sistema. processHandler é executado sempre que houver um elemento cadastrado no buffer de eventos.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com;
__event:
	.status         DB 0
	.buffer         TIMES EVENT_BUFFER_SIZE DD 0 ;[Lista circular de tratadores de eventos]
	.bufferSize     DB 0
	.bufferBegin    DD __event.buffer
	.bufferEnd      DD __event.buffer
.processHandler:
	CMP BYTE[SS:__event.bufferSize],0
	JE .done
		PUSHAD
		
		.loadNextHandler:
			MOV EAX,DWORD[SS:__event.bufferBegin]
			
			CMP DWORD[SS:EAX],__End
			JBE .invalidCall
				CALL DWORD[SS:EAX]
			.invalidCall:
			
			;Calculando a posição do novo elemento
			CMP DWORD[SS:__event.bufferBegin],__event.buffer + (EVENT_BUFFER_SIZE - 1) * 4
			JAE .resetPosition
				ADD DWORD[SS:__event.bufferBegin],4
				JMP .bufferConfigured
			.resetPosition:
				;Resetando o buffer
				MOV DWORD[SS:__event.bufferBegin],__event.buffer
			.bufferConfigured:
		
		;Decrementa o total de elementos
		DEC BYTE[SS:__event.bufferSize]
		JNZ .loadNextHandler

		POPAD
	.done:

	;Liberando o sistema de eventos
	MOV BYTE[SS:__event.status],0
	IRET
__End:
