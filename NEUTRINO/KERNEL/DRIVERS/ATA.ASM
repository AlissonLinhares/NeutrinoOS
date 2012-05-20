; Copyright (C) 2011 Alisson Linhares de Carvalho.
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
ATA_MASTER          EQU 0E0h
ATA_SLAVE           EQU 0F0h
ATA_0               EQU 1F0h
ATA_1               EQU 170h
ATA_BLOCK_SIZE      EQU 512    ;O tamanho padrão para HDs e Disquetes é de 512b   
ATA_READ_DRIVE      EQU 020h
ATA_WRITE_DRIVE     EQU 030h
ATA_IDENTIFY        EQU 0ECh

ATAPI_MASTER        EQU 0
ATAPI_SLAVE         EQU 010h
ATAPI_EJECT_DRIVE   EQU 01Bh 
ATAPI_READ_DRIVE    EQU 0A8h
ATAPI_BLOCK_SIZE    EQU 2048  ;O tamanho padrão para unidades de CD e DVD é de 2048b

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para registros---------------------------------
struc tATAController 
	.semaphore       RESD 1       ;hd0Buffer ou hd1Buffer  
	.base            RESW 1
	.buffer          RESD 1
	.numberOfSectors RESD 1

	.address0        RESB 1        
	.address1        RESB 1        
	.address2        RESB 1         
	.address3        RESB 1
	.command         RESB 1       ;20h leitura, 30h escrita
endstruc 

struc tATAPIController
	.semaphore       RESD 1       ;hd0Buffer ou hd1Buffer  
	.base            RESW 1
	.buffer          RESD 1
	.numberOfSectors RESD 1
	.drive           RESB 1

.SCSIPack:
	.command         RESB 1       ;Bloco de comando SCSI 
	.reserved1       RESB 1
	.address0        RESB 1
	.address1        RESB 1
	.address2        RESB 1
	.address3        RESB 1
	.reserved2       RESB 3
	.control         RESB 1
	.reserved3       RESW 1
endstruc 

;--------------------------------------------------------------------------------------------
;------------------------------Área reservada para variáveis---------------------------------
ata:
.channel0                TIMES tATAPIController_size + 1 DB 0
.channel1                TIMES tATAPIController_size + 1 DB 0

;--------------------------------------------------------------------------------------------
;@description: Macro para escrever dados em um HD IDE.
;@input: %1 << PAGE_ADDRESS, %2 << ATA_0 || ATA_1, %3 << ATA_MASTER || ATA_SLAVE, %4 << BUFFER, %5 << TOTAL_OF_BLOCKS
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro ata_Write 5
	MOV BP,%2
	AND EBP,0FFFFh

	CALL ata_LockChannel
	JC %%ata_Error ;Verifica se ocorreu algum erro na configuração do semáforo            
		MOV DWORD[DS:EBP + tATAController.address0       ],%1
		MOV WORD [DS:EBP + tATAController.base           ],%2
		OR  BYTE [DS:EBP + tATAController.address3       ],%3
		MOV DWORD[DS:EBP + tATAController.buffer         ],%4
		MOV BYTE [DS:EBP + tATAController.command        ],ATA_WRITE_DRIVE
		MOV DWORD[DS:EBP + tATAController.numberOfSectors],%5
		CALL ata_LBA28_RW
		
		system_SemaphoreUnlock DS:EBP
	%%ata_Error:
%endmacro

