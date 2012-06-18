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
KEYBOARD_BUFFER_SIZE   EQU 12
KEY_ESC                EQU 1
KEY_BACK_SPACE         EQU 14
KEY_TAB                EQU 15
KEY_ENTER              EQU 28
KEY_SHIFT_R            EQU 54
KEY_SHIFT_L            EQU 42
KEY_ALT                EQU 56
KEY_SPACE              EQU 57
KEY_F1                 EQU 59
KEY_F2                 EQU 60
KEY_F3                 EQU 61
KEY_F4                 EQU 62
KEY_F5                 EQU 63
KEY_F6                 EQU 64
KEY_F7                 EQU 65
KEY_F8                 EQU 66
KEY_F9                 EQU 67
KEY_F10                EQU 68 
KEY_F11                EQU 23639
KEY_F12                EQU 88
KEY_CAPS               EQU 58
KEY_NUM_LOCK           EQU 69
KEY_SCROLL_LOCK        EQU 70
KEY_NULL               EQU 0
KEY_HOME               EQU 14151 
KEY_INSERT             EQU 12370
KEY_DELETE             EQU 11347
KEY_PAUSE_BREAK        EQU 29
KEY_CTRL               EQU 29
KEY_PRTSC              EQU 0
KEY_ALTGR              EQU 56
KEY_PAGE_UP            EQU 14665
KEY_PAGE_DOWN          EQU 13137
KEY_END                EQU 12623 
KEY_UP                 EQU 14408
KEY_LEFT               EQU 13387
KEY_RIGHT              EQU 13901
KEY_DOWN               EQU 12880
KEY_WINDOW             EQU 91
KEY_WINDOW2            EQU 93

KEYBOARD_KEY_LIST_SIZE EQU 88
NEW_LINE               EQU 10
KEYBOARD_BUFFER        EQU isr0x30_size ;O buffer de teclado fica depois dos ponteiros para isr0x30
KEYBOARD_SIGNATURE     EQU 0x89ABCDEF

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para registros---------------------------------
;@description: Modelo do registro usado para troca de informações entre a nlib e o kernel.
struc tKeyboardInfo 
	.signature     RESD 1
	.keyPressed    RESW 1 
	.keyReleased   RESW 1
	.bufferSize    RESB 1
endstruc

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para variáveis--------------------------------- 
keyboard:
.currentList         DD SHIFT_DISABLED  
.beginBuffer         DD KEYBOARD_BUFFER
.endBuffer           DD KEYBOARD_BUFFER
.bufferSize          DB 0
.keyPressed          DW KEY_NULL
.keyReleased         DW KEY_NULL

