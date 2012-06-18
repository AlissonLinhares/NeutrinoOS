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
PANEL_STATE_MAX        EQU 00000001b 
PANEL_STATE_MIN        EQU 00000010b 
PANEL_STATE_RES        EQU 00000100b 
PANEL_STATE_OPENED     EQU 00001000b 
PANEL_STATE_DRAG       EQU 00010000b

PANEL_MIN_WIDTH_SIZE   EQU 168
PANEL_MIN_HEIGHT_SIZE  EQU 18
PANEL_BUFFER_SIZE      EQU VIDEO_MAX_WIDTH * 6 + VIDEO_MAX_HEIGHT * 6
PANEL_SIGNATURE        EQU 089ABCDEFh

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para registros---------------------------------
;@description: Modelo do registro usado para troca de informações entre a nlib e o kernel.
struc tPanelInfo
	.signature         RESD 1
	.focusPanel        RESD 1
	.focusComponent    RESD 1
endstruc

;@description: Modelo do registro usado no gerenciamento de paineis pela nlib.
struc tPanel  
	.signature         RESD 1
	.next              RESD 1 
	.prior             RESD 1 
	
	.y                 RESW 1
	.x                 RESW 1
	.height            RESW 1
	.width             RESW 1
	.bgColor           RESD 1
	.textColor         RESD 1

	.event:            RES_TEVENTLISTENER .event.
	
	.firstComp         RESD 1
	.lastComp          RESD 1
	.numberOfComp      RESD 1
	.base              RESD 1
	.state             RESB 1
	.defaultY          RESW 1
	.defaultX          RESW 1
	.defaultH          RESW 1
	.defaultW          RESW 1
	.barPtr            RESD 1
endstruc

;@description: Formata de uma barra para paineis.
;@todo: Transformar a barra em um component.
struc tBar                       
	.closeButton       RESB tCloseButton_size
	.minButton         RESB tMinButton_size
	.dragButton        RESB tButton_size
	.maxButton         RESB tMaxButton_size
	.resizeButton      RESB tResizeButton_size
endstruc

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para variáveis--------------------------------- 
panelList:
.first                 DD 0
.last                  DD 0
.size                  DD 0

panel:
.semaphore             DD 0
.dragFlag              DB 0
.current               DD 0
.focus                 DD 0
.bufferPtr             DD 0 ;Reservado para o buffer do painel
.tempY                 DW 0
.tempX                 DW 0
.tempHeight            DW 0
.tempWidth             DW 0

;--------------------------------------------------------------------------------------------	
;@description: Macro que é executada quando uma tecla é pressionada "Evento do teclado".
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro panel_OnKeyDown 0
	MOV EDI,tComponent.event.onKeyDown
	CALL panel_CallEventListener
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro que é executada quando uma tecla é liberada "Evento do teclado".
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro panel_OnKeyUp 0
	MOV EDI,tComponent.event.onKeyUp
	CALL panel_CallEventListener
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro que é executada quando o mouse entra na área do painel.
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro panel_OnMouseOver 0
	MOV EDI,tComponent.event.onMouseOver
	CALL panel_CallEventListener
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro que é executada quando o mouse sai da área do painel.
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro panel_OnMouseOut 0
	MOV EDI,tComponent.event.onMouseOut
	CALL panel_CallEventListener
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro que é executada quando o botão esquerdo do mouse é pressionado.
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro panel_OnMouseLeft 0
	MOV EDI,DWORD[panel.current]
	TEST EDI,EDI
	JZ %%abort
		;Verifica se o painel está em foco.
		CALL panel_SetFocus

		;Chamando o evento de onMouseDownL do painel.
		MOV EDX,DWORD[EDI + tPanel.event.onMouseDownL]
		MOV EAX,DWORD[EDI + tPanel.base]
		CALL event_CallProcessHandler
		
		MOV ESI,EDI
		component_MouseLeft
	%%abort:
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro que é executada quando o botão direito do mouse é pressionado.
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro panel_OnMouseRight 0
	MOV EDI,tComponent.event.onMouseDownR
	CALL panel_CallEventListener
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro que é executada quando o botão do meio do mouse é pressionado.
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro panel_OnMouseMiddle 0
	MOV EDI,tComponent.event.onMouseDownM
	CALL panel_CallEventListener
%endmacro	

