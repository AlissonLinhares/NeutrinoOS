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

[ORG 8000h]

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para constantes--------------------------------
HD_MASTER          EQU 080h
STORAGE_DISK_USAGE EQU 2800

;--------------------------------------------------------------------------------------------	
;@description: Procedimento principal do instalador.
;@input: DL << BootDisk
;@output: -
;@author: alisson_linhares@hotmail.com
main:
	;Salvando o número da unidade de boot
	MOV BYTE[bootDisk],DL

	;Imprimindo mensagem inicial
	MOV BX,startMsg
	CALL print
	
	;Esperando pela confirmação do usuário
	XOR AH,AH
	INT 16h 

	CMP AL,'s'
	JNE .reboot 
		CALL diskFormat ;Formatando o hd_master
		CALL installSys ;Carregando e instalando 1.44mb no disco
		CALL startSys
	.reboot:
	
	;Reiniciando o sistema em caso de erro
	CALL reboot 

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para escrever textos na tela.
;@input: BX << msgPtr
;@output: -
;@author: alisson_linhares@hotmail.com
print: 
	PUSH AX
	PUSH BX
	
	MOV AH,0Eh 
	MOV AL,BYTE[BX]   
	
	.nextChar:
		INT 10h
		INC BX
		MOV AL,BYTE[BX]
	TEST AL,AL
	JNZ .nextChar

	POP BX
	POP AX
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para reiniciar o sistema.
;@input: BX << msgPtr
;@output: -
;@author: alisson_linhares@hotmail.com
reboot:
	;Informando ao usuário sobre o reboot
	MOV BX,msgReboot
	CALL print
	
	;Esperando confirmação do usuário
	XOR AH,AH
	INT 16h 
   
	MOV AX,0040h
	MOV DS,AX
	MOV WORD[0072h],0000h    
	JMP 0ffffh:0000h ;Salta para o código do post	

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para iniciar o sistema do disco.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
startSys:
	MOV BX,msgStartNOS
	CALL print
	
	;Lendo uma tecla
	XOR AH,AH
	INT 16h 
	
	CMP AL,'s'
	JNE .abort
		MOV BX,msgStartSystem
		CALL print

		MOV SI,diskPack
		MOV BYTE[diskPack],10h       ;Tamanho do pacote
		MOV BYTE[diskPack + 01h],0   ;Reservado 
		MOV WORD[diskPack + 02h],1   ;Número de blocos trasferidos
		MOV WORD[diskPack + 04h],0   ;offset
		MOV WORD[diskPack + 06h],7C0h;segment
		MOV DWORD[diskPack + 08h],0  ;LBA
		MOV AH,42h
		MOV DL,HD_MASTER
		INT 13h
		
		;Verifica se ocorreu um erro na inicialização do sistema
		JC .startError
		CMP DWORD[07C05h],'NFS!'
		JNE .startError
			JMP 07C0h:0000h  ;--> Passa o controle para o Neutrino/0050h:0000h -> 500h 	
		.startError:
		
		MOV BX,msgStartNOSError
		CALL print
	.abort:
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para instalar o sistema.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
installSys:
	PUSHA
	MOV BX,msgInstall
	CALL print
	
	MOV AX,050h
	MOV ES,AX
	MOV SI,diskPack ;Configurando registro para INT 13h / AH = 43
	MOV BYTE[diskPack    ],10h ;Tamanho do pacote
	MOV BYTE[diskPack + 1],0 ;Reservado 
	MOV WORD[diskPack + 2],36 ;Número de blocos trasferidos
	MOV WORD[diskPack + 4],0 ;Offset
	MOV WORD[diskPack + 6],50h ;Segment
	MOV DWORD[diskPack + 08h],0 ;LBA
	
	MOV DI,(STORAGE_DISK_USAGE)/36
	
	.installLoop:
		;Troca de trilha
		INC BYTE[track]
		
		;Lendo cabeça 0
		MOV AX,0212h ;Lendo 18 setores AL = 18 e AH = 02 
		MOV CH,BYTE[track] ;Track
		MOV CL,1 ;Lendo do primeiro setor 
		XOR BX,BX ;Gravando em 0050h:0000 
		MOVZX DX,BYTE[bootDisk]   
		INT 13h	
		JC .continue
		
		;Lendo cabeça 1
		MOV AX,0212h ;Lendo 18 setores AL = 18 e AH = 02 
		MOV CH,BYTE[track] ;Track
		MOV CL,1 ;Lendo do primeiro setor 
		MOV DH,1 ;Lendo segunda cabeça
		MOV DL,BYTE[bootDisk]      
		MOV BX,2400h ;Grava em 0050h:2400h
		INT 13h
		JC .continue
		
		MOV AX,4300h
		MOV DL,HD_MASTER ;Número do drive
		
		;Gravando 36 blocos no disco
		INT 13h	                     
		JC .continue
		
		ADD DWORD[diskPack + 08h],36
	DEC DI 	
	JNZ .installLoop
	.continue:

	TEST DI,DI
	JNZ .abort
		MOV BX,msgInstallOk
		CALL print
		JMP .done
	.abort:
		MOV BX,msgInstallError
		CALL print
		CALL reboot
	.done:
	
	POPA
	RET
	
