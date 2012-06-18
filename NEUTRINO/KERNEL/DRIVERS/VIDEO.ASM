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
%include "KERNEL/DRIVERS/VIDEO/VIDEO_16.ASM" ;Vídeo em modo 16bpp
%include "KERNEL/DRIVERS/VIDEO/VIDEO_24.ASM" ;Vídeo em modo 24bpp

;--------------------------------------------------------------------------------------------
;-----------------------------Área reservada para constantes---------------------------------
VIDEO_SIGNATURE      EQU 0x89ABCDEF
VIDEO_MAX_WIDTH      EQU 1024
VIDEO_MAX_HEIGHT     EQU 800
VIDEO_BUFFER_SIZE    EQU VIDEO_MAX_WIDTH * VIDEO_MAX_HEIGHT * 3
VIDEO_MODES          EQU 3 ;8 ;Modos suportados pelo vesa 1.2+
 
;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para registros---------------------------------
;@description: Registro usado para compartilhar informações entre o Kernel Neutrino e a NLIB. 
struc tVideoInfo
	.signature     RESD 1 ;Assinatura do registro de troca.
	.bufferPtr     RESD 1 ;Endereço do buffer de vídeo.
	.memoryPtr     RESD 1 ;Endereço da memória de vídeo.
	.resolution    RESD 1 ;Resolução do vídeo.
	.height        RESW 1 ;Tamanho vertical do vídeo.
	.width         RESW 1 ;Tamanho horizontal do vídeo.
	.bpp           RESB 1 ;Total de bytes por pixel.
endstruc

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para variáveis--------------------------------- 
video:
.mode                DW 114h,111h ;11Bh,118h,115h,112h,11Ah,117h,114h,111h ;Modos suportados pelo vesa 1.2+
.buffer              DD 0 ;Ponteiro para o buffer de vídeo.
.memoryPtr           DD 0 ;Ponteiro para a memória de vídeo.
.resolution          DD 0
.height              DW 0 
.width               DW 0
.bpp                 DB 0 ;Total de bytes por pixel.
.bpl                 DD 0 ;Total de bytes por linha.

;--------------------------------------------------------------------------------------------
;@description: Macro responsável por configurar e inicializar o sistema gráfico do neutrino. O kernel pode trabalhar em 3 modos de vídeo: 16bpp, 24bpp e Modo texto.
;@input: ALL
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro video_Install 0
	;Verifica se o sistema deve entrar em modo gráfico.
	CMP BYTE[system.mode],GRAPHICS_MODE
	JNE %%enableTextMode
	
		XOR SI,SI
		MOV DI,kernel_Buffer
		MOV AX,4F00h
		INT 10h
		
		;Verifica se o sistema suporta o modo vesa 1.2+
		CMP WORD[kernel_Buffer + 4],200h
		JL %%enableTextMode

		%%nextMode:
			;Verificando se a função é suportada
			MOV DWORD[kernel_Buffer + 28h],0
			MOV DI,kernel_Buffer
			MOV AX,4F01h
			MOV CX,WORD[SI + video.mode]
			INT 10h

			;Verifica se a função existe
			CMP AX,004Fh                    
			JNE %%continue 
			
			;Verifica se o modo suporta o 'Linear frame buffer'
			TEST BYTE[kernel_Buffer],80h 
			JZ %%continue 
			CMP DWORD[kernel_Buffer + 28h],0
			JE %%continue

			;Configura as variáveis de vídeo 
			MOV EAX,DWORD[kernel_Buffer + 28h] 
			MOV DWORD[video.memoryPtr],EAX
			
			;Calculando o número de bytes por pixel
			MOV CL,BYTE[kernel_Buffer + 19h] 
			SHR CL,3 ;CL = CL * 8
			MOV BYTE[video.bpp],CL  
			
			;Salvando resolução
			MOVZX EAX,WORD[kernel_Buffer + 12h]
			MOV WORD[video.width],AX
			
			;Pegando o número de bytes da largura do vídeo.
			CMP CL,24
			JE %%24bpp
				SHL EAX,1
				JMP %%16bpp
			%%24bpp:
				LEA EAX,[EAX * 2 + EAX] ;EAX = EAX * 3
			%%16bpp:
			
			;Configurando total de bytes de uma linha.
			MOV DWORD[video.bpl],EAX
			
			MOV BX,WORD[kernel_Buffer + 14h]
			MOV WORD[video.height],BX

			;Calculando a resolução
			MUL BX
			SHL EDX,16 
			MOV DX,AX
			MOV DWORD[video.resolution],EDX
			
			;Setando o modo de video
			MOV AX,4F02h
			MOV BX,WORD[SI + video.mode]
			ADD BX,0100000000000000b ;LFB e Clear display memory
			INT 10h
			
			CMP AX,004Fh
			JE %%done
		%%continue:
			ADD SI,2
			CMP SI,VIDEO_MODES * 2 ;Número de modos de vídeo suportados
			JNE %%nextMode

	%%enableTextMode:
		;Em caso de erro o sistem entra no modo texto 80x25
		MOV BYTE[system.mode],TEXT_MODE
		MOV AX,0003h 
		INT 10h
		
		;Desativando Blinking
		MOV AX,1003h 
		XOR BX,BX               
		INT 10h
	%%done:
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Procedimento projetado para retornar informações de vídeo.
;@input: EDI << tVideoInfo
;@output: EDI >> tVideoInfo
;@author: alisson_linhares@hotmail.com
video_GetInfo:
	;Verifica se o registro enviado é válido.
	CMP DWORD[SS:EDI + tVideoInfo.signature],VIDEO_SIGNATURE
	JNE .abort
		PUSH EAX
		
		;Inserindo dados de vídeo no buffer de retorno.
		MOV EAX,DWORD[video.buffer]
		MOV DWORD[SS:EDI + tVideoInfo.bufferPtr],EAX
		
		MOV EAX,DWORD[video.memoryPtr]
		MOV DWORD[SS:EDI + tVideoInfo.memoryPtr],EAX
		
		MOV EAX,DWORD[video.resolution]
		MOV DWORD[SS:EDI + tVideoInfo.resolution],EAX

		MOV AX,WORD[video.height]
		MOV WORD[SS:EDI + tVideoInfo.height],AX
		
		MOV AX,WORD[video.width]
		MOV WORD[SS:EDI + tVideoInfo.width],AX
		
		MOV AL,BYTE[video.bpp]
		MOV BYTE[SS:EDI + tVideoInfo.bpp],AL

		POP EAX
	.abort:
	RET