;--------------------------------------------------------------------------------------------	
;@description: Macro que é executada quando o botão esquerdo do mouse é liberado.
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro panel_OnMouseUpLeft 0
	MOV EDI,tComponent.event.onMouseUpL
	CALL panel_CallEventListener
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro que é executada quando o botão direito do mouse é liberado.
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro panel_OnMouseUpRight 0
	MOV EDI,tComponent.event.onMouseUpR
	CALL panel_CallEventListener
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro que é executada quando o botão do meio do mouse é liberado.
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro panel_OnMouseUpMiddle 0
	MOV EDI,tComponent.event.onMouseUpM
	CALL panel_CallEventListener
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro que verifica as configurações dos painéis quando o mouse é movimentado.
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro panel_OnMouseMove 0
	;Verifica se o mouse estiver arrastando alguma coisa ele pula a checagem.
	CMP BYTE[panel.dragFlag],1
	JE %%abort
	CMP DWORD[panelList.size],0
	JE %%abort
		MOV EDI,DWORD[panelList.first]
		
		%%mouseUpCheck:
			;Verificando se o mouse está sobre o painel no eixo X
			MOV AX,WORD[EDI + tPanel.x]        
			CMP AX,WORD[mouse.x]    
			JG %%mouseOut
			ADD AX,WORD[EDI + tPanel.width]   
			CMP AX,WORD[mouse.x]              
			JL %%mouseOut            
			
			;Verificando se o mouse está sobre o painel no eixo Y
			MOV AX,WORD[EDI + tPanel.y]
			CMP AX,WORD[mouse.y]                 
			JG %%mouseOut 
			ADD AX,WORD[EDI + tPanel.height]
			CMP AX,WORD[mouse.y]
			JL %%mouseOut
				;Verifica se o mouse está em foco
				CMP DWORD[panel.focus],EDI
				JNE %%done
					;Verifica qual componente está em foco
					component_IsMouseUp
					MOV EDI,DWORD[panel.focus]
					JMP %%done
			%%mouseOut:
			
			;Pega o próximo painel da lista
			MOV EDI,DWORD[EDI + tPanel.next]
		TEST EDI,EDI
		JNZ %%mouseUpCheck ;Termina se o ponteiro for nulo	
		%%done:
		
		;Setando o painel como o atual.
		MOV DWORD[panel.current],EDI
	%%abort:
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro que verifica as configurações dos painéis quando o mouse para de arrastar algum componente ou painel.
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro panel_OnMouseDrop 0
	MOV EBP,panel.semaphore
	CALL system_SemaphoreLock
	
	CMP BYTE[panel.dragFlag],0                          
	JE %%abort
	CMP DWORD[panel.focus],0
	JE %%abort	
		MOV BYTE[mouse.enabled],1
		MOV BYTE[panel.dragFlag],0
		MOV EDI,DWORD[panel.focus]
				
		;Configurando o estado do painel.
		TEST BYTE[EDI + tPanel.state],PANEL_STATE_RES
		JZ .resizePanel
			AND BYTE[EDI + tPanel.state],~PANEL_STATE_RES
			ADD EDI,tPanel.defaultY
			JMP .normalPanel 
		.resizePanel:
			;Configurando a posição y inicial.
			MOV AX,WORD[EDI + tPanel.y]
			SUB AX,WORD[panel.tempY]
			ADD WORD[mouse.y],AX	
		
			;Configurando a posição x inicial.
			MOV AX,WORD[EDI + tPanel.x]
			SUB AX,WORD[panel.tempX]
			ADD WORD[mouse.x],AX
		
			AND BYTE[EDI + tPanel.state],~PANEL_STATE_DRAG
			MOV EDI,panel.tempY
		.normalPanel:
				
		;Atualizando vídeo.
		MOV DX,WORD[EDI]
		MOV CX,WORD[EDI + 2]
		MOV SI,WORD[EDI + 4]
		MOV BP,WORD[EDI + 6]
		CALL DWORD[isr0x30.video_ClearArea]
		CALL panel_DrawAll
	%%abort:
	
	system_SemaphoreUnlock panel.semaphore
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro que verifica as configurações dos painéis quando o mouse para de arrastar algum componente ou painel.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
%macro panel_OnMouseDrag 0
	CMP DWORD[panel.current    ],0
	JE %%abort
	CMP DWORD[component.current],0
	JE %%abort
		MOV ESI,DWORD[panel.current]
		MOV EDI,DWORD[component.current]

		CMP BYTE[EDI + tComponent.type],4    
		JA %%abort
		CMP BYTE[EDI + tComponent.type],COMPONENT_RESIZE_BUTTON
		JE %%resizeButton
		CMP BYTE[EDI + tComponent.type],COMPONENT_DRAG_BUTTON
		JNE %%abort
		
		%%dragButton:
			CALL panel_OnDrag
			JMP %%abort
		%%resizeButton:
			CALL panel_OnResize
	%%abort:	
%endmacro	


;--------------------------------------------------------------------------------------------	
;@description: Procedimento para executar os eventos anexados aos components.
;@input: EDI << panel.event
;@output: ALL
;@author: alisson_linhares@hotmail.com
panel_CallEventListener:
	MOV ESI,DWORD[panel.current]
	CMP DWORD[panel.focus],ESI
	JNE .abort
		MOV EAX,DWORD[ESI + tPanel.base]
		MOV EDX,DWORD[ESI + EDI]
		CALL event_CallProcessHandler

		MOV ESI,DWORD[component.current]
		TEST ESI,ESI
		JZ .abort
			MOV EDX,DWORD[ESI + EDI]
			CALL event_CallProcessHandler
	.abort:
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento local para copiar o contorno de um painel.
;@input: EBX << panel
;@output: -
;@author: alisson_linhares@hotmail.com
panel_CopyToBuffer:
	PUSHAD
	;Copiando a linha de cima
	MOV EDI,DWORD[panel.bufferPtr]
	MOV CX,WORD[EBX + tPanel.x] 
	MOV DX,WORD[EBX + tPanel.y] 
	MOV BP,WORD[EBX + tPanel.width] 
	MOV SI,1
	CALL DWORD[isr0x30.video_CopyArea]

	;Copiando a linha de baixo
	ADD EDI,VIDEO_MAX_WIDTH * 3
	ADD DX,WORD[EBX + tPanel.height] 
	DEC DX
	CALL DWORD[isr0x30.video_CopyArea]
	
	;Copiando a coluna da esquerda
	ADD EDI,VIDEO_MAX_WIDTH * 3
	MOV DX,WORD[EBX + tPanel.y]
	MOV SI,WORD[EBX + tPanel.height]  
	MOV BP,1
	CALL DWORD[isr0x30.video_CopyArea]
	
	;Copiandoa coluna da direita
	ADD EDI,VIDEO_MAX_HEIGHT * 3
 	ADD CX,WORD[EBX + tPanel.width] 
	DEC CX
	CALL DWORD[isr0x30.video_CopyArea]
	
	POPAD
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento local para pintar o contorno de um painel.
;@input: EBX << panel
;@output: -
;@author: alisson_linhares@hotmail.com
panel_DrawBuffer:
	PUSHAD
	
	;Pintando a linha de cima
	MOV EDI,DWORD[panel.bufferPtr]
	MOV CX,WORD[EBX + tPanel.x] 
	MOV DX,WORD[EBX + tPanel.y] 
	MOV BP,WORD[EBX + tPanel.width] 
	MOV SI,1
	CALL DWORD[isr0x30.video_PaintArea]

	;Pintando a linha de baixo
	ADD EDI,VIDEO_MAX_WIDTH * 3	
	ADD DX,WORD[EBX + tPanel.height] 
	DEC DX
	CALL DWORD[isr0x30.video_PaintArea]
	
	;Pintando a coluna da esquerda
	ADD EDI,VIDEO_MAX_WIDTH * 3
	MOV DX,WORD[EBX + tPanel.y]
	MOV SI,WORD[EBX + tPanel.height]  
	MOV BP,1
	CALL DWORD[isr0x30.video_PaintArea]
	
	;Pintando a coluna da direita
	ADD EDI,VIDEO_MAX_HEIGHT * 3
 	ADD CX,WORD[EBX + tPanel.width] 
	DEC CX
	CALL DWORD[isr0x30.video_PaintArea]
	
	POPAD
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento local para remover um painel da lista de renderização.
;@input: EDI << Ponteiro para o painel
;@output: -
;@author: alisson_linhares@hotmail.com
panel_Delete:
	CMP DWORD[panelList.size],0        
	JE .abort
		PUSH ESI
		PUSH EDI
		
		MOV ESI,DWORD[EDI + tPanel.next ] ;Carregando ponteiro para o próximo
		MOV EDI,DWORD[EDI + tPanel.prior] ;Carregando ponteiro para o anterior
		
		;Verificando se é o primeiro painel "EDI = 0"
		TEST EDI,EDI                         
		JZ .configPrior
			MOV DWORD[EDI + tPanel.next],ESI
			JMP .priorConfigured
		.configPrior:
			MOV DWORD[panelList.first],ESI 
		.priorConfigured:
		
		;Verificando se é o último painel "ESI = 0"
		TEST ESI,ESI
		JZ .configNext
			MOV DWORD[ESI + tPanel.prior],EDI
			JMP .nextConfigured
		.configNext:
			MOV DWORD[panelList.last],EDI
		.nextConfigured:
		
		;Decrementa o total de elementos da lista
		DEC DWORD[panelList.size]  
		
		POP EDI
		POP ESI
	.abort:
	RET 	

