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

;description: Configurando texto branco com fundo preto.
DEBUG_BGCOLOR               EQU 00000000b ;4 bits de cor para o fundo
DEBUG_TEXTCOLOR             EQU 00001111b ;4 bits de cor para o texto
DEBUG_NUMBER_OF_BREAKPOINTS EQU 0

;description: Flags mais usadas em programas.
CARRY_FLAG                  EQU 1 << 0
PARITY_FLAG                 EQU 1 << 2
AUXILIARY_FLAG              EQU 1 << 4
ZERO_FLAG                   EQU 1 << 6
SIGN_FLAG                   EQU 1 << 7
TRAP_FLAG                   EQU 1 << 8 
INTERRUPT_FLAG              EQU 1 << 9
DIRECTION_FLAG              EQU 1 << 10
OVERFLOW_FLAG               EQU 1 << 11

;Esse arquivo será compilado se o sistema estiver em DEBUG_MODE
%if OPERATION_MODE == DEBUG_MODE
	debug:
	.textPos   DW 0
	.color     DB DEBUG_BGCOLOR + (DEBUG_TEXTCOLOR << 4)
	.header    DB "---------------------------------- SYS_INFO ------------------------------------",0
	.reg32Info DB " EDI [00000000000000000000000000000000b] [0000000000d] [0x00000000] [    ]"      ,NEW_LINE
	           DB " ESI [00000000000000000000000000000000b] [0000000000d] [0x00000000] [    ]"      ,NEW_LINE
	           DB " EBP [00000000000000000000000000000000b] [0000000000d] [0x00000000] [    ]"      ,NEW_LINE
	           DB " ESP [00000000000000000000000000000000b] [0000000000d] [0x00000000] [    ]"      ,NEW_LINE
		   DB " EBX [00000000000000000000000000000000b] [0000000000d] [0x00000000] [    ]"      ,NEW_LINE
		   DB " EDX [00000000000000000000000000000000b] [0000000000d] [0x00000000] [    ]"      ,NEW_LINE
		   DB " ECX [00000000000000000000000000000000b] [0000000000d] [0x00000000] [    ]"      ,NEW_LINE
		   DB " EAX [00000000000000000000000000000000b] [0000000000d] [0x00000000] [    ]"      ,NEW_LINE
		   DB "--------------------------------------------------------------------------------",0
	.reg16Info DB " DS [0000000000000000b][00000][0x0000] - ES [0000000000000000b][00000][0x0000]"  ,NEW_LINE
		   DB " SS [0000000000000000b][00000][0x0000] - FS [0000000000000000b][00000][0x0000]"  ,NEW_LINE
		   DB " GS [0000000000000000b][00000][0x0000] - CS [0000000000000000b][00000][0x0000]"  ,NEW_LINE
	           DB "--------------------------------------------------------------------------------",0
	.flagsInfo DB " FLAGS: [00000000000000000000000000000000b]  CF=0, PF=0, ZF=0, SF=0, DF=0, OF=0 ",
		   DB "--------------------------------------------------------------------------------",0
	.pauseMsg  DB NEW_LINE,">>>>>>>>>>>>>>>>> Pressione a tecla 'Enter' para continuar <<<<<<<<<<<<<<<<<<<<<",0
	
	;--------------------------------------------------------------------------------------------	
	;@description: Função para limpar a tela no modo debug.
	;@input: -
	;@output: -
	;@author: alisson_linhares@hotmail.com;
	debug_Clear:
		PUSH AX
		PUSH EBX
		
		;Carregando cor do texto
		MOV AH,BYTE[debug.color]
		XOR AL,AL
		
		;Limpando a tela no modo texto
		MOV EBX,TEXT_MODE_BUFFER	
		.clearLoop: 
			MOV WORD[EBX],AX   
			ADD EBX,2
		CMP EBX,TEXT_MODE_BUFFER + 80 * 25 * 2 ;Trabalhando com 80x25
		JB .clearLoop
		
		;Limpando a posição atual do buffer
		MOV WORD[debug.textPos],0        
		
		POP EBX
		POP AX
		RET

	;--------------------------------------------------------------------------------------------	
	;@description: Procedimento para imprimir um buffer no modo debug.
	;@input: EDI << buffer, ECX << size
	;@output: -
	;@author: alisson_linhares@hotmail.com
	debug_PrintBuffer:  
		PUSHAD
		
		JMP .startPrintLoop
		.printLoop:
			;Imprimindo letra contida no buffer
			CALL debug_Print
			INC EDI
		.startPrintLoop:
			MOV DL,BYTE[DS:EDI]
		DEC ECX
		JNZ .printLoop
		
		POPAD
		RET

	;--------------------------------------------------------------------------------------------	
	;@description: Procedimento para imprimir String no modo debug.
	;@input: EDI << stringPtr
	;@output: -
	;@author: alisson_linhares@hotmail.com
	debug_PrintString:  
		PUSHAD
		
		JMP .startPrintLoop
		.printLoop:
			;Imprimindo letra contida no buffer
			CALL debug_Print
			INC EDI
		.startPrintLoop:
			MOV DL,BYTE[DS:EDI]
		TEST DL,DL
		JNZ .printLoop
		
		POPAD
		RET

	;--------------------------------------------------------------------------------------------	
	;@description: Procedimento para imprimir um valor numérico no modo debug.
	;@input: EAX << valor, EBX << base, CL << Alinhamento
	;@output: -
	;@author: alisson_linhares@hotmail.com
	debug_PrintInterger:
		PUSHAD
		
		;Verifica se a base é válida
		CMP EBX,16
		JA .invalidBase 
		CMP EBX,1
		JBE .invalidBase 
			SHL CX,8 ;Movendo bit de alinhamento para CH e limpando CL
			
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
					CALL debug_Print
				DEC CH
				JNZ .printAlign
			.skipAlign:

			;Imprimindo valor contido na pilha
			.printNextChar:
				POP DX       
				CALL debug_Print
			DEC CL
			JNZ .printNextChar  
		.invalidBase:
		
		POPAD
		RET

	;--------------------------------------------------------------------------------------------	
	;@description: Procedimento para imprimir um valor numérico no modo debug.
	;@input: DL << valor
	;@output: -
	;@author: alisson_linhares@hotmail.com
	debug_Print:
		PUSHAD
		MOVZX EBX,WORD[debug.textPos];Carregando posição do cursor
		MOV DH,BYTE[debug.color]     ;Carregando cor do vídeo
		
		;Verifica se deve dar um scroll+
		CMP EBX,160 * 24
		JB .newCaracter
		
		.videoScroll:
			;Movendo 24 linhas para o início do vídeo.
			CLD
			MOV ESI,TEXT_MODE_BUFFER + 0A0h     
			MOV EDI,TEXT_MODE_BUFFER
			MOV ECX,960                   
			REP MOVSD

			;Resetando o contador.
			MOV EBX,0E60h
		.newCaracter:
			;Verificando os caracteres especiais.
			CMP DL,NEW_LINE
			JE .newLine
			CMP DL,08h           
			JE .back
			
			.setCaracter:
				;Setando Caracter.
				MOV WORD[EBX + TEXT_MODE_BUFFER],DX 
				ADD BX,2h
				JMP .done ;Termina o comando.
			.newLine:
				;Calculando a nova posição do cursor.
				MOV AX,BX
				XOR DX,DX
				
				MOV BX,0A0h 
				DIV BX ;Divide AX por 160.
				INC AX ;Incrementa a posição.  

				MUL BX ;Multiplica AX por 160.
				MOV BX,AX
				JMP .done
			.back:
				SUB BX,2h 
				XOR DL,DL
				MOV WORD[EBX + TEXT_MODE_BUFFER],DX
		.done:
		
		MOV WORD[debug.textPos],BX
		POPAD
		RET

	;--------------------------------------------------------------------------------------------	
	;@description: Procedimento para imprimir o estado das flags. Usado no debug_pause.
	;@input: EAX << flags
	;@output: -
	;@author: alisson_linhares@hotmail.com
	debug_DrawFlagsInfo:
		PUSHAD
		MOV BX,WORD[debug.textPos]	
		MOV EDI,debug.flagsInfo
		CALL debug_PrintString
		
		ADD BX,9 * 2
		MOV WORD[debug.textPos],BX

		MOV EBX,2
		MOV ECX,32
		CALL debug_PrintInterger
		
		MOV BX,WORD[debug.textPos]		
		TEST EAX,CARRY_FLAG
		JZ .carryFlag
			MOV BYTE[EBX + TEXT_MODE_BUFFER + 7 * 2],'1'
		.carryFlag:

		TEST EAX,PARITY_FLAG
		JZ .parityFlag
			MOV BYTE[EBX + TEXT_MODE_BUFFER + 13 * 2],'1'
		.parityFlag:
		
		TEST EAX,ZERO_FLAG
		JZ .zeroFlag
			MOV BYTE[EBX + TEXT_MODE_BUFFER + 19 * 2],'1'
		.zeroFlag:
		
		TEST EAX,SIGN_FLAG
		JZ .signFlag
			MOV BYTE[EBX + TEXT_MODE_BUFFER + 25 * 2],'1'
		.signFlag:	
		
		TEST EAX,DIRECTION_FLAG
		JZ .directionFlag
			MOV BYTE[EBX + TEXT_MODE_BUFFER + 31 * 2],'1'
		.directionFlag:
		
		TEST EAX,OVERFLOW_FLAG
		JZ .overflowFlag
			MOV BYTE[EBX + TEXT_MODE_BUFFER + 37 * 2],'1'
		.overflowFlag:
		POPAD
		RET

	;--------------------------------------------------------------------------------------------
	;@description: Procedimento para imprimir o estado das flags. Usado no debug_pause.
	;@input: EAX << flags
	;@output: -
	;@author: alisson_linhares@hotmail.com
	debug_Reg16Info:
		PUSHAD
		
		;Salvando posição inicial do cursor.
		MOV BX,WORD[debug.textPos]
		
		MOV EDI,debug.reg16Info
		CALL debug_PrintString

		;Restaurando posição inicial do cursor.
		MOV WORD[debug.textPos],BX

		;Escrevendo informações dos registradores de segmento.
		CALL debug_Reg16Info.draw
		MOV EAX,EDX
		CALL debug_Reg16Info.draw
		MOV AX,SS
		CALL debug_Reg16Info.draw
		MOV AX,FS
		CALL debug_Reg16Info.draw
		MOV AX,GS
		CALL debug_Reg16Info.draw
		MOV AX,CS
		CALL debug_Reg16Info.draw
		
		POPAD
		RET
	.draw:
		ADD WORD[debug.textPos],5 * 2 ;Movendo 5 colunas para direita.
		MOV EBX,2
		MOV ECX,16
		CALL debug_PrintInterger
		
		ADD WORD[debug.textPos],3 * 2 ;Movendo 3 colunas para direita.
		MOV EBX,10
		MOV ECX,5
		CALL debug_PrintInterger
		
		ADD WORD[debug.textPos],4 * 2 ;Movendo 4 colunas para direita.
		MOV EBX,16
		MOV ECX,4
		CALL debug_PrintInterger
		ADD WORD[debug.textPos],3 * 2 ;Movendo 3 colunas para direita.
		RET		

	;--------------------------------------------------------------------------------------------
	;@description: Procedimento para imprimir informações dos principais registradores de 32bits.
	;@input: ALL
	;@output: -
	;@author: alisson_linhares@hotmail.com
	debug_Reg32Info:
		PUSHAD ;Salvando todos os registradores na pilha.
		
		;Imprimindo um cabeçalho.
		MOV DX,WORD[debug.textPos]
		MOV EDI,debug.reg32Info
		CALL debug_PrintString
		
		XOR EBP,EBP
		.printNext32BitsReg:
			MOV EAX,DWORD[ESP + EBP]
			
			MOV WORD[debug.textPos],DX
			ADD WORD[debug.textPos],6 * 2 ;Movendo 6 colunas para direita.
			MOV EBX,2
			MOV ECX,32
			CALL debug_PrintInterger
			
			ADD WORD[debug.textPos],4 * 2 ;Movendo 4 colunas para direita.
			MOV EBX,10
			MOV ECX,EBX
			CALL debug_PrintInterger
			
			ADD WORD[debug.textPos],6 * 2 ;Movendo 6 colunas para direita.
			MOV EBX,16
			MOV ECX,8
			CALL debug_PrintInterger

			MOVZX EBX,WORD[debug.textPos]
			MOV BYTE[EBX + (TEXT_MODE_BUFFER + 3 * 2)],AL
			MOV BYTE[EBX + (TEXT_MODE_BUFFER + 4 * 2)],AH
			SHR EAX,16
			MOV BYTE[EBX + (TEXT_MODE_BUFFER + 5 * 2)],AL
			MOV BYTE[EBX + (TEXT_MODE_BUFFER + 6 * 2)],AH
			
			ADD DX,80 * 2
			ADD EBP,4
		CMP EBP,32
		JB .printNext32BitsReg
		
		POPAD
		RET
		
	;--------------------------------------------------------------------------------------------	
	;@description: Procedimento para imprimir o estado atual dos principais registradores. O sistema entra em pausa.
	;@input: -
	;@output: -
	;@author: alisson_linhares@hotmail.com
	debug_Break:
		PUSHAD
		PUSHFD
		PUSH DS
		PUSH ES
		
		;Entrando no modo kernel.
		MOV AX,KERNEL_DATA
		MOV ES,AX
		MOV DS,AX
		
		;Desativando o escalonador.
		INC BYTE[system.irqsEnabled]
		
		;Limpando o vídeo.
		CALL debug_Clear

		MOV EDI,debug.header
		CALL debug_PrintString 
		
		;Imprimindo informações dos registradores de 32bits mais importantes.
		MOV EAX,DWORD[ESP + STACK_EAX + 12]
		MOV EDI,DWORD[ESP + STACK_EDI + 12]
		CALL debug_Reg32Info
		
		;Imprimindo informações dos registradores de segmento.
		MOV WORD[debug.textPos],(80 * 10) * 2 
		MOVZX EAX,WORD[ESP + 4]
		MOVZX EDX,WORD[ESP    ]
		CALL debug_Reg16Info

		;Imprimindo informações das flags
		MOV WORD[debug.textPos],(80 * 14) * 2
		MOV EAX,DWORD[ESP + 8]
		CALL debug_DrawFlagsInfo

		MOV WORD[debug.textPos],(80 * 18) * 2
		CALL debug_WaitKeyPress
		
		;Ativando o escalonador
		DEC BYTE[system.irqsEnabled]
				
		POP ES
		POP DS
		POPFD
		POPAD
		RET
	
	;--------------------------------------------------------------------------------------------
	;@description: Procedimento para pausar a execução do sistema.
	;@input: -
	;@output: -
	;@author: alisson_linhares@hotmail.com
	debug_Pause:
		PUSHAD
		PUSH DS
		PUSH ES
		
		;Desativando o escalonador.
		INC BYTE[system.irqsEnabled]

		;Entrando no modo kernel.
		MOV AX,KERNEL_DATA
		MOV ES,AX
		MOV DS,AX
		
		CALL debug_WaitKeyPress

		;Ativando o escalonador
		DEC BYTE[system.irqsEnabled]
		
		POP ES
		POP DS
		POPAD
		RET
		
	;--------------------------------------------------------------------------------------------
	;@description: Procedimento que espera a tecla ENTER ser pressionada.
	;@input: -
	;@output: -
	;@author: alisson_linhares@hotmail.com
	debug_WaitKeyPress:
		MOV EDI,debug.pauseMsg
		CALL debug_PrintString
		
		;Limpa o buffer do teclado.
		.keyboarIsReady:
			IN AL,0x60
		CMP AL,KEY_ENTER 
		JE .keyboarIsReady
		
		;Esperando o usuário pressionar a tecla ENTER 
		.readLoop:
			IN AL,0x60
		CMP AL,KEY_ENTER
		JNE .readLoop
		RET
