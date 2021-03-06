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

[ORG 0500h]

;Iniciando o kernel
JMP kernel_Main 

;--------------------------------------------------------------------------------------------
;-----------------------------�rea reservada para constantes---------------------------------
;Constantes externas.
DEBUG_MODE         EQU 2 ;Modo linha de comando com fun��es de debug.
TEXT_MODE          EQU 1 ;Modo linha de comando.
GRAPHICS_MODE      EQU 0 ;Modo gr�fico.

;Configurando o modo de execu��o do sistema.
%ifdef OPERATION_MODE ;Verifica se OPERATION_MODE foi definido na compila��o -dOPERATION_MODE=DEBUG_MODE|TEXT_MODE|GRAPHICS_MODE
	%if OPERATION_MODE > 2 || OPERATION_MODE < 0
		%assign OPERATION_MODE GRAPHICS_MODE
		%warning "O par�metro OPERATION_MODE retornou um atributo inv�lido, portanto o sistema ser� compilado em GRAPHICS_MODE. Para mais informa��es, consulte o manual."
	%endif
%else
	OPERATION_MODE EQU GRAPHICS_MODE
%endif

;Controle de vers�o. A m�xima vers�o suportada � "511.99" = 111111111.1100011b
KERNEL_VERSION     EQU 4 ;0.04

;--------------------------------------------------------------------------------------------
;------------------------Importando macros, procedimentos e dados----------------------------
[BITS 32]

%include "KERNEL/SYS/DEBUG.ASM"
%include "KERNEL/SYS/ERROR.ASM"
%include "KERNEL/SYS/SYSTEM.ASM"
%include "KERNEL/SYS/SCHEDULER.ASM"
%include "KERNEL/DRIVERS/VIDEO.ASM"
%include "KERNEL/SYS/EVENT.ASM"
%include "KERNEL/GUI/GUI.ASM"
%include "KERNEL/SYS/ISR0x30.ASM"
%include "KERNEL/DRIVERS/CMOS.ASM"
%include "KERNEL/DRIVERS/ATA.ASM"
%include "KERNEL/SYS/MEMORY.ASM"
%include "KERNEL/SYS/STORAGE.ASM"
%include "KERNEL/DRIVERS/MOUSE.ASM"
%include "KERNEL/DRIVERS/KEYBOARD.ASM"
%include "KERNEL/SYS/NFS.ASM"

[BITS 16]


;--------------------------------------------------------------------------------------------	
;@description: Procedimento principal do n�cleo.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
kernel_Main:
	system_Start    ;1 - Iniciando e configurando o sistema.
	gui_Start       ;2 - Iniciando o gerente gr�fico.
	scheduler_Start ;3 - Iniciando o escalonador.
	HLT             ;Fim do kernel

;--------------------------------------------------------------------------------------------
;--------------------------�rea reservada para dados do kernel-------------------------------
kernel_Buffer    TIMES 4096 DB 0
kernel_Stack     EQU $
kernel_Alignment TIMES (NFS_ROOT_SECTOR_PTR - 4) * STORAGE_PAGE_SIZE - ($-$$) DB 0

;--------------------------------------------------------------------------------------------
;-----------------------------Diret�rio principal do sistema---------------------------------
%include "KERNEL/ROOT.ASM"