;--------------------------------------------------------------------------------------------	
;@description: Procedimento local para inserir um painel na lista de renderização.
;@input: EDI << Ponteiro para o painel
;@output: -
;@author: alisson_linhares@hotmail.com
panel_Insert:
	;Verifica se a lista de renderização possui elementos.
	CMP DWORD[panelList.size],0
	JNE .insertPanel
		;Inserindo o primeiro painel na lista.
		MOV DWORD[panelList.first],EDI
		MOV DWORD[EDI + tPanel.prior],0
		JMP .done
	.insertPanel:
		;Inserindo componente no final da lista
		PUSH EBP
		MOV EBP,DWORD[panelList.last] 
		MOV DWORD[DS:EBP + tPanel.next],EDI
		MOV DWORD[EDI + tPanel.prior],EBP
		POP EBP
	.done:

	MOV DWORD[EDI + tPanel.next],0
	MOV DWORD[panelList.last],EDI
	INC DWORD[panelList.size]
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para iniciar um painel.
;@input: EDI << Ponteiro para o painel
;@output: -
;@author: alisson_linhares@hotmail.com
panel_Open:
	PUSH EBP
	
	;Travando o semáforo para painéis
	MOV EBP,panel.semaphore
	CALL system_SemaphoreLock 
		
	;Verifica se o painel é válido
	CMP DWORD[SS:EDI + tPanel.signature],PANEL_SIGNATURE
	JNE .abort
	CMP BYTE[SS:EDI + tPanel.state],0
	JA .abort
		;Verifica se o painel pode ser aberto.
		MOV EBP,DWORD[SS:BCP_PTR + bcp.base]
		ADD EDI,EBP
		
		;Setando a base do processo no painel e inserindo na lista de painéis
		MOV DWORD[EDI + tPanel.base ],EBP
		MOV BYTE [EDI + tPanel.state],PANEL_STATE_OPENED
		CALL panel_Insert
		
		;Restaurando o valor de EDI
		SUB EDI,EBP
	.abort:
	
	;Destravando o semáforo para painéis
	system_SemaphoreUnlock panel.semaphore
	POP EBP
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para removendo um painel da lista de renderização.
;@input: EDI << Ponteiro para o painel
;@output: -
;@author: alisson_linhares@hotmail.com
panel_Close:
	PUSHAD
	MOV EBP,panel.semaphore
	CALL system_SemaphoreLock 
	
	;Verifica a integridade do painel.
	CMP DWORD[SS:EDI + tPanel.signature],PANEL_SIGNATURE
	JNE .abort
	TEST BYTE[SS:EDI + tPanel.state    ],PANEL_STATE_OPENED
	JZ .abort
		;Limpa o estado do painel
		MOV BYTE[SS:EDI + tPanel.state],0 
		MOV BYTE[mouse.enabled],0
		CALL mouse_Clear   

		ADD EDI,DWORD[SS:BCP_PTR + bcp.base]
		CALL panel_Delete

		CMP DWORD[panel.current],EDI
		JNE .skipConfig
			MOV DWORD[panel.current    ],0
			MOV DWORD[panel.focus      ],0
			MOV DWORD[component.current],0
		.skipConfig:
			
		;Limpa a área ocupada pelo painel e repinta todos os painéis restantes
		MOV CX,WORD[EDI + tPanel.x]
		MOV DX,WORD[EDI + tPanel.y]
		MOV BP,WORD[EDI + tPanel.width ]
		MOV SI,WORD[EDI + tPanel.height]
		CALL DWORD[isr0x30.video_ClearArea]
		CALL panel_DrawAll

		MOV BYTE[mouse.enabled],1
	.abort:

	system_SemaphoreUnlock panel.semaphore
	POPAD
	RET
	
