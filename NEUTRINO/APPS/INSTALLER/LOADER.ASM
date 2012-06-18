; Copyright (C) 2011-2012 Alisson Linhares de Carvalho.
; All rights reserved.
;
; This file is part of the neutrino installer.
;
; The neutrino installer is free software: you can redistribute it and/or 
; modify it under the terms of the GNU General Public License as 
; published by the Free Software Foundation, either version 3 of the 
; License, or (at your option) any later version.
;
; The neutrino installer is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with the neutrino installer. If not, see <http://www.gnu.org/licenses/>.
;
;--------------------------------------------------------------------------------------------

[ORG 7C00h]
[BITS 16]

main:
	CLI
	
	;Configurando registradores de segmento e a pilha
	XOR AX,AX   
	MOV DS,AX
	MOV SS,AX 
	
	MOV AX,0800h
	MOV ES,AX  
	MOV SP,7C00h 
	
	STI

	PUSH DX

	;Lendo dados gravados no disquete
	MOV AX,0211h ;Lendo 17 setores AL = 17 e AH = 02h 
	MOV CX,0002h ;Lendo depois do segundo setor 
	XOR BX,BX ;Gravando em 0050h:0000 
	XOR DH,DH
	INT 13h
 
	POP DX

	JMP 0800h:0000 ;Pulando para o código do installer.bin

TIMES 510 - ($-$$) DB 0 ;Configurando setor de boot
                   DW 0AA55h
;--------------------------------------------------------------------------------------------
;----Importando dados do installer, kernel e loader. Montando uma imagem de disquete 1.44----
incbin "BIN/INSTALLER.BIN" ;Código do instalador
TIMES 36 * 512 - ($-$$) DB 0 ;Área entre o instalador e o código do sistema  
incbin "BIN/LOADER.BIN" ;Importando o loader.bin 
TIMES 18 * 80 * 2 * 512 -($-$$) DB 0