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
;@description: Procedimento que retorna a posição da memória vídeo com base no x e y passados.
;@input: DX << Y, CX << X;
;@output: EDI >> ponteiro para memória de vídeo;
;@author: alisson_linhares@hotmail.com
video_CalcXY_16: 
	PUSH EDX
	PUSH EAX
	
	MOV AX,WORD[video.width]  
	MUL DX
	
	;Movendo DX:AX para EDX
	SHL EDX,16
	MOV DX,AX
	
	;Somando com a largura
	MOVZX EDI,CX
	ADD EDI,EDX
	
	;Convertendo para bmp 16bits
	SHL EDI,1
	
	;Retornando em EDI o ponteiro para a memória
	ADD EDI,DWORD[video.memoryPtr] 
	
	POP EAX
	POP EDX
	RET
	
;--------------------------------------------------------------------------------------------	
;@description: Procedimento para pintar a tela em modo gráfico.
;@input: DX << Cor;
;@output: -
;@author: alisson_linhares@hotmail.com
video_Bgcolor_16:
	PUSH ECX
	PUSH EDI
	PUSH EAX
	
	CLD
	;Movendo DX:DX para EAX.
	MOV AX,DX
	SHL EAX,16
	MOV AX,DX

	;Carregando informações de vídeo.
	MOV EDI,DWORD[video.buffer]
	MOV ECX,DWORD[video.resolution]
	
	;Usando registradores de 32bits no lugar de 16bits "Dividindo por 2".
	SHR ECX,1
	REP STOSD ;Escrevendo cor na memória de vídeo.

	POP EAX
	POP EDI
	POP ECX
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para passar conteúdo do buffer de vídeo para a memória de vídeo.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
video_Reset_16:
	PUSH ECX
	PUSH EDI
	PUSH ESI
	
	CLD
	MOV EDI,DWORD[video.memoryPtr]
	MOV ESI,DWORD[video.buffer]
	MOV ECX,DWORD[video.resolution]

	SHR ECX,1             
	REP MOVSD ;Movendo dados do buffer de vídeo para memória de vídeo.
	
	POP ESI
	POP EDI
	POP ECX
	RET

