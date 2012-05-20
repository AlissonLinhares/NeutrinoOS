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

; You should have received a copy of the GNU General Public License
; along with the neutrino kernel. If not, see <http://www.gnu.org/licenses/>.
;
;--------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para registros---------------------------------
struc tLabel
	.component	RESB tComponent_size
	.name		RESD 1 ;Ponteiro para o nome da label.
endstruc

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para pintar uma label na tela.
;@input: ESP << X, ESP + 2 << Y, ESP + 4 << W, ESP + 6 << H, ESP + 8 << base 
;@output: ALL
;@author: alisson_linhares@hotmail.com
label_Draw:
	.Y EQU 4
	.X EQU 6
	.H EQU 8
	.W EQU 10
	.BASE EQU 12
	
	TEST AL,AL
	JNZ .skipDraw
		MOV CX,WORD[ESP + .X]
		MOV DX,WORD[ESP + .Y]
		MOV BP,WORD[ESP + .W]
		MOV SI,WORD[ESP + .H]
		
		;Pintando o fundo do component
		MOV EBX,DWORD[EDI + tComponent.bgColor]
		CALL DWORD[isr0x30.video_PaintRectangle]
		
		MOV EBX,DWORD[EDI + tComponent.textColor]
		
.PRINT_TEXT__:  ;Label global usada por button_Draw para escrever textos na tela
		CMP DWORD[EDI + tLabel.name],0
		JE .skipDraw
		SUB WORD[ESP + .H],CHAR_HEIGHT
		JS .skipDraw ;Verifica se existe espaço suficiente para escrever uma letra.
		SUB WORD[ESP + .W],CHAR_WIDTH
		JS .skipDraw ;Verifica se existe espaço suficiente para escrever uma letra.
			ADD WORD[ESP + .W],CX
			ADD WORD[ESP + .H],DX

			;Configurando ponteiro para trabalhar na área de dados do kernel
			MOV EDI,DWORD[EDI + tLabel.name]
			ADD EDI,DWORD[ESP + .BASE]
			
			;Escrevendo o texto da label
			.printLoop:
				CMP BYTE[EDI],NEW_LINE ;Verificando se deve pular a linha 
				JE .newLine
				CMP CX,WORD[ESP + .W]
				JLE .print

				.newLine:
					MOV CX,WORD[ESP + .X] ;Reseta o X
					ADD DX,CHAR_HEIGHT
					CMP DX,WORD[ESP + .H]
					JG .skipDraw
				.print:
					;Imprimindo caracter
					MOVZX ESI,BYTE[EDI]
					SHL ESI,2 ;Multiplica por 4
					ADD ESI,DWORD[gui.asciiListPtr] ;Soma com o ponteiro da lista de nifs
					MOV ESI,DWORD[ESI]
					
					CALL DWORD[isr0x30.video_DrawNIF2] ;Pintando a letra
					ADD CX,CHAR_WIDTH
				.continue:

				INC EDI ;Próxima letra
			CMP BYTE[EDI],0
			JNE .printLoop
	.skipDraw:
	RET 12 ;Desalocando os 12bytes passados na pilha. 