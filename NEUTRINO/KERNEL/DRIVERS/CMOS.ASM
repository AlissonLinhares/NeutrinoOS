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
RT_CMOS_PORT_ADDRESS EQU 070h
RT_CMOS_PORT_DATA    EQU 071h

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para registros---------------------------------
struc tCMOS_Map ;Mapa da CMOS          
	.seconds       RESB 1
	.secondsAlarm  RESB 1
	.minutes       RESB 1
	.minutesAlarm  RESB 1
	.hours         RESB 1
	.hoursAlarm    RESB 1
	.dayOfWeek     RESB 1  
	.dayOfMonth    RESB 1
	.month         RESB 1
	.year          RESB 1
	.statusRegA    RESB 1
	.statusRegB    RESB 1
	.statusRegC    RESB 1
	.statusRegD    RESB 1
	.reserved      RESB 51
endstruc

;@description: Formato da hora retornada pelo sistema.
struc tTimerFormat
	.hours         RESB 1
	.minutes       RESB 1
	.seconds       RESB 1
	.day           RESB 1
	.month         RESB 1
	.year          RESB 1
endstruc

;--------------------------------------------------------------------------------------------	
;@description: Macro para ler dados da CMOS.
;@input: AL << índice da CMOS
;@output: AL >> valor contido no índice
;@author: alisson_linhares@hotmail.com
%macro cmos_Read 0
	;Carregando dados da CMOS
	OUT RT_CMOS_PORT_ADDRESS,AL
	IN AL,RT_CMOS_PORT_DATA  
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro para ler dados da CMOS.
;@input: %1 << índice da CMOS, %2 << byte que será gravado
;@output: AL >> byte que será gravado
;@author: alisson_linhares@hotmail.com
%macro cmos_Write 2
	;Gravando dados na CMOS
	MOV AL,%1
	OUT RT_CMOS_PORT_ADDRESS,AL
	MOV AL,%2
	OUT RT_CMOS_PORT_DATA,AL
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Procedimento que retornar data e hora do sistema.
;@input: EDI << tTimerFormat
;@output: -
;@author: alisson_linhares@hotmail.com;
cmos_GetTimer:
	PUSH EAX

	;Esperando o termino da atualização da CMOS "Sem isso pode ocorrer erros na leitura e escrita"
	.waitLoop:
		MOV AL,tCMOS_Map.statusRegA
		cmos_Read
	TEST AL,80h
	JNZ .waitLoop

	;Carregando hora
	MOV AL,tCMOS_Map.hours
	CALL cmos_ReadByte
	MOV BYTE[SS:EDI + tTimerFormat.hours],AL
	
	;Carregando minutos
	MOV AL,tCMOS_Map.minutes
	CALL cmos_ReadByte		
	MOV BYTE[SS:EDI + tTimerFormat.minutes],AL
	
	;Carregando segundos
	MOV AL,tCMOS_Map.seconds
	CALL cmos_ReadByte		
	MOV BYTE[SS:EDI + tTimerFormat.seconds],AL
	
	;Carregando dia	
	MOV AL,tCMOS_Map.dayOfMonth
	CALL cmos_ReadByte 		
	MOV BYTE[SS:EDI + tTimerFormat.day],AL
	
	;Carregando mês
	MOV AL,tCMOS_Map.month
	CALL cmos_ReadByte		
	MOV BYTE[SS:EDI + tTimerFormat.month],AL
	
	;Carregando ano
	MOV AL,tCMOS_Map.year
	CALL cmos_ReadByte		
	MOV BYTE[SS:EDI + tTimerFormat.year],AL
	
	POP EAX
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento que ler da CMOS e converte o valor de BCD para byte.
;@input: AL << índice da CMOS
;@output: AL >> valor contido no índice
;@author: alisson_linhares@hotmail.com
cmos_ReadByte:
	PUSH DX
	
	;Lendo BCD da CMOS
	OUT RT_CMOS_PORT_ADDRESS,AL
	IN AL,RT_CMOS_PORT_DATA 
	
	;Convertendo de BCD para byte
	MOV AH,AL
	AND AH,11110000b
	MOV DL,AH
	SHR DL,1
	SHR AH,3
	ADD DL,AH
	AND AL,00001111b
	ADD AL,DL
	
	POP DX
	RET