;--------------------------------------------------------------------------------------------	
;@description: Procedimento para inserir um componente em um painel.
;@input: EDI << ponteiro para painel, ESI << ponteiro para o componente
;@output: -
;@author: alisson_linhares@hotmail.com
panel_Add:
	;Verificando a integridade do component e do painel
	CMP DWORD[SS:EDI + tPanel.signature    ],PANEL_SIGNATURE
	JNE .abort
	CMP DWORD[SS:ESI + tComponent.signature],COMPONENT_SIGNATURE
	JNE .abort
		PUSH EBP
		
		;Travando o semáforo
		MOV EBP,panel.semaphore
		CALL system_SemaphoreLock
		
		;Inserindo elemento na lista de componentes
		CMP DWORD[SS:EDI + tPanel.numberOfComp],0
		JNE .insertFirstComp
			MOV DWORD[SS:EDI + tPanel.firstComp],ESI
			MOV DWORD[SS:ESI + tComponent.prior],0
			JMP .done
		.insertFirstComp:
			MOV EBP,DWORD[SS:EDI + tPanel.lastComp]
			MOV DWORD[EBP + tComponent.next ],ESI
			MOV DWORD[SS:ESI + tComponent.prior],EBP
		.done:
		
		MOV DWORD[SS:ESI + tComponent.next],0
		MOV DWORD[SS:EDI + tPanel.lastComp],ESI
		INC DWORD[SS:EDI + tPanel.numberOfComp]

		;Destravando o semáforo
		system_SemaphoreUnlock panel.semaphore
		POP EBP
	.abort:
	RET	

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para remover um componente de um painel.
;@input: EDI << ponteiro para painel, ESI << ponteiro para o componente
;@output: -
;@author: alisson_linhares@hotmail.com
panel_Remove:
	CMP DWORD[SS:EDI + tPanel.signature    ],PANEL_SIGNATURE
	JNE .abort ;Verificando a integridade do painel
	CMP DWORD[SS:EDI + tPanel.numberOfComp ],0
	JE  .abort ;Verificando se existe algum componente nesse painel
	CMP DWORD[SS:ESI + tComponent.signature],COMPONENT_SIGNATURE
	JNE .abort ;Verificando a integridade do component
		PUSH ESI
		PUSH EBP
		
		;Travando o semáforo
		MOV EBP,panel.semaphore
		CALL system_SemaphoreLock
		
		MOV EBP,DWORD[SS:ESI + tComponent.prior]
		MOV ESI,DWORD[SS:ESI + tComponent.next ]
				
		;Verificando se é o primeiro component "EBP = 0"
		TEST EBP,EBP                         
		JZ .configPrior	
			MOV DWORD[EBP + tComponent.next],ESI
			JMP .priorConfigured
		.configPrior:
			MOV DWORD[SS:EDI + tPanel.firstComp],ESI 
		.priorConfigured:
		
		;Verificando se é o último component "ESI = 0"
		TEST ESI,ESI
		JZ .configNext
			MOV DWORD[SS:ESI + tComponent.prior],EBP
			JMP .nextConfigured
		.configNext:
			MOV DWORD[SS:EDI + tPanel.lastComp],EBP
		.nextConfigured:
		
		;Decrementa o total de elementos da lista
		DEC DWORD[SS:EDI + tPanel.numberOfComp]
		
		;Destravando o semáforo
		system_SemaphoreUnlock panel.semaphore
	
		POP EBP
		POP ESI
	.abort:
	RET

;--------------------------------------------------------------------------------------------	
;@description: Evento para fechar um programa.
;@input: ESI << Painel
;@output: -
;@author: alisson_linhares@hotmail.com
panel_OnClose:
	;Liberando a interrupção do mouse.
	MOV AL,020h
	OUT 0A0h,AL
	OUT 020h,AL 
	
	MOV EDI,DWORD[ESI + tPanel.base]
	CALL scheduler_KillProcess
	RET

;--------------------------------------------------------------------------------------------	
;@description: Evento para minimizar um painel. 
;@input: EDI << Ponteiro para o painel
;@output: -
;@author: alisson_linhares@hotmail.com
panel_OnMin:
	MOV EDI,ESI

	;Apagando vídeo ocupado pelo painel
	MOV CX,WORD[EDI + tPanel.x]
	MOV DX,WORD[EDI + tPanel.y]
	MOV BP,WORD[EDI + tPanel.width]
	MOV SI,WORD[EDI + tPanel.height]
	CALL DWORD[isr0x30.video_ClearArea]
		
	TEST BYTE[EDI + tPanel.state],PANEL_STATE_MIN
	JNZ .exitMinScreen 
		;Configurando o estado da tela
		OR BYTE[EDI + tPanel.state],PANEL_STATE_MIN
		TEST BYTE[EDI + tPanel.state],PANEL_STATE_MAX
		JNZ .clearMaxFlag
			;Salvando o x, y, w e h do painel
			MOV EAX,DWORD[EDI + tPanel.y]
			MOV DWORD[EDI + tPanel.defaultY],EAX
			MOV EAX,DWORD[EDI + tPanel.height]
			MOV DWORD[EDI + tPanel.defaultH],EAX
		.clearMaxFlag:
		
		AND BYTE[EDI + tPanel.state],~PANEL_STATE_MAX
		
		MOV WORD[EDI + tPanel.height],PANEL_MIN_HEIGHT_SIZE
		MOV WORD[EDI + tPanel.width ],PANEL_MIN_WIDTH_SIZE	

		;Verifica se deve configurar uma barra
		CMP DWORD[EDI + tPanel.barPtr],0
		JE .enterNormalScreen
			MOV EAX,DWORD[EDI + tPanel.barPtr]
			ADD EAX,DWORD[EDI + tPanel.base  ]
			ADD WORD[EAX + tBar.maxButton  + tComponent.y    ],PANEL_MIN_HEIGHT_SIZE
			ADD WORD[EAX + tBar.resizeButton + tComponent.y  ],PANEL_MIN_HEIGHT_SIZE
			MOV WORD[EAX + tBar.dragButton + tComponent.x    ],30
			MOV WORD[EAX + tBar.dragButton + tComponent.width],PANEL_MIN_WIDTH_SIZE - 32
			MOV WORD[EAX + tBar.minButton  + tComponent.x    ],16
			JMP .enterNormalScreen
	.exitMinScreen:   
    	;Configurando o estado da tela
		AND BYTE[EDI + tPanel.state],~PANEL_STATE_MIN
		MOV EAX,DWORD[EDI + tPanel.defaultY] 
		MOV DWORD[EDI + tPanel.y],EAX               ;Restaurando o x e y do painel
		MOV EAX,DWORD[EDI + tPanel.defaultH]
		MOV DWORD[EDI + tPanel.height],EAX          ;Restaurando o w e h do painel
		
		;Configurando a barra
		CMP DWORD[EDI + tPanel.barPtr],0
		JE .skipConfig
			MOV EAX,DWORD[EDI + tPanel.barPtr]
			ADD EAX,DWORD[EDI + tPanel.base  ]
			
			;Setando as configurações padrões
			SUB WORD[EAX + tBar.maxButton  + tComponent.y  ],PANEL_MIN_HEIGHT_SIZE
			SUB WORD[EAX + tBar.resizeButton + tComponent.y],PANEL_MIN_HEIGHT_SIZE
			MOV WORD[EAX + tBar.dragButton + tComponent.x  ],44
			MOV WORD[EAX + tBar.minButton  + tComponent.x  ],30
			
			;Setando a largura do painel
			MOV BX,WORD[EDI + tPanel.width]
			MOV WORD[EAX + tBar.dragButton   + tComponent.width],BX	
			SUB WORD[EAX + tBar.dragButton   + tComponent.width],60
			MOV WORD[EAX + tBar.resizeButton + tComponent.x    ],BX
			SUB WORD[EAX + tBar.resizeButton + tComponent.x    ],15
		.skipConfig:
	.enterNormalScreen:

	CALL panel_DrawAll
	RET	