;--------------------------------------------------------------------------------------------
;@description: Procedimento projetado para enviar um mapa de bits de 16bpp para o buffer de vídeo.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
video_DrawBitmap_16:
	PUSH ECX
	PUSH EDI
	PUSH ESI

	;Configurando a base do processo
	ADD ESI,DWORD[SS:BCP_PTR + bcp.base]
	
	CLD
	
	;Movendo um buffer de pixels para o buffer de vídeo
	MOV EDI,DWORD[video.buffer]
	MOV ECX,DWORD[video.resolution]
	SHR ECX,1
	REP MOVSD 
	
	;Movendo o buffer de video para memória de vídeo
	CALL video_Reset_16

	POP ESI
	POP EDI
	POP ECX
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para pintar uma área da tela contida no buffer de vídeo.
;@input: CX << X, DX << Y, BP << W, SI << H
;@output: -
;@author: alisson_linhares@hotmail.com
video_ClearArea_16:
	PUSHAD
	
	;Calculando o ponteiro para o vídeo.
	CALL video_CalcXY_16
		
	;Calculando o total de bytes para uma nova linha.
	MOVZX EDX,WORD[video.width]    
	SUB DX,BP
	SHL EDX,1
	MOV AX,SI
	
	;Calculando o ponteiro para o buffer
	MOV ESI,EDI
	SUB ESI,DWORD[video.memoryPtr]
	ADD ESI,DWORD[video.buffer]
	XOR ECX,ECX

	CLD
	SHR BP,1 ;Verifica se o tamanho da tela é par ou ímpar
	JNC .paintB
		.repeatUntilA:
			;Movendo dados do buffer para a memória de vídeo
			MOV CX,BP
			REP MOVSD
			MOVSW
			
			;Pulando linha
			ADD ESI,EDX
			ADD EDI,EDX
			DEC AX
		JNZ .repeatUntilA
		JMP .exitPaintA
	.paintB:
		.repeatUntilB:
			;Movendo dados do buffer para a memória de vídeo
			MOV CX,BP
			REP MOVSD
			
			;Pulando linha
			ADD ESI,EDX
			ADD EDI,EDX
			DEC AX
		JNZ .repeatUntilB 
	.exitPaintA:
	
	POPAD
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para mover um mapa de 16bits para a memória de vídeo.
;@input: CX << X, DX << Y, BP << W, SI << H, EDI << buffer
;@output: -
;@author: alisson_linhares@hotmail.com
video_PaintArea_16:
	PUSHAD
	
	MOV AX,SI   ;Movendo a altura para AX
	MOV ESI,EDI ;Movendo o buffer para ESI
	
	;Calculando o ponteiro para o vídeo.
	CALL video_CalcXY_16
	
	;Calculando o total de bytes para uma nova linha.
	MOVZX EBX,WORD[video.width]    
	SUB BX,BP
	SHL EBX,1
	
	CLD
	XOR ECX,ECX

	SHR BP,1 ;Verifica se o numero é par ou ímpar
	JNC .plot16_B
		.repeatUntilA:
			;Movendo dados para a memória de vídeo.
			MOV CX,BP          
			REP MOVSD
			MOVSW
			
			;Pulando a linha
			ADD EDI,EBX
			DEC AX
		JNZ .repeatUntilA 
		JMP .exitPlot16A
	.plot16_B:
		.repeatUntilB:
			;Movendo dados para a memória de vídeo.
			MOV CX,BP     
			REP MOVSD
			
			;Pulando a linha
			ADD EDI,EBX
			DEC AX
		JNZ .repeatUntilB
	.exitPlot16A:

	POPAD
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para copiar um mapa de 16bits da memória de vídeo.
;@input: CX << X, DX << Y, BP << W, SI << H, EDI << buffer
;@output: -
;@author: alisson_linhares@hotmail.com
video_CopyArea_16:
	PUSHAD
	
	;Calculando o ponteiro para o vídeo.
	CALL video_CalcXY_16
	
	;Calculando o total de bytes para uma nova linha.
	MOVZX EBX,WORD[video.width]    
	SUB BX,BP
	SHL EBX,1

	MOV AX,SI ;Movendo a altura para AX
	MOV ESI,EDI
	MOV EDI,DWORD[ESP + STACK_EDI]
	
	CLD
	XOR ECX,ECX

	SHR BP,1 ;Verifica se o numero é par ou ímpar
	JNC .plot16_B
		.repeatUntilA:
			;Copiando dados
			MOV CX,BP          
			REP MOVSD          
			MOVSW
			
			;Pulando a linha
			ADD ESI,EBX
			DEC AX
		JNZ .repeatUntilA 
		JMP .exitPlot16A
	.plot16_B:
		.repeatUntilB:
			;Copiando dados
			MOV CX,BP      
			REP MOVSD
			
			;Pulando a linha
			ADD ESI,EBX
			DEC AX
		JNZ .repeatUntilB
	.exitPlot16A:

	POPAD
	RET
	
;--------------------------------------------------------------------------------------------	
;@description: Procedimento para desenhar um retângulo no vídeo.
;@input: DX << y, CX << X, SI << H, BP << W, BX << cor
;@output: -
;@author: alisson_linhares@hotmail.com
video_DrawRectangle_16:
	PUSHAD
	
	;Calculando o ponteiro para o vídeo.
	CALL video_CalcXY_16
	
	;Largura do video em bytes.
	MOV EDX,DWORD[video.bpl]

	CLD
	MOV AX,BX
	MOVZX ECX,BP    
	REP STOSW

	SUB EDI,2
	MOV CX,SI
	.drawY_H:
		MOV WORD[EDI],BX ;Movendo a cor para a memória de vídeo.
		ADD EDI,EDX ;Pulando uma linha.
		DEC CX
	JNZ .drawY_H
	
	STD
	SUB EDI,EDX ;Pulando uma linha.
	MOV CX,BP
	REP STOSW ;Movendo a cor para a memória de vídeo.
	
	ADD EDI,2
	MOV CX,SI
	.drawY_H2:
		MOV WORD[EDI],BX ;Movendo a cor para a memória de vídeo.
		SUB EDI,EDX ;Pulando uma linha.
		DEC CX
	JNZ .drawY_H2

	POPAD
	RET
 
