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
MOUSE_BUFFER_SIZE            EQU MOUSE_HEIGHT * MOUSE_WIDTH * 3
MOUSE_MAX_COUNT              EQU 3
MOUSE_ACK                    EQU 0FAh

;Comandos básicos usados na configuração do mouse
MOUSE_SET_RESOLUTION         EQU 0E8h
MOUSE_SET_SAMPLE_RATE        EQU 0F3h
MOUSE_ENABLE_DATA_REPORTING  EQU 0F4h
MOUSE_DISABLE_DATA_REPORTING EQU 0F5h 
MOUSE_RESET                  EQU 0FFh
MOUSE_SIGNATURE              EQU 0x89ABCDEF

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para registros---------------------------------
;@description: Modelo do registro usado para troca de informações entre a nlib e o kernel.
struc tMouseInfo 
	.signature   RESD 1
	.enabled     RESB 1
	.drag        RESB 1
	.lbtnState   RESB 1
	.mbtnState   RESB 1
	.rbtnState   RESB 1
	.mouseY      RESW 1
	.mouseX      RESW 1
endstruc

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para variáveis--------------------------------- 
mouse:
.enabled     DB 1
.drag        DB 0
.lbtnState   DB 0
.mbtnState   DB 0
.rbtnState   DB 0
.y           DW 100
.x           DW 100
.height      DW MOUSE_HEIGHT
.width       DW MOUSE_WIDTH
.buffer      DD 0 ;Reservado para o buffer do mouse

mousePacket:
.count       DB MOUSE_MAX_COUNT
.y           DB 0
.x           DB 0
.state       DB 0 ;Yoverflow, Xoverflow,Y sign bit, X sign bit, Always 1, Middle Btn, Right Btn, Left Btn 

;--------------------------------------------------------------------------------------------	
;@description: Macro que atualiza o desenho do mouse na tela quando ele se move.
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro mouse_Move 0
	;Verifica se o mouse está ativo
	CMP BYTE[mouse.enabled],0
	JE %%continue
		;Carregando informações do mouse
		MOV CX,WORD[mouse.x]
		MOV DX,WORD[mouse.y]
		MOV BP,MOUSE_WIDTH
		MOV SI,MOUSE_HEIGHT
		MOV EDI,DWORD[mouse.buffer]
		
		;Limpa a área do mouse.
		CALL DWORD[isr0x30.video_PaintArea]
	
		;Atualizando posição do mouse
		CALL mouse_UpdatePosition

		;Copiando a nova área ocupada pelo mouse para o buffer
		MOV CX,WORD[mouse.x]
		MOV DX,WORD[mouse.y]
		CALL DWORD[isr0x30.video_CopyArea]

		;Desenhado o mouse na tela
		XOR EBX,EBX
		MOV EBP,0FFFFFFFFh
		MOV ESI,DWORD[gui.mousePtr]
		CALL DWORD[isr0x30.video_DrawNIF]
	%%continue:	
%endmacro

;--------------------------------------------------------------------------------------------
;@description: Macro para escrever comando na porta 60h.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
%macro mouse_Write 1               
	;Toda escrita na porta 60h deve ser precedida de espera.
	CALL system_WritePort60
	MOV AL,0D4h
	OUT 064h,AL

	;Preparando para escrever comando na porta 60h
	CALL system_WritePort60
	MOV AL,%1
	OUT 060h,AL	
%endmacro 

;--------------------------------------------------------------------------------------------
;@description: Macro para configurar configurar o mouse PS2.
;@remarks: Mouse USB também é suportado porém, o mesmo trabalha de forma emulada.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
%macro mouse_Install 0
	;Verifica se o sistema está em modo texto.
	CMP BYTE[system.mode],GRAPHICS_MODE    
	JNE %%skip
		;Preparando para setar o Controller Command Byte
		CALL system_WritePort60
		MOV AL,060h
		OUT 064h,AL     

		;Enviando o Controller Command Byte para a controladora de teclado. 
		CALL system_WritePort60
		MOV AL,01000011b ;Ativar o keyboard e IRQ 1, Ativar o mouse e IRQ 12 e Usar XLAT   
		OUT 060h,AL

		;Programando a controladora para enviar 20 amostras por segundo
		mouse_Write MOUSE_SET_SAMPLE_RATE
		mouse_Write 20

		;Setando a resolução para 1 count/mm
		mouse_Write MOUSE_SET_RESOLUTION
		mouse_Write 0
		
		;Ativando o envio de pacotes
		mouse_Write MOUSE_ENABLE_DATA_REPORTING	
	%%skip:	