;--------------------------------------------------------------------------------------------	
;@description: Macro que insere uma telca no buffer do teclado. 
;@remarks: Não possui controle de concorrência.
;@input: DX << KEY
;@output: AX >> Lixo, BX >> Lixo
;@author: alisson_linhares@hotmail.com
%macro keyBoard_BufferInsert 0
	;Verifica se o buffer está cheio
	CMP BYTE[keyboard.bufferSize],KEYBOARD_BUFFER_SIZE  
	JAE %%abort
		;Inserindo tecla no buffer
		MOV EBX,DWORD[keyboard.endBuffer]
		MOV WORD[EBX],DX
		
		;Verifica se o buffer deve reiniciar
		CMP DWORD[keyboard.endBuffer],KEYBOARD_BUFFER + (KEYBOARD_BUFFER_SIZE - 1) * 2
		JB %%nextPosition
			MOV DWORD[keyboard.endBuffer],KEYBOARD_BUFFER
			JMP %%continue
		%%nextPosition:		
			ADD DWORD[keyboard.endBuffer],2
		%%continue:	
		
		;Incremento o total de elementos do buffer
 	    INC BYTE[keyboard.bufferSize]
    %%abort:
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro que remove uma telca do buffer do teclado.
;@remarks: Não possui controle de concorrência.
;@input: -
;@output: DX >> KEY, AX >> Lixo, BX >> Lixo
;@author: alisson_linhares@hotmail.com
%macro keyBoard_BufferRemove 0
	;Verifica se o buffer está vazio
	CMP BYTE[keyboard.bufferSize],0 
	JE %%abort
		;Retornando a tecla em DX
		MOV EBX,DWORD[keyboard.beginBuffer]	
		MOV DX,WORD[EBX] 
		
		;Verifica se o buffer deve reiniciar
		CMP DWORD[keyboard.beginBuffer],KEYBOARD_BUFFER + (KEYBOARD_BUFFER_SIZE - 1) * 2
		JB %%nextPosition
			MOV DWORD[keyboard.beginBuffer],KEYBOARD_BUFFER
			JMP %%continue
		%%nextPosition:	
			ADD DWORD[keyboard.beginBuffer],2
		%%continue:
		
		;Decremento o número de elementos
		DEC BYTE[keyboard.bufferSize]
	%%abort:
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Procedimento que verifica se o código passado por AL é válido e retorna em DH o caracter ascii  
;@input: EAX << código da tecla
;@output: DL >> código da tecla, DH >> ascii da tecla [Em caso de teclas fora da lista ou de comando, DH retorna 0]
;@author: alisson_linhares@hotmail.com
keyboard_GetASCIICode:
	AND EAX,11111111b
	MOV EDX,EAX

	;Verifica se foi ativado uma tecla fora da lista	
	CMP AL,KEYBOARD_KEY_LIST_SIZE
	JA .discardKey 
		;Carregando o ascii da tecla
		ADD EAX,DWORD[keyboard.currentList]
		MOV DH,BYTE[DS:EAX]
	.discardKey:
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento projetado para retornar informações do teclado.
;@input: EDI << tKeyboardInfo
;@output: EDI >> tKeyboardInfo
;@author: alisson_linhares@hotmail.com
keyboard_GetInfo:
	CMP DWORD[SS:EDI + tKeyboardInfo.signature],KEYBOARD_SIGNATURE
	JNE .abort
		PUSH EAX
		
		;Copiando a última tecla pressionada e a última tecla liberada para o buffer de retorno. 
		MOV EAX,DWORD[keyboard.keyPressed]
		MOV DWORD[SS:EDI + tKeyboardInfo.keyPressed],EAX
		
		;Copiando o total de letras existentes no buffer.
		MOV AL,BYTE[keyboard.bufferSize]
		MOV BYTE[SS:EDI + tKeyboardInfo.bufferSize],AL

		POP EAX
	.abort:
	RET


