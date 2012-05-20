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
;------------------------------Área reservada para registros---------------------------------
struc tButton
	.component          RESB tComponent_size
	.name               RESD 1 ;Ponteiro para o nome da label.
endstruc

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para pintar um botão simples na tela.
;@input: ESP << X, ESP + 2 << Y, ESP + 4 << W, ESP + 6 << H, ESP + 8 << base 
;@output: ALL
;@author: alisson_linhares@hotmail.com
button_Draw:
	.Y EQU 4
	.X EQU 6
	.H EQU 8
	.W EQU 10
	.BASE EQU 12
	
	MOV CX,WORD[ESP + .X]
	MOV DX,WORD[ESP + .Y]
	MOV BP,WORD[ESP + .W]
	MOV SI,WORD[ESP + .H]
	
	;Verifica o tipo de pintura
	TEST AL,AL
	JNZ .color1
		MOV EBX,DWORD[EDI + tComponent.bgColor]
		CALL DWORD[isr0x30.video_PaintRectangle] ;Pintando a parte interna do botão
		
		MOV EBX,DWORD[EDI + tComponent.textColor]
		JMP .color2
	.color1: ;Mouse UP
		MOV EBX,DWORD[EDI + tComponent.textColor]
		CALL DWORD[isr0x30.video_PaintRectangle] ;Pintando a parte interna do botão
	
		MOV EBX,DWORD[EDI + tComponent.bgColor]
	.color2:
	
	CALL DWORD[isr0x30.video_DrawRectangle] ;Pintando o contorno do botão
	JMP label_Draw.PRINT_TEXT__ ;Saltando para função que escreve textos na tela