;--------------------------------------------------------------------------------------------
;@description: Macro para ler dados em um HD IDE.
;@input: %1 << PAGE_ADDRESS, %2 << ATA_0 || ATA_1, %3 << ATA_MASTER || ATA_SLAVE, %4 << BUFFER, %5 << TOTAL_OF_BLOCKS
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro ata_Read 5
	MOV BP,%2
	AND EBP,0FFFFh

	CALL ata_LockChannel
	JC %%ata_Error
		MOV DWORD[DS:EBP + tATAController.address0       ],%1
		MOV WORD [DS:EBP + tATAController.base           ],%2
		OR  BYTE [DS:EBP + tATAController.address3       ],%3
		MOV DWORD[DS:EBP + tATAController.buffer         ],%4
		MOV BYTE [DS:EBP + tATAController.command        ],ATA_READ_DRIVE
		MOV DWORD[DS:EBP + tATAController.numberOfSectors],%5
		CALL ata_LBA28_RW
		
		system_SemaphoreUnlock DS:EBP
	%%ata_Error:
%endmacro

;--------------------------------------------------------------------------------------------
;@description: Macro para ler dados em um drive de CD/DVD IDE.
;@input: %1 << PAGE_ADDRESS, %2 << ATA_0 || ATA_1, %3 << ATA_MASTER || ATA_SLAVE, %4 << BUFFER
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro atapi_Read 4
	MOV BP,%2
	AND EBP,0FFFFh

	CALL ata_LockChannel
	JC %%atapi_Error
		MOV BYTE [DS:EBP + tATAPIController.drive    ],%3
		MOV WORD [DS:EBP + tATAPIController.base     ],%2 
		MOV DWORD[DS:EBP + tATAPIController.reserved1],0
		MOV WORD [DS:EBP + tATAPIController.reserved2],0
		MOV WORD [DS:EBP + tATAPIController.command  ],ATAPI_READ_DRIVE ;Limpando o reserved1 e inserindo o comando. 
		MOV BYTE [DS:EBP + tATAPIController.control  ],1 ;Lendo 1 setor
		MOV DWORD[DS:EBP + tATAPIController.address0 ],%1
		ROR DWORD[DS:EBP + tATAPIController.address0 ],16;Convertendo para big endian 
		ROR WORD [DS:EBP + tATAPIController.address0 ],8 ;
		ROR WORD [DS:EBP + tATAPIController.address2 ],8 ;
		MOV DWORD[DS:EBP + tATAPIController.buffer   ],%4
		CALL atapi_Execute

		system_SemaphoreUnlock DS:EBP
	%%atapi_Error:
%endmacro

;--------------------------------------------------------------------------------------------	
;@description: Macro para ejetar CD/DVD em um drive de CD/DVD IDE.
;@input: %1 << ATA_0 || ATA_1, %2 << ATAPI_MASTER || ATAPI_SLAVE
;@output: ALL
;@author: alisson_linhares@hotmail.com
%macro atapi_Eject 2
	MOV BP,%1
	AND EBP,0FFFFh

	CALL ata_LockChannel
	JC %%atapi_Error
		MOV BYTE [DS:EBP + tATAPIController.drive      ],%2
		MOV WORD [DS:EBP + tATAPIController.base       ],%1                
		MOV DWORD[DS:EBP + tATAPIController.command    ],0000001Bh         
		MOV DWORD[DS:EBP + tATAPIController.command + 4],00000002h          
		MOV DWORD[DS:EBP + tATAPIController.command + 8],0;Pacote para ejetar drive 1B,0,0,0,2,0,0,0,0,0,0,0
		CALL atapi_Execute
		
		system_SemaphoreUnlock DS:EBP
	%%atapi_Error:
%endmacro

;--------------------------------------------------------------------------------------------
;@description: Procedimento para controle de concorrência. Retornar o ponteiro para o canal requerido.
;@input: EBP << ATA_0 || ATA_1
;@output: EBP >> channel0 ou channel1
;@author: alisson_linhares@hotmail.com
ata_LockChannel:
	CMP BP,ATA_0
	JE .atahd0Semaphore
	CMP BP,ATA_1
	JE .atahd1Semaphore
		STC ;Retornado erro
		RET
	.atahd0Semaphore:
		MOV EBP,ata.channel0
		JMP .continue
	.atahd1Semaphore:
		MOV EBP,ata.channel1
	.continue:

	CALL system_SemaphoreLock ;Bloqueando o canal para o processo.
	RET