;--------------------------------------------------------------------------------------------	
;@description: Tratador de eventos para o teclado. ISR instalada na int 21h do sistema
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
keyboard_IrqHandler:
	PUSHAD
	
	;Lendo código da tecla
	IN AL,060h
	
	;Verifica se os eventos estão habilitados
	CMP BYTE[CS:system.irqsEnabled],0
	JA .abort

		;Termina em caso de teclas especiais
		CMP AL,224 
		JAE .abort
		
		;Usando segmento de dados do kernel
		PUSH DS		
		MOV DX,KERNEL_DATA
		MOV DS,DX
		MOV ES,DX 
		
		;Verifica o tipo de evento (KeyUp ou KeyDown)
		CMP AL,128
		JA .keyUp
			CALL keyboard_GetASCIICode

			;Salvando o código da tecla.
			MOV WORD[keyboard.keyPressed],DX 

			;Verifica se foi pressionado alguma tecla de sistema
			CMP DX,KEY_SHIFT_L
			JE .shiftEnabled
			CMP DX,KEY_SHIFT_R
			JE .shiftEnabled
			CMP DX,KEY_ALTGR
			JE .altgrEnabled
			
			;Tratando o evento de teclado
			.otherKey:
				keyBoard_BufferInsert
				JMP .onKeyDown
			.altgrEnabled:
				MOV DWORD[keyboard.currentList],ALTGR_ENABLED
				JMP .onKeyDown
			.shiftEnabled:
				MOV DWORD[keyboard.currentList],SHIFT_ENABLED
			.onKeyDown:
			
			;Executando o tratador de eventos do sistema.
			event_OnKeyDown
			JMP .done
		.keyUp:
			;Pegando os 128 bits para keyUp "128 bits para KEY_UP e 128 bits para KEY_DOWN"
			SUB AL,128                  
			CALL keyboard_GetASCIICode
			
			;Salvando o código da tecla.
			MOV WORD[keyboard.keyReleased],DX 

			;Verifica se foi pressionado alguma tecla de sistema
			CMP DX,KEY_SHIFT_L
			JE .shiftDisabled
			CMP DX,KEY_SHIFT_R
			JE .shiftDisabled
			CMP DX,KEY_ALTGR
			JNE .onKeyUp
			.shiftDisabled:
				MOV DWORD[keyboard.currentList],SHIFT_DISABLED
			.onKeyUp:

			;Executando o tratador de eventos do sistema.
			event_OnKeyUp 
		.done:	

		;Retornando para o segmento de dados anterior
		MOV ES,WORD[ESP]
		POP DS
	.abort:
	
	;Notificando o fim da interrupção
	MOV AL,020h
	OUT 020h,AL
	POPAD
	IRET	

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para ler uma tecla do buffer do teclado [Modo texto / Monotarefa] 
;@input: -
;@output: DL >> código da tecla, DH >> ascii
;@author: alisson_linhares@hotmail.com
keyboard_ReadKey:  
	PUSH EBX
	
	.waitLoop:
		;Verifica se existe algum elemento na lista
		CMP BYTE[keyboard.bufferSize],0
		JNE .exitLoop 
		
		system_Sleep 
	JMP .waitLoop
	.exitLoop:
	
	;Removendo tecla do buffer
	keyBoard_BufferRemove
	
	POP EBX
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para ler uma tecla do buffer do teclado.
;@input: -
;@output: DX >> KEY
;@author: alisson_linhares@hotmail.com
keyboard_GuiReadKey:  
	PUSH EBX
	PUSH EAX
	
	.waitLoop:
		;Verifica se existe algum elemento na lista
		CMP BYTE[keyboard.bufferSize],0
		JE .wait 
			MOV EAX,DWORD[FS:BCP_PTR + bcp.base]
			MOV EBX,DWORD[panel.focus]

			;Verifica se o painel em foco pertence ao processo atual
			CMP DWORD[EBX + tPanel.base],EAX                    
			JE .exitLoop
		.wait:

		system_Sleep 
	JMP .waitLoop
	.exitLoop:
	
	;Removendo tecla do buffer
	keyBoard_BufferRemove
	
	POP EAX
	POP EBX
	RET
	
;--------------------------------------------------------------------------------------------	
;@description: Procedimento para ler strings no modo texto.
;@input: EDI << buffer de leitura, ECX << tamanho do buffer.
;@output: EBX >> total de caracteres lidos.
;@author: alisson_linhares@hotmail.com
keyboard_ReadString:
	DEC ECX ;Reservando um espaço para o marcador de fim de linha
	JS .abort
		PUSH DX
		
		XOR EBX,EBX
		JMP .startLoop
		.readLoop:			
			CMP BYTE[keyboard.bufferSize],0
			JNE .skipDraw  
				CALL prompt_Update
			.skipDraw:
			
			CALL DWORD[isr0x30.keyboard_ReadKey]
			CMP DX,KEY_ENTER      
			JE .done   
			
			CMP DX,KEY_BACK_SPACE
			JNE .backSpace
			TEST EBX,EBX
			JZ .readLoop
				DEC EBX
				MOV DL,8
				JMP .continue	
			.backSpace:        
				MOV BYTE[FS:EDI + EBX],DH
				INC EBX 
				MOV DL,DH
			.continue:
			
			CALL DWORD[isr0x30.prompt_PrintChar] 

			;Termina se for igual ao tamanho do buffer.
		.startLoop:
			CMP EBX,ECX
			JB .readLoop
		.done:
		
		;Marcando o final da string.
		MOV BYTE[FS:EDI + EBX],0
		POP DX
	.abort:
	
	INC ECX ;Recuperando o valor original de ECX
	RET

