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
;-------------------------Importando macros, procedimentos e dados---------------------------
%include "KERNEL/GUI/COMPONENTS/PROMPT.ASM"
%include "KERNEL/GUI/COMPONENTS/BUTTON.ASM"
%include "KERNEL/GUI/COMPONENTS/NIFBUTTON.ASM"
%include "KERNEL/GUI/COMPONENTS/CLOSEBUTTON.ASM"
%include "KERNEL/GUI/COMPONENTS/MINBUTTON.ASM"
%include "KERNEL/GUI/COMPONENTS/MAXBUTTON.ASM"
%include "KERNEL/GUI/COMPONENTS/RESIZEBUTTON.ASM"
%include "KERNEL/GUI/COMPONENTS/LABEL.ASM"
%include "KERNEL/GUI/COMPONENTS/CANVAS.ASM"

;--------------------------------------------------------------------------------------------
;-----------------------------Área reservada para constantes---------------------------------
COMPONENT_CLOSE_BUTTON  EQU 0
COMPONENT_MAX_BUTTON    EQU 1
COMPONENT_MIN_BUTTON    EQU 2
COMPONENT_RESIZE_BUTTON EQU 3
COMPONENT_DRAG_BUTTON   EQU 4
COMPONENT_BUTTON        EQU 5
COMPONENT_NIF_BUTTON    EQU 6
COMPONENT_LABEL         EQU 7
COMPONENT_CANVAS        EQU 8
COMPONENT_PROMPT        EQU 9
COMPONENT_SIGNATURE     EQU 0x89ABCDEF

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para registros---------------------------------
struc tComponent
	.signature          RESD 1
	.next               RESD 1
	.prior              RESD 1
	
	.y                  RESW 1
	.x                  RESW 1
	.height             RESW 1
	.width              RESW 1
	.bgColor            RESD 1
	.textColor          RESD 1

	.event:             RES_TEVENTLISTENER .event.
	
	.type               RESB 1
endstruc

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para variáveis--------------------------------- 
component:
.current   DD 0
.list      DD closeButton_Draw, maxButton_Draw, minButton_Draw, resizeButton_Draw, button_Draw, button_Draw,
           DD nifButton_Draw, label_Draw, canvas_Draw,prompt_Draw

