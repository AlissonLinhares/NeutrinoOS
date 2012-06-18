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
;-----------------------------Área reservada para constantes---------------------------------
PROMPT_WIDTH     EQU 80
PROMPT_HEIGHT    EQU 25
TEXT_MODE_BUFFER EQU 0b8000h

;Cores básicas usadas pelo terminal em modo gráfico 24bpp
BLACK            EQU 000000000h
DARKBLUE         EQU 00000007Fh
DARKGREEN        EQU 000007F00h
DARKCYAN         EQU 000007F7Fh
DARKRED          EQU 0007F0000h
DARKMAGENTA      EQU 0007F007Fh
DARKYELLOW       EQU 0007F7F00h
LIGHTGREY        EQU 000AAAAAAh
DARKGREY         EQU 000555555h
BLUE             EQU 0000000FFh
GREEN            EQU 00000FF00h
CYAN             EQU 00000FFFFh
RED              EQU 000FF0000h
MAGENTA          EQU 000FF00FFh
YELLOW           EQU 000FFFF00h
WHITE            EQU 000FFFFFFh

;Máscaras usadas para converter imagens de 24bpp para 16bpp
RED_MASK         EQU 00000000111110000000000000000000b
GREEN_MASK       EQU 00000000000000001111110000000000b
BLUE_MASK        EQU 00000000000000000000000011111000b

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para registros---------------------------------
struc tPrompt	
	.component RESB tComponent_size
	.buffer    RESD 1
	.bufferPos RESW 1
	.color     RESB 1
endstruc

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para variáveis--------------------------------- 
prompt:	
.color  DD BLACK ;Criando um mapa para 4bits de cor
        DD DARKBLUE
        DD DARKGREEN
        DD DARKCYAN
        DD DARKRED
        DD DARKMAGENTA
        DD DARKYELLOW
        DD LIGHTGREY
        DD DARKGREY
        DD BLUE
        DD GREEN
        DD CYAN
        DD RED
        DD MAGENTA
        DD YELLOW
        DD WHITE

;--------------------------------------------------------------------------------------------	
;@description: Macro que converte uma cor de 24bpp para 16bpp.
;@input: %1 << RGB24
;@output: -
;@author: alisson_linhares@hotmail.com
%macro convertToRGB16 2
	MOV %1,((%2 & RED_MASK) >> 8) | ((%2 & GREEN_MASK) >> 5) | ((%2 & BLUE_MASK) >> 3) 
%endmacro		  

