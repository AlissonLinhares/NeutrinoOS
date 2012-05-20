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
;------------------------------Área reservada para registros---------------------------------
struc tCloseButton
	.component          RESB tComponent_size
endstruc

;--------------------------------------------------------------------------------------------
;@description: Procedimento para pintar o botão responsável por fechar as janelas.
;@input: ESP << X, ESP + 2 << Y, ESP + 4 << W, ESP + 6 << H, ESP + 8 << base
;@output: ALL
;@author: alisson_linhares@hotmail.com
closeButton_Draw:
	.Y EQU 4
	.X EQU 6
	.H EQU 8
	.W EQU 10
	.BASE EQU 12
	
	MOV ESI,DWORD[gui.closeButtonPtr]
	JMP nifButton_Draw.PRINT_NIF__