;--------------------------------------------------------------------------------------------	
;@description: Evento para maximizar um painel.
;@input: ESI << Ponteiro para o painel
;@output: -
;@author: alisson_linhares@hotmail.com
panel_OnMax:
	;Limpando a área do painel
	MOV EDI,ESI	
	MOV CX,WORD[EDI + tPanel.x]
	MOV DX,WORD[EDI + tPanel.y]
	MOV BP,WORD[EDI + tPanel.width ]
	MOV SI,WORD[EDI + tPanel.height]
	CALL DWORD[isr0x30.video_ClearArea]
		
	;Verifica se o painel deve maximizar
	TEST BYTE[EDI + tPanel.state],PANEL_STATE_MAX
	JNZ .exitMinScreen 	
		MOV EAX,DWORD[EDI + tPanel.y]                
		MOV DWORD[EDI + tPanel.defaultY],EAX        ;Salvando o x e y do painel
		MOV EAX,DWORD[EDI + tPanel.height] 
		MOV DWORD[EDI + tPanel.defaultH],EAX        ;Salvando o w e h do painel
		
		MOV DWORD[EDI + tPanel.y],0                 ;Painel vai para o (0,0)
		MOV EAX,DWORD[video.height]  
		MOV DWORD[EDI + tPanel.height],EAX          ;Setando a altura do painel 
    	JMP .enterNormalScreen
	.exitMinScreen:   
		MOV EAX,DWORD[EDI + tPanel.defaultY]        
		MOV DWORD[EDI + tPanel.y],EAX               ;Restaurando o x e y do painel
		MOV EAX,DWORD[EDI + tPanel.defaultH]
		MOV DWORD[EDI + tPanel.height],EAX          ;Restaurando o w e h do painel		
	.enterNormalScreen:

	;Verifica se a barra existe
	CMP DWORD[EDI + tPanel.barPtr],0
	JE .skipBarConfig		
		MOV EBX,DWORD[EDI + tPanel.barPtr]
		ADD	EBX,DWORD[EDI + tPanel.base  ]
		
		;Configurando o tamanho da barra
		MOV AX,WORD[EDI + tPanel.width]		
		MOV WORD[EBX + tBar.dragButton   + tComponent.width],AX	
		SUB WORD[EBX + tBar.dragButton   + tComponent.width],60
		MOV WORD[EBX + tBar.resizeButton + tComponent.x    ],AX
		SUB WORD[EBX + tBar.resizeButton + tComponent.x    ],15
	.skipBarConfig:	

	;Atualizando o estado do painel e a tela.
	TEST BYTE[EDI + tPanel.state],PANEL_STATE_MAX
	JNZ .minConfig 
		OR BYTE[EDI + tPanel.state],PANEL_STATE_MAX
		CALL panel_Print
		RET
	.minConfig:
	
	AND BYTE[EDI + tPanel.state],~PANEL_STATE_MAX
	CALL panel_DrawAll	
	RET	

;--------------------------------------------------------------------------------------------
;@description: Procedimento para atualizar a posição do painel.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
panel_UpdatePosition:
	PUSH AX
	
	MOVSX AX,BYTE[mousePacket.x]
	ADD WORD[EBX + tPanel.x],AX 
		
	;Verifica se a nova posição x está fora dos limites da tela
	CMP WORD[EBX + tPanel.x],0                 
	JLE .minX			
		MOV AX,WORD[video.width]
		SUB AX,WORD[EBX + tPanel.width]
		
		;Verifica se a nova posição x está fora dos limites da tela
		CMP WORD[EBX + tPanel.x],AX
		JL .xConfigured 
	.maxX:
		MOV WORD[EBX + tPanel.x],AX
		JMP .xConfigured
	.minX:
		MOV WORD[EBX + tPanel.x],0
	.xConfigured:
	
	MOVSX AX,BYTE[mousePacket.y]
	NEG AX
	ADD WORD[EBX + tPanel.y],AX
	
	;Verifica se o mouse está se movendo para cima ou para baixo.	
	CMP WORD[EBX + tPanel.y],0
	JLE .minY
		MOV AX,WORD[video.height]
		SUB AX,WORD[EBX + tPanel.height]
		
		;Verifica se a nova posição y está fora dos limites da tela
		CMP WORD[EBX + tPanel.y],AX
		JL .yConfigured
	.maxY:
		MOV WORD[EBX + tPanel.y],AX
		JMP .yConfigured
	.minY:	
		MOV WORD[EBX + tPanel.y],0
	.yConfigured:

	POP AX
	RET
	