%endmacro

;--------------------------------------------------------------------------------------------
;@description: Tratador de interrupção para mouse. É instalado na interrupção 0Ch.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
mouse_IrqHandler:
	PUSHAD
	PUSH DS
	MOV AX,KERNEL_DATA
	MOV DS,AX
	MOV ES,AX 
	
	IN AL,060h

	;Montando o mouse packet
	XOR EBX,EBX
	MOV BL,BYTE[mousePacket.count]
	MOV BYTE[mousePacket  + EBX],AL
		
	;Verifica se terminou o pacote
	DEC BYTE[mousePacket.count]
	JNZ .abort
	
		;Resetando o contador
		MOV BYTE[mousePacket.count],MOUSE_MAX_COUNT
		
		;Verifica se os eventos podem ocorrer e se o primeiro pacote é válido
		CMP BYTE[system.irqsEnabled],0       
		JA .abort
		TEST BYTE[mousePacket.state],00001000b
		JZ .abort
		TEST BYTE[mousePacket.state],11000000b ;Em caso de overflow no eixo X ou Y o pacote é descartado
		JNZ .abort

			;Verifica o estado do botão esquerdo do mouse
			TEST BYTE[mousePacket.state],1
			JZ .mouseLBUp
				CMP BYTE[mouse.lbtnState],0
				JA .mouseLBDown
					INC BYTE[mouse.lbtnState]
					event_OnMouseLeft
					JMP .mouseLBDown
			.mouseLBUp:
				CMP BYTE[mouse.lbtnState],0
				JE .mouseLBDown
					DEC BYTE[mouse.lbtnState]
					event_OnMouseUpLeft
					
					CMP BYTE[mouse.drag],0
					JE .mouseDrop
						DEC BYTE[mouse.drag]
						event_OnMouseDrop
					.mouseDrop:	
			.mouseLBDown:
			
			;Verifica o estado do botão direito do mouse
			TEST BYTE[mousePacket.state],2
			JZ .mouseRBUp
				CMP BYTE[mouse.rbtnState],0
				JA .mouseRBDown
					INC BYTE[mouse.rbtnState]
					event_OnMouseRight
					JMP .mouseRBDown         
			.mouseRBUp:
				CMP BYTE[mouse.rbtnState],0
				JE .mouseRBDown
					DEC BYTE[mouse.rbtnState]
					event_OnMouseUpRight
			.mouseRBDown:

			;Verifica o estado do botão do meio do mouse	
			TEST BYTE[mousePacket.state],4              
			JZ .mouseMBUp
				CMP BYTE[mouse.mbtnState],0
				JA .mouseMBDown
					INC BYTE[mouse.mbtnState]	
					event_OnMouseMiddle
					JMP .mouseMBDown
			.mouseMBUp:
				CMP BYTE[mouse.mbtnState],0
				JE .mouseMBDown
					DEC BYTE[mouse.mbtnState]
					event_OnMouseUpMiddle
			.mouseMBDown:
			
			;Verifica se o evento de mouse move deve ser tratado
			CMP BYTE[mousePacket.x],0
			JNE .onMouseMove
			CMP BYTE[mousePacket.y],0
			JE .done
			.onMouseMove:
				mouse_Move
				event_OnMouseMove

				CMP BYTE[mouse.lbtnState],0
				JE .mouseDrag
					MOV BYTE[mouse.drag],1 
					gui_OnMouseDrag
				.mouseDrag:
			.done:
	.abort:
	
	MOV ES,WORD[ESP]
	POP DS

	;Informando o fim da interrupção
	MOV AL,020h
	OUT 0A0h,AL
	OUT 020h,AL
	
	POPAD
	IRET
	