;--------------------------------------------------------------------------------------------
;--------------------------------------Teclado ABNT------------------------------------------
SHIFT_ENABLED EQU $ - 1
SHIFT_E1    DB KEY_NULL
SHIFT_E2    DB '!'
SHIFT_E3    DB '@'
SHIFT_E4    DB '#'
SHIFT_E5    DB '$'
SHIFT_E6    DB '%'
SHIFT_E7    DB '¨'
SHIFT_E8    DB '&'
SHIFT_E9    DB '#'
SHIFT_E10   DB '('
SHIFT_E11   DB ')'
SHIFT_E12   DB '_'
SHIFT_E13   DB '+'
SHIFT_E14   DB KEY_NULL   
SHIFT_E15   DB KEY_NULL
SHIFT_E16   DB 'Q'
SHIFT_E17   DB 'W'
SHIFT_E18   DB 'E'
SHIFT_E19   DB 'R'
SHIFT_E20   DB 'T'
SHIFT_E21   DB 'Y'
SHIFT_E22   DB 'U'
SHIFT_E23   DB 'I'
SHIFT_E24   DB 'O'
SHIFT_E25   DB 'P'
SHIFT_E26   DB '`'
SHIFT_E27   DB '{'
SHIFT_E28   DB 0 ;Enter
SHIFT_E29   DB KEY_NULL
SHIFT_E30   DB 'A'
SHIFT_E31   DB 'S'
SHIFT_E32   DB 'D'
SHIFT_E33   DB 'F'
SHIFT_E34   DB 'G'
SHIFT_E35   DB 'H'
SHIFT_E36   DB 'J'
SHIFT_E37   DB 'K'
SHIFT_E38   DB 'L'
SHIFT_E39   DB 128    ;'Ç'
SHIFT_E40   DB '^'
SHIFT_E41   DB '"'
SHIFT_E42   DB KEY_NULL
SHIFT_E43   DB '}'
SHIFT_E44   DB 'Z'
SHIFT_E45   DB 'X'
SHIFT_E46   DB 'C'
SHIFT_E47   DB 'V'
SHIFT_E48   DB 'B'
SHIFT_E49   DB 'N'
SHIFT_E50   DB 'M'
SHIFT_E51   DB '<'
SHIFT_E52   DB '>'
SHIFT_E53   DB ':'
SHIFT_E54   DB KEY_NULL
SHIFT_E55   DB KEY_NULL
SHIFT_E56   DB KEY_NULL
SHIFT_E57   DB 20h
SHIFT_E58   DB KEY_NULL
SHIFT_E59   DB KEY_NULL 
SHIFT_E60   DB KEY_NULL
SHIFT_E61   DB KEY_NULL
SHIFT_E62   DB KEY_NULL
SHIFT_E63   DB KEY_NULL 
SHIFT_E64   DB KEY_NULL
SHIFT_E65   DB KEY_NULL
SHIFT_E66   DB KEY_NULL
SHIFT_E67   DB KEY_NULL
SHIFT_E68   DB KEY_NULL
SHIFT_E69   DB KEY_NULL	 
SHIFT_E70   DB KEY_NULL
SHIFT_E71   DB KEY_NULL
SHIFT_E72   DB KEY_NULL
SHIFT_E73   DB KEY_NULL 
SHIFT_E74   DB KEY_NULL 
SHIFT_E75   DB KEY_NULL
SHIFT_E76   DB KEY_NULL
SHIFT_E77   DB KEY_NULL
SHIFT_E78   DB KEY_NULL
SHIFT_E79   DB KEY_NULL 
SHIFT_E80   DB KEY_NULL 
SHIFT_E81   DB KEY_NULL 
SHIFT_E82   DB KEY_NULL 
SHIFT_E83   DB KEY_NULL 
SHIFT_E84   DB KEY_NULL      
SHIFT_E85   DB KEY_NULL
SHIFT_E86   DB KEY_NULL  
SHIFT_E87   DB KEY_NULL	 
SHIFT_E88   DB KEY_NULL       