;--------------------------------------------------------------------------------------------	
;@description: Evento para arrastar um painel.
;@input: ESI << Ponteiro para o painel
;@output: -
;@author: alisson_linhares@hotmail.com
panel_OnDrag:
	;Se a tela estiver maximizada ou o mouse não estiver com um evento de mouse drag aborta
	CMP BYTE[mouse.drag],0
	JE .abort
	TEST BYTE[ESI + tPanel.state],PANEL_STATE_MAX
	JNZ .abort 
		MOV EBX,ESI
	
		CMP BYTE[panel.dragFlag],0
		JE .dragIsEnable	
			;Pintando o conteúdo do buffer
			CALL panel_DrawBuffer
			JMP .continueDrag
		.dragIsEnable:
			MOV BYTE[panel.dragFlag],1
			
			;Apagando e desativando o mouse
			MOV BYTE[mouse.enabled],0
			CALL mouse_Clear
			
			;Salvando posição e tamanho inicial 
			MOV EAX,DWORD[EBX + tPanel.y]                  
			MOV DWORD[panel.tempY],EAX
			MOV EAX,DWORD[EBX + tPanel.height]
			MOV DWORD[panel.tempHeight],EAX
		.continueDrag:		
		
		;Atualizando a posição do painel.
		CALL panel_UpdatePosition
		
		;Copia para o buffer uma parte da tela
		CALL panel_CopyToBuffer
		
		;Pintando um contorno para mover a tela
		MOV CX,WORD[EBX + tPanel.x]                        
		MOV DX,WORD[EBX + tPanel.y]
		MOV SI,WORD[EBX + tPanel.height]
		MOV BP,WORD[EBX + tPanel.width]
		XOR EBX,EBX
		CALL DWORD[isr0x30.video_DrawRectangle]
	.abort:
	RET

;--------------------------------------------------------------------------------------------	
;@description: Evento para redimensionar um painel.
;@input: EDI << ponteiro para painel
;@output: -
;@author: alisson_linhares@hotmail.com
panel_OnResize:
	CMP BYTE[mouse.drag],0
	JE .abort
	TEST BYTE[ESI + tPanel.state],PANEL_STATE_MAX ;Verifica se a tela está maximizada
	JNZ .abort
		MOV EBX,ESI ;Passando para EBX o ponteiro para o painel
		MOV DX,WORD[EBX + tPanel.y]
		MOV CX,WORD[EBX + tPanel.x]
		MOV BP,WORD[EBX + tPanel.width ]
		MOV SI,WORD[EBX + tPanel.height] 
				
		CMP BYTE[panel.dragFlag],0
		JE .dragIsEnable
			CALL panel_DrawBuffer ;Pintando o conteúdo do buffer
			JMP .continueDrag
		.dragIsEnable:
			CALL mouse_Clear

			;Configurando o painel
			MOV WORD[EBX + tPanel.defaultY],DX
			MOV WORD[EBX + tPanel.defaultX],CX
			MOV WORD[EBX + tPanel.defaultH],SI
			MOV WORD[EBX + tPanel.defaultW],BP
			OR BYTE[EBX + tPanel.state],PANEL_STATE_RES ;Setando o bit de drag
			
			MOV BYTE[panel.dragFlag],1 ;Ativa o drag flag
			MOV BYTE[mouse.enabled],0 ;Desativando o mouse
		.continueDrag:
			
		MOV WORD[mouse.x     ],CX
		ADD WORD[mouse.x     ],BP 
		MOV WORD[mouse.y     ],DX
		ADD WORD[mouse.y     ],SI 
		MOV WORD[mouse.height],1
		MOV WORD[mouse.width ],1
		
		;Atualizando posição do mouse
		CALL mouse_UpdatePosition

		;Calculando o novo tamanho da tela no eixo x
		MOV BP,WORD[mouse.x]
		SUB BP,CX
		CMP BP,PANEL_MIN_WIDTH_SIZE ;Tamanho mínimo no eixo x
		JG .wSize
			MOV BP,PANEL_MIN_WIDTH_SIZE
		.wSize:

		;Calculando o novo tamanho da tela no eixo y
		MOV SI,WORD[mouse.y]
		SUB SI,DX
		CMP SI,PANEL_MIN_HEIGHT_SIZE ;Tamanho máximo no eixo x
		JG .hSize
			MOV SI,PANEL_MIN_HEIGHT_SIZE
		.hSize:

		SUB WORD[mouse.x],MOUSE_WIDTH
		SUB WORD[mouse.y],MOUSE_HEIGHT
		MOV WORD[mouse.height],MOUSE_HEIGHT
		MOV WORD[mouse.width ],MOUSE_WIDTH
		
		MOV WORD[EBX + tPanel.width ],BP
		MOV WORD[EBX + tPanel.height],SI 
		CALL panel_CopyToBuffer ;Copia para o buffer uma parte da tela
					
		CMP DWORD[EBX + tPanel.barPtr],0
		JE .skipConfigBar
			MOV EAX,DWORD[EBX + tPanel.barPtr] 
			ADD EAX,DWORD[EBX + tPanel.base  ] 
			
			MOV WORD[EAX + tBar.dragButton   + tComponent.width],BP
			SUB WORD[EAX + tBar.dragButton   + tComponent.width],60
			MOV WORD[EAX + tBar.resizeButton + tComponent.x    ],BP
			SUB WORD[EAX + tBar.resizeButton + tComponent.x    ],15
		.skipConfigBar:
		
		XOR EBX,EBX
		CALL DWORD[isr0x30.video_DrawRectangle]
	.abort:
	RET
	
