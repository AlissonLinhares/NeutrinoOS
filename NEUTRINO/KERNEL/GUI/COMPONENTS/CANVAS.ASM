; Copyright (C) 2011-2012 Alisson Linhares de Carvalho.
; All rights reserved.
;
; This file is part of the neutrino kernel.
;
; The neutrino kernel is free software: you can redistribute it and/or 
; modify it under the terms of the GNU General Public License as 
; published by the Free Software Foundation, either version 3 of the 
; License, or (at your option) any later version.
;
; The neutrino kernel is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with the neutrino kernel. If not, see <http://www.gnu.org/licenses/>.
;
;--------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para registros---------------------------------
struc tCanvas
	.component          RESB tComponent_size
	.bufferPtr          RESD 1 ;Ponteiro para o buffer de vídeo do programa. 
endstruc

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para desenhar uma área grafica na tela.
;@input: ESP << X, ESP + 2 << Y, ESP + 4 << W, ESP + 6 << H, ESP + 8 << base 
;@output: ALL
;@author: alisson_linhares@hotmail.com
canvas_Draw:
	.Y EQU 4
	.X EQU 6
	.H EQU 8
	.W EQU 10
	.BASE EQU 12

	MOV EDI,DWORD[EDI + tCanvas.bufferPtr]
	
	TEST AL,AL
	JNZ .skipDraw
	TEST EDI,EDI
	JE .skipDraw
		MOV CX,WORD[ESP + .X]
		MOV DX,WORD[ESP + .Y]
		MOV BP,WORD[ESP + .W]
		MOV SI,WORD[ESP + .H]
		
		;Colocando o ponteiro na área de dados do kernel.
		ADD EDI,DWORD[ESP + .BASE]
		
		;Pintando o conteúdo do buffer na tela
		CALL DWORD[isr0x30.video_PaintArea]
	.skipDraw:
	RET 12 ;Desalocando os 12bytes passados na pilha.