;--------------------------------------------------------------------------------------------	
;@description: Macro que configura o prompt de comando.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
%macro prompt_Config 0			
	CMP BYTE[video.bpp],2
	JNE %%vesa24 
		convertToRGB16 DWORD[prompt.color     ],BLACK
		convertToRGB16 DWORD[prompt.color + 4 ],DARKBLUE
		convertToRGB16 DWORD[prompt.color + 8 ],DARKGREEN
		convertToRGB16 DWORD[prompt.color + 12],DARKCYAN
		convertToRGB16 DWORD[prompt.color + 16],DARKRED
		convertToRGB16 DWORD[prompt.color + 20],DARKMAGENTA
		convertToRGB16 DWORD[prompt.color + 24],DARKYELLOW
		convertToRGB16 DWORD[prompt.color + 28],LIGHTGREY
		convertToRGB16 DWORD[prompt.color + 32],DARKGREY
		convertToRGB16 DWORD[prompt.color + 36],BLUE
		convertToRGB16 DWORD[prompt.color + 40],GREEN
		convertToRGB16 DWORD[prompt.color + 44],CYAN
		convertToRGB16 DWORD[prompt.color + 48],RED
		convertToRGB16 DWORD[prompt.color + 52],MAGENTA
		convertToRGB16 DWORD[prompt.color + 56],YELLOW
		convertToRGB16 DWORD[prompt.color + 60],WHITE
	%%vesa24:
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para criar um prompt.
;@input: ESI << prompt ptr, EDI << panel ptr
;@output: -
;@author: alisson_linhares@hotmail.com
prompt_Create:
	MOV DWORD[SS:BCP_PTR + bcp.promptPtr     ],ESI
	MOV DWORD[SS:BCP_PTR + bcp.promptPanelPtr],EDI
	
	;Verifica se o sistema está em modo texto
	CMP BYTE[system.mode],GRAPHICS_MODE                          
	JNE .done
		CALL panel_Add
		CALL panel_Open
		CALL prompt_Clear
		CALL panel_Draw
	.done:
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para limpar vídeo do console.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
prompt_Clear:
	PUSH EDI
	MOV EDI,DWORD[FS:BCP_PTR + bcp.promptPtr]

	TEST EDI,EDI
	JZ .skipClear
		PUSH EAX
		PUSH ECX

		;Colocando na posição (0,0) do prompt
		MOV WORD[FS:EDI + tPrompt.bufferPos],0

		;Configurando cor do texto [Cor| 0 |Cor| 0 ]
		MOV AL,BYTE[FS:EDI + tPrompt.color]
		SHL EAX,24
		MOV AH,BYTE[FS:EDI +  tPrompt.color]

		;Verifica se o sistema está em modo texto
		CMP BYTE[system.mode],GRAPHICS_MODE
		JE .graphicMode
			MOV EDI,TEXT_MODE_BUFFER
			JMP .textMode	
		.graphicMode:
			MOV EDI,DWORD[FS:EDI + tPrompt.buffer]
			ADD EDI,DWORD[FS:BCP_PTR + bcp.base  ]
		.textMode:		
		
		;Limpando a tela com a cor contida em EAX
		CLD
		MOV ECX,PROMPT_HEIGHT * PROMPT_WIDTH / 2
		REP STOSD

		POP ECX
		POP EAX
	.skipClear:
	
	POP EDI
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para imprimir String no prompt. 
;@input: EDI << *string
;@output: -
;@author: alisson_linhares@hotmail.com
prompt_PrintString:
	PUSH DX
	PUSH EDI
	
	JMP .startLoop
	.printLoop:
		CALL DWORD[isr0x30.prompt_PrintChar]
		INC EDI
	.startLoop:
		MOV DL,BYTE[FS:EDI] ;Usa FS como registrador de segmento
	TEST DL,DL ;Verifica se terminou a string 
	JNZ .printLoop

	POP EDI
	POP DX
	RET	

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para imprimir valor numérico no prompt.
;@input: EDI << valor, EBX << base, CL << Alinhamento
;@output: -
;@author: alisson_linhares@hotmail.com
prompt_PrintInteger:
	;Verifica se a base é válida
	CMP EBX,16
	JA .invalidBase 
	CMP EBX,1
	JBE .invalidBase 
		PUSH CX
		PUSH EDX
		PUSH EAX
		
		SHL CX,8 ;Movendo bit de alinhamento para CH e limpando CL
		MOV EAX,EDI
		
		.convertLoop:
			XOR EDX,EDX
			DIV EBX 
			
			;Verifica se deve imprimir em outra base numérica
			CMP EDX,10
			JB .decBase
				ADD EDX,41h - 0Ah
				JMP .otherBase
			.decBase:
				ADD EDX,30h  
			.otherBase:

			;Salvando na pilha o char do número
			PUSH DX  
			INC CL
		TEST EAX,EAX
		JNZ .convertLoop 

		;Verifica se deve fazer o alinhamento
		CMP CH,CL
		JBE .skipAlign
			SUB CH,CL
			
			.printAlign:
				MOV DL,30h
				CALL prompt_PrintChar
			DEC CH
			JNZ .printAlign
		.skipAlign:

		;Imprimindo valor contido na pilha
		.printNextChar:
			POP DX       
			CALL prompt_PrintChar
		DEC CL
		JNZ .printNextChar  

		POP EAX
		POP EDX
		POP CX
	.invalidBase:
	RET	

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para pintar uma letra no prompt.
;@input: DL << CHAR
;@output: -
;@author: alisson_linhares@hotmail.com
prompt_PrintChar:
	;Verifica se existe algum prompt cadastrado
	CMP DWORD[FS:BCP_PTR + bcp.promptPtr],0
	JE .abort
		PUSHAD
		
		MOV EBP,DWORD[FS:BCP_PTR + bcp.promptPtr]
		
		;Verifica se o sistema está em modo texto
		CMP BYTE[system.mode],GRAPHICS_MODE
		JE .graphicMode
			MOV EDI,TEXT_MODE_BUFFER
			JMP .textMode
		.graphicMode:
			;Carregando o ponteiro para o buffer do prompt
			MOV EDI,DWORD[FS:EBP + tPrompt.buffer]
			ADD EDI,DWORD[FS:BCP_PTR + bcp.base] 
		.textMode:
		
		;Verifica se deve dar um scroll+
		CMP WORD[FS:EBP + tPrompt.bufferPos],PROMPT_WIDTH * (PROMPT_HEIGHT - 1)   
		JB .skipVideoScroll
			CLD
			LEA ESI,[EDI + PROMPT_WIDTH * 2]
			MOV ECX,PROMPT_WIDTH * (PROMPT_HEIGHT - 1) / 2
			REP MOVSD
			
			MOV WORD[FS:EBP + tPrompt.bufferPos],PROMPT_WIDTH * (PROMPT_HEIGHT - 2) 
			SUB EDI,PROMPT_WIDTH * (PROMPT_HEIGHT - 1) * 2 ;Inserindo uma linha no final do buffer
		.skipVideoScroll:
		
		MOVZX ESI,WORD[FS:EBP + tPrompt.bufferPos]
		LEA EDI,[EDI + ESI * 2]
		MOV DH,BYTE[FS:EBP + tPrompt.color] ;Setando a cor da letra

		CMP DL,NEW_LINE
		JE .newLine
		CMP DL,08h
		JE .back
			MOV WORD[EDI],DX
			INC WORD[FS:EBP + tPrompt.bufferPos]
			JMP .continue
		.newLine:
			XOR DX,DX
			MOV AX,WORD[FS:EBP + tPrompt.bufferPos]
			MOV BX,PROMPT_WIDTH 
			DIV BX                                       ;Divide pela largura
			INC AX                                       ;Incrementa a posição  

			MUL BX                                       ;Multiplica  AX por 160 
			MOV WORD[FS:EBP + tPrompt.bufferPos],AX	
			JMP .continue
		.back:
			XOR DL,DL
			MOV WORD[EDI - 2],DX
			DEC WORD[FS:EBP + tPrompt.bufferPos]
		.continue:	
		
		POPAD
	.abort:	
    RET
	