;--------------------------------------------------------------------------------------------	
;@description: Procedimento para pintar um painel.
;@input: EDI << ponteiro para painel
;@output: -
;@author: alisson_linhares@hotmail.com
panel_Draw:
	;O painel não pode ficar em foco caso tenha alguma tela sendo arrastada
	CMP BYTE[panel.dragFlag],1
	JE .abort
	CMP DWORD[SS:EDI + tPanel.signature],PANEL_SIGNATURE
	JNE .abort ;Verifica se o painel é válido
	TEST BYTE[SS:EDI + tPanel.state],PANEL_STATE_OPENED
	JZ .abort  ;Verifica se o painel está aberto e se o mesmo existe
		ADD EDI,DWORD[SS:BCP_PTR + bcp.base] 
		
		;Verifica se a tela está em foco
		CMP DWORD[panel.focus],EDI
		JE .skipFocus
			CALL panel_SetFocus
			JMP .printPanel
		.skipFocus:
			CALL panel_Print 
		.printPanel:
		
		;Restaurando o valor de EDI
		SUB EDI,DWORD[SS:BCP_PTR + bcp.base]
	.abort:
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para pintar um component de um painel.
;@input: EDI << Component, ESI << Painel
;@output: -
;@author: alisson_linhares@hotmail.com
panel_DrawComponent:
	;Verifica se exist algum painel sendo arrastada
	CMP BYTE[panel.dragFlag],1
	JE .abort
	CMP DWORD[SS:ESI + tPanel.signature],PANEL_SIGNATURE
	JNE .abort ;Verifica se o painel é válido
	TEST BYTE[SS:ESI + tPanel.state],PANEL_STATE_OPENED
	JZ .abort
	CMP DWORD[SS:EDI + tComponent.signature],COMPONENT_SIGNATURE
	JNE .abort ;Verifica se o component é válido
		ADD ESI,DWORD[SS:BCP_PTR + bcp.base] 

		;Aborta se o painel atual não estiver em foco
		CMP DWORD[panel.focus],ESI
		JNE .skipDraw
			PUSH EAX
		
			;Pintando o componente
			XOR EAX,EAX
			ADD EDI,DWORD[SS:BCP_PTR + bcp.base]
			CALL component_Draw
			
			;Restaurando o valor de EDI
			SUB EDI,DWORD[SS:BCP_PTR + bcp.base] 
			POP EAX
		.skipDraw:
		
		;Restaurando o valor de ESI
		SUB ESI,DWORD[SS:BCP_PTR + bcp.base] 
	.abort:
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para pintar todas as telas.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
panel_DrawAll:
	CMP BYTE[panel.dragFlag],1
	JAE .abort
		PUSHAD
		MOV EBP,panel.semaphore
		CALL system_SemaphoreLock

		CMP DWORD[panelList.size],0
		JE .done
			;Apagando e desativando o mouse
			MOV BYTE[mouse.enabled],0
	;		CALL mouse_Clear
			
			MOV EDI,DWORD[panelList.last]
			
			.drawLoop:
				MOV CX,WORD[EDI + tPanel.x     ]
				MOV DX,WORD[EDI + tPanel.y     ]
				MOV SI,WORD[EDI + tPanel.height] 
				MOV BP,WORD[EDI + tPanel.width ]
				
				;Pintando a tela onde ficará os componentes
				MOV EBX,DWORD[EDI + tPanel.bgColor]
				CALL DWORD[isr0x30.video_PaintRectangle]
	
				;Pintando o contorno
				MOV EBX,DWORD[EDI + tPanel.textColor]
				CALL DWORD[isr0x30.video_DrawRectangle]
				
				;Pintando todos os componentes
				CALL component_DrawAll	
				
				;Carregando o elemento anterior.
				MOV EDI,DWORD[EDI + tPanel.prior]	
			TEST EDI,EDI
			JNZ .drawLoop	
			
			;Repintando e reativando o mouse
			CALL mouse_Draw	
			MOV BYTE[mouse.enabled],1
		.done:
		
		system_SemaphoreUnlock panel.semaphore
		POPAD
	.abort:	
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para pintar um painel.
;@input: EDI << Painel
;@output: -
;@author: alisson_linhares@hotmail.com
panel_Print:
	PUSHAD
	
	;Pintando o fundo do painel
	MOVZX ECX,WORD[EDI + tPanel.x  ]
	MOVZX EDX,WORD[EDI + tPanel.y  ]
	MOV SI,WORD[EDI + tPanel.height] 
	MOV BP,WORD[EDI + tPanel.width ]

	MOV EBX,DWORD[EDI + tPanel.bgColor]  
	CALL DWORD[isr0x30.video_PaintRectangle]
	
	;Pintando o contorno do painel
	MOV EBX,DWORD[EDI + tPanel.textColor]  
	CALL DWORD[isr0x30.video_DrawRectangle]

	;Pintando todos os componentes	
	CALL component_DrawAll

	;Verifica se o mouse está fora da área do painel
	CMP WORD[mouse.x],CX
	JB .skipDraw
		LEA ECX,[ECX + EBP - MOUSE_WIDTH]
		CMP WORD[mouse.x],CX
		JA .skipDraw
			CMP WORD[mouse.y],DX
			JB .skipDraw
				LEA EDX,[EDX + ESI - MOUSE_HEIGHT]
				CMP WORD[mouse.y],DX
				JA .skipDraw
					CALL mouse_Draw  ;Pinta o mouse na tela, se estiver sobre a área repintanda pelo painel
	.skipDraw:

	POPAD
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para colocar painel em foco
;@input: EDI << Painel
;@output: -
;@author: alisson_linhares@hotmail.com
panel_SetFocus:
	PUSHAD
	MOV EBP,panel.semaphore
	CALL system_SemaphoreLock 
	
	;Verifica se o painel requerido já está em foco
	CMP DWORD[panel.focus],EDI
	JE .done
		;Verifica se o elemento já está na frente da lista de rederização, caso contrário o processo é movido. 
		CMP DWORD[panelList.first],EDI
		JE .skipMoveToFront
			MOV ESI,DWORD[EDI + tPanel.next ]
			MOV EBP,DWORD[EDI + tPanel.prior]
			MOV DWORD[DS:EBP + tPanel.next],ESI
			
			;Verificando se é o último "ESI = 0" 
			TEST ESI,ESI
			JZ .configNextPanel
				MOV DWORD[ESI + tPanel.prior],EBP
				JMP .nextPanelConfigured
			.configNextPanel:
				;Seta como o último da lista
				MOV DWORD[panelList.last],EBP
			.nextPanelConfigured:
			
			;Insere o painel no início da lista
			MOV ESI,DWORD[panelList.first] 
			MOV DWORD[ESI + tPanel.prior],EDI
			MOV DWORD[EDI + tPanel.next ],ESI
			MOV DWORD[EDI + tPanel.prior],0
			MOV DWORD[panelList.first],EDI
		.skipMoveToFront:

		;Configurando dados do painel
		MOV DWORD[panel.focus      ],EDI 
		MOV DWORD[panel.current    ],EDI
		MOV DWORD[component.current],0
		CALL panel_Print

		;Executando o evento de onFocus do painel
		MOV EDX,DWORD[EDI + tPanel.event.onFocus]
		MOV EAX,DWORD[EDI + tPanel.base]
		CALL event_CallProcessHandler
	.done:
	
	system_SemaphoreUnlock panel.semaphore
	POPAD
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para desalocar painéis.
;@input: EDI << ponteiro para o BCP
;@output: -
;@author: alisson_linhares@hotmail.com
panel_Deallocate:
	PUSHAD

	MOV EBP,panel.semaphore
	CALL system_SemaphoreLock

	;Verifica se existe elementos na lista de painéis
	CMP DWORD[panelList.size],0
	JE .abort		
		MOV BYTE[mouse.enabled],0
		
		;Carregando a base do processo
		MOV EAX,DWORD[EDI + bcp.base]
		
		;Pegando o primeiro elemento da lista
		MOV EDI,DWORD[panelList.first]

		.destroyLoop:
			;Verifica se a tela pertence ao processo atual
			CMP DWORD[EDI + tPanel.base],EAX                
			JNE .nextPanel
				CALL panel_Delete
				
				MOV CX,WORD[EDI + tPanel.x]
				MOV DX,WORD[EDI + tPanel.y]
				MOV BP,WORD[EDI + tPanel.width ]
				MOV SI,WORD[EDI + tPanel.height]
				CALL DWORD[isr0x30.video_ClearArea]
				
				CMP DWORD[panel.current],EDI
				JNE .nextPanel
					MOV DWORD[panel.current    ],0 
					MOV DWORD[panel.focus      ],0
					MOV DWORD[component.current],0
			.nextPanel:
			
			;Carregando o próximo painel.
			MOV EDI,DWORD[EDI + tPanel.next]
		TEST EDI,EDI
		JNZ .destroyLoop
		
		;Atualiza o vídeo
		CALL panel_DrawAll
		MOV BYTE[mouse.enabled],1
	.abort:
	
	system_SemaphoreUnlock panel.semaphore
	POPAD
	RET
	