;--------------------------------------------------------------------------------------------	
;@description: Função que espera o drive ficar pronto.
;@input: DX << commandPort 
;@output: ALL
;@author: alisson_linhares@hotmail.com
ata_IsReady:
	;Esperando o disco ficar pronto

	.ataIsReady:        
		IN AL,DX

		TEST AL,AL
		JZ  .ata_Error
		TEST AL,00100001b 
		JNZ .ata_Error
		TEST AL,10000000b
		JNZ .Sleep
			TEST AL,01011000b ;Verifica se o drive está pronto [88] 
			JNZ .done
		.Sleep:
		
		system_Sleep ;Trocando de processo		
	JMP .ataIsReady
	.ata_Error:
		STC ;Retornando erro
	.done:
	RET

;--------------------------------------------------------------------------------------------
;@description: Resetando a controladora.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
ata_Reset:
	PUSH DX
	PUSH AX
	
;	MOV DX,WORD[DS:EBP + tATAController.base] 
;	OR  DX,206h ;Porta 3X6h

;	MOV AL,04h
;	OUT DX,AL ;SRST=1

;	XOR AL,AL
;	OUT DX,AL ;SRST=0
	
	MOV DX,WORD[DS:EBP + tATAController.base]
	ADD DX,7
	
	;Esperando o disco ficar pronto
	.hdIsBusy:
		IN AL,DX

		TEST AL,10000000b ;Verifica se o drive está trabalhando 
		JZ .hdReady1
		
		system_Sleep ;Trocando de processo      
	JMP .hdIsBusy 
	.hdReady1:

	POP AX
	POP DX
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para ler e escrever em unidades IDE.
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
ata_LBA28_RW:
	CLD
	MOV EDI,DWORD[DS:EBP + tATAController.buffer]
	MOV ESI,EDI
	
	CALL ata_Reset
	.readBlock:
		MOV DX,WORD[DS:EBP + tATAController.base]
		INC DL
		XOR AL,AL
		OUT DX,AL ;Mandando 0 para porta X1h
		
		;Enviando o total de setores para porta X2h
		INC DL
		MOV AL,ATA_BLOCK_SIZE / 512 ;Configurando para ler 512b. Algumas controladoras possuem problemas relativos a leitura de mais setores... 
		OUT DX,AL 

		;Enviando os bit 0..7 para porta X3h
		INC DL
		MOV AL,BYTE[DS:EBP + tATAController.address0]
		OUT DX,AL

		;Enviando os bit 8..15 para porta X4h
		INC DL
		MOV AL,BYTE[DS:EBP + tATAController.address1]
		OUT DX,AL

		;Enviando os bit 16..23 para porta X5h
		INC DL
		MOV AL,BYTE[DS:EBP + tATAController.address2]
		OUT DX,AL

		;Enviando os bit 24..28 + [Maste 0F0h || Slave 0E0h] para porta X6h
		INC DL
		MOV AL,BYTE[DS:EBP + tATAController.address3]
		OUT DX,AL

		;Enviando o tipo de operação "20h leitura e 30h gravação" para porta X7h
		INC DL
		MOV AL,BYTE[DS:EBP + tATAController.command]
		OUT DX,AL

		CALL ata_IsReady
		JC .hd_Error  ;Verifica se o drive está pronto 
		
		MOV ECX,ATA_BLOCK_SIZE / 4      
		MOV DX,WORD[DS:EBP + tATAController.base]   

		CMP BYTE[DS:EBP + tATAController.command],ATA_READ_DRIVE
		JNE .ata_Read
			REP INSD ;Carregando dados em EDI
			JMP .ata_Write
		.ata_Read:
			CMP BYTE[DS:EBP + tATAController.command],ATA_WRITE_DRIVE
			JNE .hd_Error
				REP OUTSD ;Gravando dados apontados por ESI
		.ata_Write:
		
		INC DWORD[DS:EBP + tATAController.address0]
		DEC DWORD[DS:EBP + tATAController.numberOfSectors]
	JNZ .readBlock
	
	.done:
		RET
	.hd_Error:
		PUSH DWORD ATA_COMMAND_ERROR
		CALL error_ThrowException  ;Informando ao núcleo sobre o erro.
	RET