;--------------------------------------------------------------------------------------------	
;@description: Macro que verifica se o mouse está sobre algum componente.
;@input: EDI << PanelPtr
;@output: All
;@author: alisson_linhares@hotmail.com
%macro component_IsMouseUp 0
	CMP DWORD[EDI + tPanel.numberOfComp],0
	JE %%done
		;Salvando EDI em ESI e carregando o primeiro componente da lista em EDI
		MOV ESI,EDI
		MOV EDI,DWORD[ESI + tPanel.firstComp]

		%%while:
			;Colocando ponteiro na área de código do kernel
			ADD EDI,DWORD[ESI + tPanel.base]
			
			;Verificando se o mouse está sobre o componente no eixo X
			MOV AX,WORD[EDI + tComponent.x]   
			ADD AX,WORD[ESI + tPanel.x    ]
			CMP AX,WORD[mouse.x]    
			JG %%mouseOut 
			
			ADD AX,WORD[EDI + tComponent.width]   
			CMP AX,WORD[mouse.x]                
			JL %%mouseOut            
	
			;Verificando se o mouse está sobre o componente no eixo Y
			MOV AX,WORD[EDI + tComponent.y]
			ADD AX,WORD[ESI + tPanel.y    ]
			CMP AX,WORD[mouse.y]
			JG %%mouseOut  
			
			ADD AX,WORD[EDI + tComponent.height]
			CMP AX,WORD[mouse.y]
			JL %%mouseOut
				;Se o component já estiver setado como currente continua o programa.
				CMP DWORD[component.current],EDI
				JE %%done
					;Seta o componente como o atual da lista.
					MOV DWORD[component.current],EDI

					;Configurando o mouse over para o componente.
					component_MouseOver
					JMP %%done
			%%mouseOut:
				CMP DWORD[component.current],0
				JE %%continue
					component_MouseOut
					MOV DWORD[component.current],0
			%%continue:
			
			;Pega o próximo nó da lista
			MOV EDI,DWORD[EDI + tComponent.next]
		TEST EDI,EDI
		JNZ %%while
	%%done:
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro que é executada quando o mouse está sobre um componente.
;@input: ESI << painel, EDI << componente
;@output: All
;@author: alisson_linhares@hotmail.com
%macro component_MouseOver 0
	;Carregando base em EAX e agendando evento do onMouseOver
	MOV EAX,DWORD[ESI + tPanel.base]
	MOV EDX,DWORD[EDI + tComponent.event.onMouseOver]
	CALL event_CallProcessHandler

	;Verifica se o componente é o primeiro da lista
	CMP DWORD[EDI + tComponent.prior],0
	JE %%skipMove
		MOV EBX,DWORD[EDI + tComponent.next ]
		MOV EDX,DWORD[EDI + tComponent.prior]
		
		MOV DWORD[EDX + EAX + tComponent.next],EBX

		;Verificando se é o último componente da lista "EBX = 0"
		TEST EBX,EBX
		JZ %%configLastComponent
			MOV DWORD[EBX + EAX + tComponent.prior],EDX
			JMP %%continue
		%%configLastComponent:
			;Configura EDX como o último componente da lista
			MOV DWORD[ESI + tPanel.lastComp],EDX 
		%%continue:
		
		;Retirando a base usada na configuração do componente "EDI"
		MOV EDX,EDI
		SUB EDX,EAX
		
		;Configurando o novo registro
		MOV EBX,DWORD[ESI + tPanel.firstComp] 
		MOV DWORD[EBX + EAX + tComponent.prior],EDX
		MOV DWORD[EDI + tComponent.next],EBX
		MOV DWORD[EDI + tComponent.prior],0
		MOV DWORD[ESI + tPanel.firstComp],EDX
	%%skipMove:

	;Desativando e apagando o ponteiro do mouse
	MOV BYTE[mouse.enabled],0
	CALL mouse_Clear
	
	;Pintando o componente com a cor 1
	MOV AL,1
	CALL component_Draw
	
	;Repinta e reativa o mouse
	CALL mouse_Draw
	MOV BYTE[mouse.enabled],1
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro que é executada quando o mouse sai do componente.
;@input: ESI << painel, EDI << componente
;@output: All
;@author: alisson_linhares@hotmail.com
%macro component_MouseOut 0
	;Agendando evento para onMouseOut
	MOV EAX,DWORD[ESI + tPanel.base]
	MOV EDX,DWORD[EDI + tComponent.event.onMouseOut]
	CALL event_CallProcessHandler

	;Apagando o ponteiro do mouse
	MOV BYTE[mouse.enabled],0
	CALL mouse_Clear

	;Pintando o componente
	XOR AL,AL
	MOV EDI,DWORD[component.current]
	CALL component_Draw

	;Pinta novamente o mouse
	CALL mouse_Draw
	MOV BYTE[mouse.enabled],1
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro que é ativada quando é pressionado o botão direito do mouse sobre o componente.
;@input: ESI << painel
;@output: All
;@author: alisson_linhares@hotmail.com
%macro component_MouseLeft 0  
	MOV EDI,DWORD[component.current]
	
	;Verifica se o mouse está sobre algum componente
	TEST EDI,EDI
	JZ %%abort
		;Verifica se deve agendar uma chamada 
		CMP BYTE[EDI + tComponent.type],4   
		JA %%otherComponent
		CMP BYTE[EDI + tComponent.type],COMPONENT_MAX_BUTTON
		JE %%maxButton
		CMP BYTE[EDI + tComponent.type],COMPONENT_MIN_BUTTON
		JE %%minButton
		CMP BYTE[EDI + tComponent.type],COMPONENT_CLOSE_BUTTON
		JNE %%abort
		
		%%closeButton:
			CALL panel_OnClose
			JMP %%abort
		%%maxButton:
			CALL panel_OnMax
			JMP %%abort
		%%minButton:
			CALL panel_OnMin
			JMP %%abort
		%%otherComponent:
			MOV EDX,DWORD[EDI + tComponent.event.onMouseDownL]
			MOV EAX,DWORD[ESI + tPanel.base]
			CALL event_CallProcessHandler
	%%abort:
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para pintar todos os componentes.
;@input: EDI << Painel
;@output: -
;@author: alisson_linhares@hotmail.com
component_DrawAll: 
	CMP DWORD[EDI + tPanel.numberOfComp],0
	JE .abort
		PUSHAD
	
		;Configurando os registradores usados em component_Draw.
		MOV EBX,DWORD[EDI + tPanel.base     ]
		MOV ESI,EDI
		MOV EDI,DWORD[EDI + tPanel.firstComp]
		
		;Configurando o modo de pintura normal.
		XOR AX,AX
		
		.drawLoop:
			ADD EDI,EBX ;Colocando EDI na base do kernel.
			CALL component_Draw 
			MOV EDI,DWORD[EDI + tComponent.next]
		TEST EDI,EDI
		JNZ .drawLoop

		POPAD
	.abort:
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para desenhar um componente na tela.
;@input: ESI << Panel, EDI << Componente 
;@output: -
;@author: alisson_linhares@hotmail.com
component_Draw:
	.Y EQU 0 ;Posição dos elementos que serão passados na pilha.
	.X EQU 2
	.H EQU 4
	.W EQU 6
	.BASE EQU 8
	
	PUSHAD

	;Verifica se o componente pode ser desenhado.
	CMP WORD[EDI + tComponent.width],0
	JLE .abort
	CMP WORD[EDI + tComponent.height],0
	JLE .abort
		;Verifica se o componente está fora do painel no eixo X.
		MOV CX,WORD[EDI + tComponent.x]
		CMP CX,WORD[ESI + tPanel.width]
		JAE .abort
			;Verifica se o componente está fora do painel no eixo Y.
			MOV DX,WORD[EDI + tComponent.y]
			CMP DX,WORD[ESI + tPanel.height]
			JAE .abort
				;Verifica se o componente está fora dos limites do painel no eixo X.
				MOV BX,WORD[EDI + tComponent.width]
				ADD CX,BX
				SUB CX,WORD[ESI + tPanel.width]
				JS .skipWConfig ;Verifica se o sub retornou um valor negativo.
					INC CX
					SUB BX,CX ;Retirando o total de pixels que ficaram fora da tela.
					JLE .abort
				.skipWConfig:

				;Movendo a largura para esquerda.
				SHL EBX,16
				
				;Verifica se o componente está fora dos limites do painel no eixo X.
				MOV BX,WORD[EDI + tComponent.height]
				ADD DX,BX
				SUB DX,WORD[ESI + tPanel.height]
				JS .skipHConfig ;Verifica se o sub retornou um valor negativo.
					INC DX
					SUB BX,DX ;Retirando o total de pixels que ficaram fora da tela.
					JLE .abort
				.skipHConfig:

				;Alocando 12bytes na pilha(x,y,h,w,base).
				SUB ESP,12

				;Salvando a altura e a largura na pilha.
				MOV DWORD[ESP + .H],EBX

				;Salvando a posição XY do component na pilha.
				MOV EBX,DWORD[ESI + tPanel.y]
				ADD EBX,DWORD[EDI + tComponent.y]
				MOV DWORD[ESP + .Y],EBX

				;Salvando a base do processo na pilha.
				MOV EBX,DWORD[ESI + tPanel.base]
				MOV DWORD[ESP + .BASE],EBX
				
				XOR EBX,EBX
				MOV BL,BYTE[EDI + tComponent.type]
				CALL DWORD[DS:EBX * 4 + component.list]
	.abort:

	POPAD
	RET