;--------------------------------------------------------------------------------------------	
;@description: Procedimento para setar uma nova base para os painéis.
;@input: EAX << Nova base
;@output: -
;@author: alisson_linhares@hotmail.com
panel_ResetBase:
	;Verifica se existe algum painel na lista de renderização
	CMP DWORD[panelList.size],0
	JZ .abort
		PUSH EDI
		PUSH EBP
		
		;Pegando o ponteiro para a base do processo
		MOV EBP,DWORD[SS:BCP_PTR + bcp.base]
		
		;Pegando o primeiro elemento da lista
		MOV EDI,DWORD[panelList.first]
		
		.resetLoop:
			;Procurando pela tela 
			CMP DWORD[EDI + tPanel.base],EBP
			JNE .nextPanel
				PUSH EDI
				
				;Resetando variáveis de gerente gráfico	
				CMP DWORD[panel.current],EDI
				JNE .resetPanelState
					MOV DWORD[panel.current    ],0
					MOV DWORD[panel.focus      ],0
					MOV DWORD[component.current],0
				.resetPanelState:

				;Removendo painel da lista	
				CALL panel_Delete
				
				;Reconfigurando base do painel
				SUB EDI,EBP
				ADD EDI,EAX			
				MOV DWORD[EDI + tPanel.base],EAX
				
				;Inserindo o painel reconfigurado na lista de renderização
				CALL panel_Insert
				
				POP EDI
			.nextPanel:
			
			;Movendo para EDI o próximo painel
			MOV EDI,DWORD[EDI + tPanel.next]
		TEST EDI,EDI
		JNZ .resetLoop

		POP EBP
		POP EDI
	.abort:
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento projetado para retornar informações do sistema gráfico.
;@input: EDI << tPanelInfo
;@output: EDI >> tPanelInfo
;@author: alisson_linhares@hotmail.com
panel_GetInfo:
	CMP DWORD[SS:EDI + tPanelInfo.signature],PANEL_SIGNATURE
	JNE .abort
		PUSH EAX
		PUSH EBX
		
		MOV EBX,DWORD[panel.focus]

		;Verifica se o painel atual é válido
		TEST EBX,EBX
		JZ .invalidPanel
			MOV EAX,DWORD[SS:BCP_PTR + bcp.base]
		
			;Verifica se o painel corrent pertence ao processo atual.
			CMP DWORD[EBX + tPanel.base],EAX
			JNE .invalidPanel
				;Salvando o painel no buffer de retorno.
				SUB EBX,EAX
				MOV DWORD[SS:EDI + tPanelInfo.focusPanel],EBX

				MOV EBX,DWORD[component.current]

				;Verifica se o component atual é válido.
				TEST EBX,EBX
				JZ .invalidComponent
					SUB EBX,EAX
					;Salvando o ponteiro para o component atual.
					MOV DWORD[SS:EDI + tPanelInfo.focusComponent],EBX
					JMP .done
		.invalidPanel:
			MOV DWORD[SS:EDI + tPanelInfo.focusPanel],0
		.invalidComponent:
			MOV DWORD[SS:EDI + tPanelInfo.focusComponent],0
		.done:
		
		POP EBX
		POP EAX
	.abort:
	RET