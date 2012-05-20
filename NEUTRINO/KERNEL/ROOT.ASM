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
ROOT_NODE_PTR EQU $ ;Ponteiro para o início do sistema de arquivos.

;--------------------------------------------------------------------------------------------	
;@description: Macro projetada para simplificar a criação de subpastas.
;@input: %1 << nome do nó, %2 << Tamanho do nó "em páginas", %3 << Ponteiro para os dados, %4 << Tipo do nó.
;@output: -
;@author: alisson_linhares@hotmail.com
%macro new_node 4
	%strlen %%name_Lenght %1

	%%subnode_DataPtr      DD ((%3 - ROOT_NODE_PTR)/STORAGE_PAGE_SIZE) + NFS_ROOT_SECTOR_PTR 
	%%subnode_Size         DD %2
	%%subnode_Type         DB %4
	%%subnode_Name         DB %1
			       TIMES NFS_NAME_LENGTH - %%name_Lenght DB 0
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro projetada para iniciar uma pasta.
;@input: %1 << Ponteiro para o nó.
;@output: -
;@author: alisson_linhares@hotmail.com
%macro start_node 1 
	%1 EQU $
	
	;Salvando o contexto da macro
	%push start_node
	%$begin_ptr:
%endmacro 

;--------------------------------------------------------------------------------------------	
;@description: Macro projetada para marcar o fim de uma pasta.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
%macro end_node 0
	;Calculando o tamanho do nó
	TIMES 512 - ($ - %$begin_ptr) DB 0

	%pop 
%endmacro
 
;--------------------------------------------------------------------------------------------	
;@description: Macro responsável por simplificar a importação de dados.
;@input: %3 << filePath
;@output: %1 >> dataPtr, %2 >> dataSize
;@author: alisson_linhares@hotmail.com
%macro import_data 3
	%2 EQU (1 + (%%ALING - $)/STORAGE_PAGE_SIZE)
	%1 INCBIN %3
	%%ALING TIMES 512 * %2 - ($ - %1) DB 0
%endmacro

;--------------------------------------------------------------------------------------------
;---------Estrutura projetada para conter o formato inicial do sistema de arquivos.----------
;@description: Diretório raiz do sistema.
start_node ROOT_NODE
	new_node 'boot',1,BOOT_NODE,NFS_SUBNODETYPE_FOLDER ;Pasta que contém os programas de boot
	new_node 'apps',1,APPS_NODE,NFS_SUBNODETYPE_FOLDER ;Pasta que contém os programas normais
	new_node 'home',1,HOME_NODE,NFS_SUBNODETYPE_FOLDER ;Pasta que contém os arquivos do usuário
	new_node 'data',1,DATA_NODE,NFS_SUBNODETYPE_FOLDER ;Pasta que contém dados do sistema e dos programas
	new_node 'conf',1,CONF_NODE,NFS_SUBNODETYPE_FOLDER ;Pasta que contém configurações de programas e do sistema
	new_node 'temp',1,TEMP_NODE,NFS_SUBNODETYPE_FOLDER ;Arquivos temporários
	new_node 'lib' ,1,LIB_NODE ,NFS_SUBNODETYPE_FOLDER ;Bibliotecas
end_node                      

;@description: Pasta reservada para programas de boot.
start_node BOOT_NODE
	new_node 'desktop.bin' ,DESKTOP_SIZE,DESKTOP_PTR,NFS_SUBNODETYPE_BINARY
	new_node 'cmd.bin',CMD_SIZE,CMD_PTR,NFS_SUBNODETYPE_BINARY
end_node

;@description: Pasta reservada para programas do usuário.
start_node APPS_NODE     
	new_node 'demo.bin',DEMO_SIZE,DEMO_PTR,NFS_SUBNODETYPE_BINARY
end_node   
   
;@description: Pasta reservado para arquivos do usuário.
start_node HOME_NODE
	new_node 'desktop.jpg',DESKTOP_IMG_SIZE,DESKTOP_IMG_PTR,NFS_SUBNODETYPE_DATA
	new_node 'license.txt',GPL3_SIZE,GPL3_PTR,NFS_SUBNODETYPE_DATA
end_node

;@description: Pasta reservada para dados dos sistema.
start_node DATA_NODE
	new_node 'nif.img',NIF_SIZE,NIF_PTR,NFS_SUBNODETYPE_DATA
end_node

;@description: Pasta reservada para arquivos de configuração do sistema.
start_node CONF_NODE

end_node

;@description: Pasta reservada para arquivos temporários.
start_node TEMP_NODE

end_node

;@description: Pasta reservada para bibliotecas do sistema.
start_node LIB_NODE

end_node

;--------------------------------------------------------------------------------------------
;-------------------------------Área reservada para dados------------------------------------
import_data CMD_PTR,CMD_SIZE,"BIN/CMD.BIN"
import_data DESKTOP_PTR,DESKTOP_SIZE,"BIN/DESKTOP.BIN" 
import_data DESKTOP_IMG_PTR,DESKTOP_IMG_SIZE,"RES/DESKTOP.JPG"
import_data NIF_PTR,NIF_SIZE,"BIN/NIF.BIN" 
import_data DEMO_PTR,DEMO_SIZE,"BIN/DEMO.BIN"
import_data GPL3_PTR,GPL3_SIZE,"KERNEL/LICENSE"