;--------------------------------------------------------------------------------------------
;@description: Procedimento para atualizar a posição do mouse.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
mouse_UpdatePosition:
	PUSH AX
	
	MOVSX AX,BYTE[mousePacket.x]	
	ADD WORD[mouse.x],AX 
		
	;Verifica se a nova posição x está fora dos limites da tela
	CMP WORD[mouse.x],0                 
	JLE .minX
		MOV AX,WORD[video.width]
		SUB AX,WORD[mouse.width]
		
		;Verifica se a nova posição x está fora dos limites da tela
		CMP WORD[mouse.x],AX
		JL .xConfigured 
	.maxX:
		MOV WORD[mouse.x],AX
		JMP .xConfigured
	.minX:
		MOV WORD[mouse.x],0
	.xConfigured:
	
	
	;Carregando a posição y atual do mouse.
	MOVSX AX,BYTE[mousePacket.y]
	NEG AX
	ADD WORD[mouse.y],AX
	
	;Verifica se o mouse está se movendo para cima ou para baixo.	
	CMP WORD[mouse.y],0
	JLE .minY
		MOV AX,WORD[video.height]
		SUB AX,WORD[mouse.height]
		
		;Verifica se a nova posição y está fora dos limites da tela
		CMP WORD[mouse.y],AX
		JL .yConfigured
	.maxY:
		MOV WORD[mouse.y],AX
		JMP .yConfigured
	.minY:	
		MOV WORD[mouse.y],0
	.yConfigured:

	POP AX
	RET	

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para desenhar um mouse na tela.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
mouse_Draw:  
	PUSHAD
	
	;Carregando informações do mouse
	MOV CX,WORD[mouse.x]
	MOV DX,WORD[mouse.y]	
	MOV BP,MOUSE_WIDTH
	MOV SI,MOUSE_HEIGHT
	
	;Copiando a nova área ocupada pelo mouse para o buffer
	MOV EDI,DWORD[mouse.buffer]
	CALL DWORD[isr0x30.video_CopyArea]

	;Desenhado o mouse na tela
	XOR EBX,EBX
	MOV EBP,0FFFFFFFFh
	MOV ESI,DWORD[gui.mousePtr]
	CALL DWORD[isr0x30.video_DrawNIF]
		
	POPAD
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para apagar o mouse da tela.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
mouse_Clear:
	PUSHAD
	
	MOV CX,WORD[mouse.x]
	MOV DX,WORD[mouse.y]
	MOV BP,MOUSE_WIDTH
	MOV SI,MOUSE_HEIGHT
	MOV EDI,DWORD[mouse.buffer] ;Pintando o buffer do mouse
	CALL DWORD[isr0x30.video_PaintArea]	
	
	POPAD
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento projetado para retornar informações do mouse.
;@input: EDI << tMouseInfo
;@output: EDI >> tMouseInfo
;@author: alisson_linhares@hotmail.com
mouse_GetInfo:
	CMP DWORD[SS:EDI + tMouseInfo.signature],MOUSE_SIGNATURE
	JNE .abort
		PUSH EAX
		
		;Copiando a posição atual do mouse para o buffer de retorno.
		MOV EAX,DWORD[mouse.y]
		MOV DWORD[SS:EDI + tMouseInfo.mouseY],EAX
		
		;Copiando o estado atual do mouse ( enabled, drag, lbtnState, mbtnState, rbtnState ) para o buffer de retorno.
		MOV EAX,DWORD[mouse.enabled]
		MOV DWORD[SS:EDI + tMouseInfo.enabled],EAX

		MOV AL,BYTE[mouse.rbtnState]
		MOV BYTE[SS:EDI + tMouseInfo.rbtnState],AL

		POP EAX
	.abort:
	RET	