;--------------------------------------------------------------------------------------------	
;@description: Procedimento para pintar uma área da tela com uma cor.
;@input: DX << y, CX << X, SI << H, BP << W, BX << cor
;@output: -
;@author: alisson_linhares@hotmail.com
video_PaintRectangle_16:
	PUSHAD
	
	;Calculando o ponteiro para o vídeo.
	CALL video_CalcXY_16
	
	MOVZX EDX,WORD[video.width]    
	SUB DX,BP ;Retirando a largura do vídeo
	SHL EDX,1 ;VESA 16bits

	CLD
	XOR ECX,ECX
	
	MOV AX,BX
	SHL EAX,16
	MOV AX,BX
	
	SHR BP,1
	JNC .paintB
		.repeatUntilA:
			MOV CX,BP ;Passando o valor da largura
			REP STOSD ;Setando cor de fundo
			STOSW
			
			ADD EDI,EDX ;Próxima linha
			DEC SI
		JNZ .repeatUntilA
		JMP .exitPaintA
	.paintB:
		.repeatUntilB:
			MOV CX,BP ;Passando o valor da largura
			REP STOSD ;Setando cor de fundo
			
			ADD EDI,EDX ;Próxima linha
			DEC SI
		JNZ .repeatUntilB 
	.exitPaintA:
	
	POPAD
	RET
		
;--------------------------------------------------------------------------------------------	
;@description: Procedimento para pintar desenhos com fundo usando um array de bytes. Neutrino Image Format - NIF¹
;@remarks: 01 - pula um pixel, 10 - pinta um pixel, 11 - pula uma linha, 00 - fim da IMG [Sempre presente]
;@input: CX << X, DX << Y, BX << COR1, BP << COR2 
;@output: -
;@author: alisson_linhares@hotmail.com
video_DrawNIF_16:
	PUSHAD
	
	;Calculando o ponteiro para o vídeo.
	CALL video_CalcXY_16
	MOV EDX,EDI
	
	CLD
	.nifLoop:
		;Move 32bits de ESI para EAX e ESI += 4
		LODSD
		MOV ECX,16
		
		.nextFlag:
			;Verificando o tipo do bit
			TEST EAX,10000000000000000000000000000000b
			JNZ .paintPixel 
			TEST EAX,01000000000000000000000000000000b
			JZ .done ;Se for 00 terminou a nif
			
			.setColor2: ;Pula um pixel
				MOV WORD[EDI],BP  ;Pinta o pixel com a cor2
				JMP .nextPixel
			.paintPixel: ;Pinta um pixel
				TEST EAX,01000000000000000000000000000000b
				JZ .setColor1 ;11 - Pula a linha
					SUB EDX,EDI
					ADD EDI,EDX ;Retirando o incremento
					ADD EDI,DWORD[video.bpl]
					MOV EDX,EDI
					JMP .continue
				.setColor1:
				
				MOV WORD[EDI],BX
			.nextPixel:
				ADD EDI,2
			.continue:
			
			SHL EAX,2 ;Move 2 bits para esquerda
		DEC ECX
		JNZ .nextFlag
	JMP .nifLoop
	.done:
	
	POPAD
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para pintar desenhos sem fundo usando um array de bytes. Neutrino Image Format - NIF¹
;@remarks: 01 - pula um pixel, 10 - pinta um pixel, 11 - pula uma linha, 00 - fim da IMG [Sempre presente]
;@input: CX << X, DX << Y, BX << COR1
;@output: -
;@author: alisson_linhares@hotmail.com
video_DrawNIF2_16:
	PUSHAD
	
	;Calculando o ponteiro para o vídeo.s
	CALL video_CalcXY_16

	MOV EDX,EDI
	MOV EBP,DWORD[video.bpl]

	CLD
	.nifLoop:
		;Move 32bits de ESI para EAX e ESI += 4
		LODSD
		MOV ECX,16
		.nextFlag:
			TEST EAX,10000000000000000000000000000000b
			JNZ .paintPixel ;Pinta um pixel
			TEST EAX,01000000000000000000000000000000b
			JNZ .nextPixel  ;Pula um pixel
			JMP .done       ;Se for 00 terminou a nif
			
			.paintPixel:
				TEST EAX,01000000000000000000000000000000b
				JZ .setColor ;11 - Pula a linha
					;Pulando uma linha
					SUB EDX,EDI
					ADD EDI,EDX
					ADD EDI,EBP
					MOV EDX,EDI
					JMP .continue
				.setColor:
			
				;Pinta o pixel com a cor passada em BX
				MOV WORD[EDI],BX
			.nextPixel:
				ADD EDI,2
			.continue:
			
			SHL EAX,2 ;Move 2 bits para esquerda
			DEC ECX
		JNZ .nextFlag
	JMP .nifLoop
	.done:
	
	POPAD
	RET
	
;--------------------------------------------------------------------------------------------
;[1] NIF - Neutrino Image Format: It is an image format designed by Alisson Linhares de Carvalho for the neutrino kernel.
;NIF - Neutrino Image Format Copyright (C) 2011 Alisson Linhares de Carvalho. All rights reserved.