;--------------------------------------------------------------------------------------------	
;@description: Procedimento para atualizar o prompt.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
prompt_Update:
	;Verifica se o prompt existe
	CMP DWORD[FS:BCP_PTR + bcp.promptPtr],0
	JE .skipUpdate
	
		;Verifica se o sistema está em modo gráfico
		CMP BYTE[system.mode],GRAPHICS_MODE
		JE .graphicMode
			PUSH DX
			PUSH AX
			PUSH EBX
			
			MOV EBX,DWORD[FS:BCP_PTR + bcp.promptPtr]
			MOV BX,WORD[FS:EBX + tPrompt.bufferPos]
			
			;Movendo o cursor
			MOV DX,0x3D4                 
			MOV AL,0x0F
			OUT DX,AL
			
			INC DX ;Porta 03D5h
			MOV AL,BL
			OUT DX,AL  
			
			DEC DX ;Porta 03D4h
			MOV AL,0x0E
			OUT DX,AL 
			
			INC DX ;Porta 03D5h
			MOV AL,BH
			OUT DX,AL 
			
			POP EBX
			POP AX
			POP DX
			JMP .textoMode
		.graphicMode:
			PUSH EDI
			PUSH ESI
			
			MOV EDI,DWORD[FS:BCP_PTR + bcp.promptPtr]
			MOV ESI,DWORD[FS:BCP_PTR + bcp.promptPanelPtr]
			CALL panel_DrawComponent
			
			POP ESI
			POP EDI
		.textoMode:
	.skipUpdate:
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para desenhar um prompt em modo gráfico.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
prompt_Draw:
	.Y EQU 4
	.X EQU 6
	.H EQU 8
	.W EQU 10
	.BASE EQU 12
	
	;Carregando o ponteiro para o buffer do terminal
	MOV EDI,DWORD[EDI + tPrompt.buffer]
	
	TEST AL,AL ;Não existe Mouse UP para o prompt
	JNZ .skipDraw        
	TEST EDI,EDI ;Verifica se existe um ponteiro para o buffer do prompt
	JZ .skipDraw
	SUB WORD[ESP + .W],CHAR_WIDTH
	JS .skipDraw ;Verifica se existe espaço suficiente para escrever uma letra.
	SUB WORD[ESP + .H],CHAR_HEIGHT
	JS .skipDraw ;Verifica se existe espaço suficiente para escrever uma letra.
		MOV CX,WORD[ESP + .X]
		MOV DX,WORD[ESP + .Y]
		
		;Configurando largura e altura
		ADD WORD[ESP + .W],CX
		ADD WORD[ESP + .H],DX

		ADD EDI,DWORD[ESP + .BASE]
		LEA EAX,[EDI + PROMPT_WIDTH * PROMPT_HEIGHT * 2] ;Ponteiro para o final do buffer

		.drawLoop:
			CMP CX,WORD[ESP + .W] ;Verifica se a posição atual é maior que a largura da tela
			JLE .print
				MOV CX,WORD[ESP + .X] ;Reseta o X
				ADD DX,CHAR_HEIGHT
				CMP DX,WORD[ESP + .H] ;Termina se posição y for maior que o a altura da tela
				JG .skipDraw
			.print:
				;Carregando a cor de fundo da letra
				MOV BL,BYTE[EDI + 1] 
				AND EBX,000000F0h
				SHR EBX,2
				MOV EBX,DWORD[DS:EBX + prompt.color]

				;Pintando o fundo da letra
				MOV SI,CHAR_HEIGHT
				MOV BP,CHAR_WIDTH
				CALL DWORD[isr0x30.video_PaintRectangle]
				
				;Carregando a cor da letra
				MOV BL,BYTE[EDI + 1]
				AND EBX,0000000Fh
				SHL EBX,2
				MOV EBX,DWORD[DS:EBX + prompt.color]
				
				;Carregando a img nif da letra	
				MOVZX ESI,BYTE[EDI]		
				SHL ESI,2
				ADD ESI,DWORD[gui.asciiListPtr]
				MOV ESI,DWORD[ESI]
				
				;Pintando a letra no console
				CALL DWORD[isr0x30.video_DrawNIF2]
				ADD CX,CHAR_WIDTH
			.continue:
			
			ADD EDI,2 ;Proxima letra	
		CMP EAX,EDI ;Verifica se terminou o buffer
		JAE .drawLoop
	.skipDraw: 
	RET 12 ;Desalocando os 12bytes passados na pilha.