ALTGR_ENABLED EQU $ - 1 
ALTGR_1     DB KEY_NULL                                 
ALTGR_2     DB 251       ;'¹' 
ALTGR_3     DB 253       ;'²'
ALTGR_4     DB 252       ;'³'
ALTGR_5     DB '£'  
ALTGR_6     DB 189       ;'¢'
ALTGR_7     DB '¬' 
ALTGR_8     DB KEY_NULL
ALTGR_9     DB KEY_NULL
ALTGR_10    DB KEY_NULL
ALTGR_11    DB KEY_NULL
ALTGR_12    DB KEY_NULL
ALTGR_13    DB '§'
ALTGR_14    DB KEY_NULL
ALTGR_15    DB KEY_NULL
ALTGR_16    DB KEY_NULL
ALTGR_17    DB KEY_NULL  
ALTGR_18    DB KEY_NULL
ALTGR_19    DB KEY_NULL
ALTGR_20    DB KEY_NULL
ALTGR_21    DB KEY_NULL
ALTGR_22    DB KEY_NULL
ALTGR_23    DB KEY_NULL
ALTGR_24    DB KEY_NULL
ALTGR_25    DB KEY_NULL
ALTGR_26    DB KEY_NULL
ALTGR_27    DB 'ª'  
ALTGR_28    DB 0          ;Enter              
ALTGR_29    DB KEY_NULL                    
ALTGR_30    DB KEY_NULL
ALTGR_31    DB KEY_NULL
ALTGR_32    DB KEY_NULL
ALTGR_33    DB KEY_NULL
ALTGR_34    DB KEY_NULL
ALTGR_35    DB KEY_NULL
ALTGR_36    DB KEY_NULL
ALTGR_37    DB KEY_NULL
ALTGR_38    DB KEY_NULL
ALTGR_39    DB KEY_NULL
ALTGR_40    DB KEY_NULL
ALTGR_41    DB KEY_NULL
ALTGR_42    DB KEY_NULL
ALTGR_43    DB 'º'   
ALTGR_44    DB KEY_NULL
ALTGR_45    DB KEY_NULL
ALTGR_46    DB KEY_NULL
ALTGR_47    DB KEY_NULL
ALTGR_48    DB KEY_NULL
ALTGR_49    DB KEY_NULL
ALTGR_50    DB KEY_NULL
ALTGR_51    DB KEY_NULL
ALTGR_52    DB KEY_NULL
ALTGR_53    DB KEY_NULL
ALTGR_54    DB KEY_NULL 
ALTGR_55    DB KEY_NULL
ALTGR_56    DB KEY_NULL
ALTGR_57    DB 20h 
ALTGR_58    DB KEY_NULL
ALTGR_59    DB KEY_NULL 
ALTGR_60    DB KEY_NULL
ALTGR_61    DB KEY_NULL 
ALTGR_62    DB KEY_NULL
ALTGR_63    DB KEY_NULL
ALTGR_64    DB KEY_NULL
ALTGR_65    DB KEY_NULL
ALTGR_66    DB KEY_NULL
ALTGR_67    DB KEY_NULL
ALTGR_68    DB KEY_NULL
ALTGR_69    DB KEY_NULL
ALTGR_70    DB KEY_NULL
ALTGR_71    DB KEY_NULL
ALTGR_72    DB KEY_NULL
ALTGR_73    DB KEY_NULL 
ALTGR_74    DB KEY_NULL 
ALTGR_75    DB KEY_NULL 
ALTGR_76    DB KEY_NULL
ALTGR_77    DB KEY_NULL
ALTGR_78    DB KEY_NULL
ALTGR_79    DB KEY_NULL
ALTGR_80    DB KEY_NULL 
ALTGR_81    DB KEY_NULL 
ALTGR_82    DB KEY_NULL
ALTGR_83    DB KEY_NULL 
ALTGR_84    DB KEY_NULL      
ALTGR_85    DB KEY_NULL
ALTGR_86    DB KEY_NULL  
ALTGR_87    DB KEY_NULL
ALTGR_88    DB KEY_NULL

