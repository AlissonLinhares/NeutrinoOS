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

[ORG 7C00h]
[BITS 16]

;--------------------------------------------------------------------------------------------
;-----------------------------Área reservada para constantes---------------------------------
;Constantes externas.
%define CD "CD"
%define DVD "DVD"
%define HD "HD"

;Verifica se BOOT_FROM foi definido na compilação -dBOOT_FROM=CD|DVD|HD
%ifdef BOOT_FROM
	%if BOOT_FROM == CD || BOOT_FROM == DVD
		SECTOR_SIZE EQU 4
		SECTOR_LBA  EQU (0x12000 / 0x800) + 1
	%else
		%if BOOT_FROM != HD
			%warning "O parâmetro BOOT_FROM retornou um atributo inválido, portanto o sistema usará a formatação padrão. Para mais informações, consulte o manual."
		%endif

		SECTOR_SIZE EQU 1
		SECTOR_LBA  EQU 1
	%endif
%else
	SECTOR_SIZE EQU 1
	SECTOR_LBA  EQU 1
%endif

;Constantes locais.
USED_PAGES EQU 2800/SECTOR_SIZE
LIST_OF_PAGES_PTR EQU 2800/SECTOR_SIZE 
ROOT_NODE_PTR EQU 2000/SECTOR_SIZE
NUMBER_OF_BLOCKS EQU 59/SECTOR_SIZE

;--------------------------------------------------------------------------------------------
;-------------------------------------Registro de boot---------------------------------------
JMP 0:tBootSector.codeArea ;Configurando CS e IP
tBootSector.signature        DD 'NFS!' 
tBootSector.usedPages        DD USED_PAGES            ;Total de páginas usadas pelo kernel.
tBootSector.listOfPagesPtr   DD LIST_OF_PAGES_PTR     ;Ponteiro para o bloco de páginas livres.
tBootSector.rootNode.dataPtr DD ROOT_NODE_PTR         ;Ponteiro para o nó raiz.
tBootSector.rootNode.size    DD 1                     ;Configurando o nó raiz para trabalhar com 512 bytes.
tBootSector.rootNode.type    DB 1                     ;Configurando o nó raiz como pasta.
tBootSector.rootNode.name    DB 'ND0 - NEUTRINO O.S.' ;Configurando o nome da unidade.
                             TIMES 49 - ($-$$) DB 0

;--------------------------------------------------------------------------------------------
;-------------------------Área reservada para o código de inicialização----------------------
tBootSector.codeArea:
	;Configurando registradores de segmento e pilha.
	XOR AX,AX
	MOV DS,AX
	MOV ES,AX
	MOV FS,AX
	MOV GS,AX
	MOV SS,AX
	MOV SP,7C00h
	
	;Carregando sistema para memória.
	MOV SI,packet
	MOV AH,42h
	INT 13h

	;Verifica se ocorreu um erro na inicialização do sistema.
	JC .showError
		JMP 0050h:0000h ;Passa o controle para o Neutrino/0050h:0000h -> 500h.
	.showError:
		;Informando mensagem de erro para o usuário.
		MOV BX,errorMsg
		MOV AH,0Eh 
		
		.printLoop:
			MOV AL,BYTE[BX]
			INT 10h
			INC BX
		CMP BX,packet ;Verifica se terminou a string
		JB .printLoop
	JMP $

;--------------------------------------------------------------------------------------------
;------------------------Área reservada para os dados de inicialização-----------------------
tBootSector.dataArea:
errorMsg                        DB 0Dh,'   - Nao foi possivel iniciar o sistema. Verifique se o seu HD-MASTER foi corretamente configurado.',0Ah,0Dh
packet:
	.size                   DB 10h
	.reserved               DB 0
	.numberOfBlocks         DW NUMBER_OF_BLOCKS
	.offset                 DW 0          ;O kernel é carregado na posição 500h
	.segment                DW 50h        ;
	.posLBA                 DQ SECTOR_LBA ;Setor inicial

;Esse registro de boot define as partições nos disco, alguns computadores só conseguem dar boot em HDs e USB-Drives com esses registros ativados. 
tBootSector.alignment           TIMES 446-($-$$) DB 0                        
tBootSector.bootIndicator       DB 80h ;80 = botável, 0 = não botável  
tBootSector.startHeadNumber     DB 0   ;CHS - 0,0,1
tBootSector.startCylinderNumber DW 0100h
tBootSector.descriptor          DB 0Bh ;FAT 32 - Se colocar 0 ocorre erro em alguns PCs...
tBootSector.lastHeadNumber      DB 16
tBootSector.lastCylinderNumber  DW 03FCFh
tBootSector.startingSector      DD 1
tBootSector.partitionSize       DD 207 * 16 * 63
tBootSector.reserved            TIMES (SECTOR_SIZE * 512 - 2)-($-$$) DB 0 ;Alinhando dados do kernel.
tBootSector.bootSignature       DW 0AA55h

;--------------------------------------------------------------------------------------------
;------------------------Área reservada para os dados do kernel -----------------------------
incbin "BIN/KERNEL.BIN" ;Importando os binários do kernel