;--------------------------------------------------------------------------------------------	
;@description: Procedimento para executar comandos básicos para dispositivos ATAPI.
;@input: -
;@output: ALL
;@author: alisson_linhares@hotmail.com
atapi_Execute:
	MOV DX,WORD[DS:EBP + tATAPIController.base]
	OR DX,6
	MOV AL,BYTE[DS:EBP + tATAPIController.drive]
	OUT DX,AL ;Drive master ou slave para porta 1X6h
	 
	ADD DX,200h ;Porta 3X6h
	IN AL,DX ;Sleep "Recomendado pelo OSDEV" 
	IN AL,DX ; Procurar uma forma melhor de fazer isso!
	IN AL,DX ;
	IN AL,DX ;
	
	;Ativando modo PIO 
	MOV DX,WORD[DS:EBP + tATAPIController.base]
	INC DX ;1X1h
	XOR AL,AL
	OUT DX,AL ;Mandando 0 para porta 1X1h (1 == DMA / PIO  == 0)

	;Enviando a parte baixa de ATAPI_BLOCK_SIZE "Tamanho do bloco usado nos drives de CD e DVD" para a porta 1X4h 
	ADD DX,3
	MOV AL,ATAPI_BLOCK_SIZE & 0FFh ;Pegando os 8 primeiros bits 	
	OUT DX,AL                    
	
	;Enviando a parte alta de ATAPI_BLOCK_SIZE para a porta 1X5h
	INC DX
	MOV AL,ATAPI_BLOCK_SIZE >> 8 ;Movendo 8bits para esquerda 	  
	OUT DX,AL
	
	;Enviando o modo de operação para a porta 1X7h
	ADD DX,2
	MOV AL,0A0h ;Modo ATAPI
	OUT DX,AL        
	
	CALL ata_IsReady ;Verifica se o drive está pronto, para receber os comandos scsi
	JC .disk_Error
		CLD
		MOV DX,WORD[DS:EBP + tATAPIController.base]
		LEA ESI,[DS:EBP + tATAPIController.SCSIPack]
		MOV ECX,6
		REP OUTSW ;Movendo 12 bytes para porta 1X0h

		CMP BYTE[DS:EBP + tATAPIController.command],ATAPI_EJECT_DRIVE ;Verifica se o comando é de eject
		JE .done
			OR DX,7 ;Porta 1X7h
			CALL ata_IsReady ;Verifica se o drive está pronto, para enviar os dados
			JC .disk_Error       

			MOV ECX,ATAPI_BLOCK_SIZE / 2   
			MOV DX ,WORD[DS:EBP + tATAPIController.base]
			MOV EDI,DWORD[DS:EBP + tATAPIController.buffer]
			REP INSW ;Carregando dados em EDI
		.done:
		RET
	.disk_Error:
		PUSH DWORD ATAPI_COMMAND_ERROR
		CALL error_ThrowException ;Informando ao núcleo sobre o erro.
	RET

;--------------------------------------------------------------------------------------------	
;@description: Tratador de interrupções para unidade master.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
ata_MasterIrqHandler:
	PUSH AX
	MOV AL,020h
	OUT 0A0h,AL
	OUT 020h,AL
	POP AX
	IRETD

;--------------------------------------------------------------------------------------------	
;@description: Tratador de interrupções para unidade slave.
;@input: -
;@output: -
;@author: alisson_linhares@hotmail.com
ata_SlaveIrqHandler:
	PUSH AX
	MOV AL,020h
	OUT 0A0h,AL
	OUT 020h,AL
	POP AX
	IRETD