;--------------------------------------------------------------------------------------------	
;@description: Procedimento para formatar o disco.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
diskFormat:
	PUSHA
	
	MOV BX,msgFormat
	CALL print
	
	MOV DX,1F6h                  
	MOV AL,0A0h
	OUT DX,AL ;HD Master[0A0h] ou Slave[0B0h]

	INC DX ;1X7h
	MOV AL,0ECh ;Comando de identificação
	OUT DX,AL

	.ataIsReady:
		IN AL,DX
	TEST AL,AL
	JZ  .formatError
	TEST AL,00000001b 
	JNZ .formatError
	TEST AL,01000000b ;Verifica se o drive está pronto 
	JZ .ataIsReady ;Esperando o disco ficar pronto
		XOR AX,AX
		MOV ES,AX
	
		CLD
		MOV DX,1F0h ;Movendo a porta base para DX
		MOV CX,256
		MOV DI,END_SYSTEM
		REP INSW ;Lendo dados em DI
	
		;Configurando o sistema de gerência de memória
		MOV EAX,DWORD[END_SYSTEM + 120]
		SUB EAX,STORAGE_DISK_USAGE                
		MOV DWORD[pageList.blockSize],EAX ;Configurando o tamanho do bloco de páginas
		
		;Gravando em disco o bloco de páginas para o sistema de alocação
		MOV SI,diskPack
		MOV DWORD[diskPack + 08h],STORAGE_DISK_USAGE 
		MOV BYTE [diskPack      ],10h ;Tamanho do pacote
		MOV BYTE [diskPack + 01h],0 ;Reservado 
		MOV WORD [diskPack + 02h],1 ;Número de blocos trasferidos
		MOV WORD [diskPack + 04h],pageList
		MOV AX,4300h	
		MOV DL,HD_MASTER ;Número do drive
		INT 13h                             
		JC .formatError
		
		MOV BX,msgFormatOk
		CALL print
		JMP .done
	.formatError:
		MOV BX,msgFormatError
		CALL print
		CALL reboot
	.done:
	POPA
	RET
	 
;--------------------------------------------------------------------------------------------
;-------------------------------Área reservada para variáveis--------------------------------
startMsg         DB 'Instalar neutrino o.s. no HD-MASTER?  (s/n)',0Ah,0Dh,0
msgFormat        DB ' - Formatando o HD-MASTER.',0Ah,0Dh,0	
msgFormatOk      DB '   - HD-MASTER formatado sem erros.',0Ah,0Dh,0
msgFormatError   DB '   - HD-MASTER formatado com erros.',0Ah,0Dh,0
msgInstall       DB ' - Instalando neutrino o.s.',0Ah,0Dh,0	
msgInstallOk     DB '   - Instalacao finalizada sem erros.',0Ah,0Dh,0  
msgInstallError  DB '   - Instalacao finalizada com erros.',0Ah,0Dh,0
msgStartNOS      DB 'Iniciar neutrino o.s. pelo HD-MASTER? (s/n)',0Ah,0Dh,0 
msgStartSystem   DB ' - Iniciando sistema.',0Ah,0Dh,0
msgStartNOSError DB ' - Não foi possível iniciar o sistema, verifique se seu HD-MASTER está corretamente configurado!',0Ah,0Dh,0
msgReboot        DB 'Remova o cd e digite (ENTER) para reiniciar...',0Ah,0Dh,0
track            DB 0
bootDisk         DB 0 
diskPack TIMES 18h  DB 0
 
pageList:
.nextBlock  DD 0
.blockSize  DD 0
           
END_SYSTEM EQU $