%endif

;--------------------------------------------------------------------------------------------	
;@description: Macro usada para alertar o usuário sobre o estado do OPERATION_MODE.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
%macro debug_Warning 0
	%warning "O DEBUG_MODE nao foi ativado. Verifique a constante OPERATION_MODE em KERNEL.ASM. Para mais informacoes, consulte o manual."
%endmacro 

;--------------------------------------------------------------------------------------------	
;@description: Macro para limpar a tela no modo debug.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
%macro clear 0
	%if OPERATION_MODE == DEBUG_MODE
		CALL debug_Clear
	%else
		debug_Warning
	%endif
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro para escrever uma string no modo debug.
;@input: %1 << *string || string
;@output: -
;@author: alisson_linhares@hotmail.com
%macro print_s 1 
	%if OPERATION_MODE == DEBUG_MODE
		PUSH EDI
		
		%ifstr %1
			JMP %%dataArea
				%%str DB %1,0
			%%dataArea:
			
			MOV EDI,%%str
		%else
			MOV EDI,%1
		%endif
		
		CALL debug_PrintString
		
		POP EDI
	%else
		debug_Warning
	%endif	
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro para escrever um byte no modo debug.
;@input: %1 << byte
;@output: -
;@author: alisson_linhares@hotmail.com
%macro print_b 1-3 10,0
	%if OPERATION_MODE == DEBUG_MODE && %2 >= 2 && %2 < 17
		PUSHAD
			
		%ifnum %1 
			MOV EAX,%1 & 0FFh
		%else
			MOVZX EAX,%1
			AND EAX,0FFh
		%endif	
		
		MOV EBX,%2
		MOV ECX,%3
		CALL debug_PrintInterger

		POPAD
	%else
		debug_Warning
	%endif
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro para escrever um word no modo debug.
;@input: %1 << word
;@output: -
;@author: alisson_linhares@hotmail.com
%macro print_w 1-3 10,0
	%if OPERATION_MODE == DEBUG_MODE && %2 >= 2 && %2 < 17
		PUSHAD
		
		%ifnum %1 
			MOV EAX,%1 & 0FFFFh
		%else
			MOVZX EAX,%1
		%endif
		
		MOV EBX,%2
		MOV ECX,%3
		CALL debug_PrintInterger
		
		POPAD
	%else
		debug_Warning
	%endif
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro para escrever um int no modo debug.
;@input: %1 << int
;@output: -
;@author: alisson_linhares@hotmail.com
%macro print_d 1-3 10,0
	%if OPERATION_MODE == DEBUG_MODE && %2 >= 2 && %2 < 17
		PUSHAD
		
		;Não compila esse código se o registrador passado for o EAX
		%ifnidn %1,EAX
			MOV EAX,%1
		%endif
	
		MOV EBX,%2
		MOV ECX,%3
		CALL debug_PrintInterger
		
		POPAD
	%else
		debug_Warning
	%endif
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro para escrever um char no modo debug.
;@input: %1 << char
;@output: -
;@author: alisson_linhares@hotmail.com
%macro print_c 1 
	%if OPERATION_MODE == DEBUG_MODE
		PUSH EDX
				
		%ifnidn %1,EDX
			%ifnidn %1,DL
				MOV DL,%1
			%endif
		%endif

		CALL debug_Print
		
		POP EDX
	%else
		debug_Warning
	%endif
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro usada para pausar o processamento do kernel.
;@input: %1 << char
;@output: -
;@author: alisson_linhares@hotmail.com
%macro pause 0
	%if OPERATION_MODE == DEBUG_MODE
		CALL debug_Pause
	%else
		debug_Warning
	%endif
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro usada para verificar o estado dos registradores em um ponto do código.
;@input: %1 << char
;@output: -
;@author: alisson_linhares@hotmail.com
%macro break 0
	%if OPERATION_MODE == DEBUG_MODE
		CALL debug_Break
	%else
		debug_Warning	
	%endif
%endmacro