SHIFT_DISABLED EQU $ - 1
SHIFT_D1    DB KEY_NULL                                
SHIFT_D2    DB '1'                      
SHIFT_D3    DB '2'                     
SHIFT_D4    DB '3'                     
SHIFT_D5    DB '4'                       
SHIFT_D6    DB '5'                     
SHIFT_D7    DB '6'                      
SHIFT_D8    DB '7'                     
SHIFT_D9    DB '8'                     
SHIFT_D10   DB '9'                     
SHIFT_D11   DB '0'                     
SHIFT_D12   DB '-'                     
SHIFT_D13   DB '='                     
SHIFT_D14   DB KEY_NULL              
SHIFT_D15   DB KEY_NULL                     
SHIFT_D16   DB 'q'                      
SHIFT_D17   DB 'w'                       
SHIFT_D18   DB 'e'                      
SHIFT_D19   DB 'r'                     
SHIFT_D20   DB 't'                     
SHIFT_D21   DB 'y'                     
SHIFT_D22   DB 'u'                     
SHIFT_D23   DB 'i'                     
SHIFT_D24   DB 'o'                     
SHIFT_D25   DB 'p'                     
SHIFT_D26   DB '´'                     
SHIFT_D27   DB '['                       
SHIFT_D28   DB 0      ;Enter                 
SHIFT_D29   DB KEY_NULL                     
SHIFT_D30   DB 'a'                     
SHIFT_D31   DB 's'                     
SHIFT_D32   DB 'd'                     
SHIFT_D33   DB 'f'                     
SHIFT_D34   DB 'g'                     
SHIFT_D35   DB 'h'                     
SHIFT_D36   DB 'j'                     
SHIFT_D37   DB 'k'                     
SHIFT_D38   DB 'l'                     
SHIFT_D39   DB 135    ;'ç'                     
SHIFT_D40   DB '~'                     
SHIFT_D41   DB 027h                    
SHIFT_D42   DB KEY_NULL                   
SHIFT_D43   DB ']'                        
SHIFT_D44   DB 'z'                     
SHIFT_D45   DB 'x'                     
SHIFT_D46   DB 'c'                     
SHIFT_D47   DB 'v'                     
SHIFT_D48   DB 'b'                     
SHIFT_D49   DB 'n'                     
SHIFT_D50   DB 'm'                     
SHIFT_D51   DB ','                     
SHIFT_D52   DB '.'                     
SHIFT_D53   DB ';'                     
SHIFT_D54   DB KEY_NULL                    
SHIFT_D55   DB '#'                     
SHIFT_D56   DB KEY_NULL                     
SHIFT_D57   DB 20h                   
SHIFT_D58   DB KEY_NULL                    
SHIFT_D59   DB KEY_NULL	                      
SHIFT_D60   DB KEY_NULL                      
SHIFT_D61   DB KEY_NULL                       
SHIFT_D62   DB KEY_NULL                      
SHIFT_D63   DB KEY_NULL                      
SHIFT_D64   DB KEY_NULL                      
SHIFT_D65   DB KEY_NULL                      
SHIFT_D66   DB KEY_NULL                      
SHIFT_D67   DB KEY_NULL                      
SHIFT_D68   DB KEY_NULL                     
SHIFT_D69   DB KEY_NULL
SHIFT_D70   DB KEY_NULL             
SHIFT_D71   DB '7'                     
SHIFT_D72   DB '8'                     
SHIFT_D73   DB '9'                      
SHIFT_D74   DB '-'                      
SHIFT_D75   DB '4'                      
SHIFT_D76   DB '5'                     
SHIFT_D77   DB '6'                     
SHIFT_D78   DB '+'                      
SHIFT_D79   DB '1'                      
SHIFT_D80   DB '2'                      
SHIFT_D81   DB '3'	                  
SHIFT_D82   DB '0'                      
SHIFT_D83   DB ','                      
SHIFT_D84   DB KEY_NULL                            
SHIFT_D85   DB KEY_NULL                       
SHIFT_D86   DB '\\'                      
SHIFT_D87   DB KEY_NULL                      		 
SHIFT_D88   DB KEY_NULL 