/*---------------------------------------------------------------------------*
 * Copyright (C) 2011 Alisson Linhares de Carvalho.                          *
 * All rights reserved.                                                      *
 *                                                                           *
 * This file is part of the neutrino lib.                                    *
 *                                                                           *
 * The neutrino lib is free software: you can redistribute it and/or         *
 * modify it under the terms of the GNU Lesser General Public License as     *
 * published by the Free Software Foundation, either version 3 of the        *
 * License, or (at your option) any later version.                           *
 *                                                                           *
 * The neutrino lib is distributed in the hope that it will be useful,       *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of            *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             *
 * GNU Lesser General Public License for more details.                       *
 *                                                                           *
 * You should have received a copy of the GNU Lesser General Public License  *
 * along with the neutrino lib. If not, see <http://www.gnu.org/licenses/>.  *
 *---------------------------------------------------------------------------*/

#ifndef SYS_H
#define SYS_H

namespace nlib {

	/** Lista completa de interrupções do sistema. */
	enum tISR0x30 {
		PROMPT_PRINT_CHAR = 0     ,/**< EAX << 00; Função para imprimir caracter no prompt de comando. */
		PROMPT_PRINT_STRING       ,/**< EAX << 01; Função para imprimir string no prompt de comando. */ 
		PROMPT_PRINT_INTEGER      ,/**< EAX << 02; Função para imprimir um valor numérico no prompt de comando. */
		PROMPT_CLEAR              ,/**< EAX << 03; Função para limpar o prompt de comando. */ 	 
		PROMPT_CREATE             ,/**< EAX << 04; Função para criar um prompt de comando. */
		PROMPT_RESERVED_0         ,/**< EAX << 05; Reservado para uso futuro. */
		PROMPT_RESERVED_1         ,/**< EAX << 06; Reservado para uso futuro. */
		PROMPT_RESERVED_2         ,/**< EAX << 07; Reservado para uso futuro. */
		
		KEYBOARD_READ_KEY         ,/**< EAX << 08; Função para ler caracter do buffer de teclado. */
		KEYBOARD_READ_STRING      ,/**< EAX << 09; Função para ler conjunto de caracteres do teclado. */
		KEYBOARD_GET_INFO         ,/**< EAX << 10; Reservado para uso futuro. */
		KEYBOARD_RESERVED_0       ,/**< EAX << 11; Reservado para uso futuro. */
		KEYBOARD_RESERVED_1       ,/**< EAX << 12; Reservado para uso futuro. */
		
		VIDEO_COPY_AREA           ,/**< EAX << 13; Função para copiar área do vídeo para um buffer. */
		VIDEO_CLEAR_AREA          ,/**< EAX << 14; Função para escrever conteúdo do buffer de vídeo em na tela. */
		VIDEO_PAINT_AREA          ,/**< EAX << 15; Função para pintar um mapa de bits no vídeo. */
		VIDEO_BGCOLOR             ,/**< EAX << 16; Função para pintar o fundo com uma cor sólida. */
		VIDEO_RESET               ,/**< EAX << 17; Função para copiar o buffer principal para o de vídeo. */
		VIDEO_DRAW_RECTANGLE      ,/**< EAX << 18; Função para escrever um retângulo. */
		VIDEO_PAINT_RECTANGLE     ,/**< EAX << 19; Função para pintar área retangular. */
		VIDEO_DRAW_NIF            ,/**< EAX << 20; Função para escrever uma imagem nif na tela. */
		VIDEO_DRAW_NIF2           ,/**< EAX << 21; Função para escrever uma imagem nif na tela. */
		VIDEO_GET_INFO            ,/**< EAX << 22; Função que retorna informações do vídeo. */
		VIDEO_DRAW_BITMAP         ,/**< EAX << 23; Função para pintar um mapa de bits no vídeo. */
		VIDEO_RESERVED_1          ,/**< EAX << 24; Reservado para uso futuro. */
		VIDEO_RESERVED_2          ,/**< EAX << 25; Reservado para uso futuro. */
		
		PANEL_OPEN                ,/**< EAX << 26; Função para inserir um painel na lista de renderização. */
		PANEL_CLOSE               ,/**< EAX << 27; Função para remover o painel da lista de renderização. */
		PANEL_ADD                 ,/**< EAX << 28; Função para inserir um component no painel. */
		PANEL_REMOVE              ,/**< EAX << 29; Função para remover um component do painel. */
		PANEL_DRAW                ,/**< EAX << 30; Função para pintar um painel em modo gráfico. */
		PANEL_DRAW_COMPONENT      ,/**< EAX << 31; Função para pintar um component do painel. */
		PANEL_DRAW_ALL            ,/**< EAX << 32; Função para repintar todos os painéis contidos na lista de renderização. */
		PANEL_GET_INFO            ,/**< EAX << 33; Função que retorna informações do sistema de paineis. */
		PANEL_RESERVED_0          ,/**< EAX << 34; Função para maximizar um painel. */
		PANEL_RESERVED_1          ,/**< EAX << 35; Função para minimizar um painel. */
		
		SCHEDULER_START_PROCESS   ,/**< EAX << 36; Função para iniciar um processo. */
		SCHEDULER_KILL_PROCESS    ,/**< EAX << 37; Função para matar um processo. */
		SCHEDULER_GET_INFO        ,/**< EAX << 38; Função para retornar informaçoes do scheduler. */
		SCHEDULER_RESERVED_0      ,/**< EAX << 39; Reservado para uso futuro. */
		SCHEDULER_RESERVED_1      ,/**< EAX << 40; Reservado para uso futuro. */
		SCHEDULER_RESERVED_2      ,/**< EAX << 41; Reservado para uso futuro. */
		
		STORAGE_ALLOCATE_PAGE     ,/**< EAX << 42; Função para alocar uma página em disco. */
		STORAGE_DEALLOCATE_PAGE   ,/**< EAX << 43; Função para desalocar uma página em disco. */
		STORAGE_GET_INFO          ,/**< EAX << 44; Função para retornar informações dos discos. */
		STORAGE_RESERVED_0        ,/**< EAX << 45; Reservado para uso futuro. */
		STORAGE_RESERVED_1        ,/**< EAX << 46; Reservado para uso futuro. */
		STORAGE_RESERVED_2        ,/**< EAX << 47; Reservado para uso futuro. */
		
		MEMORY_FREE               ,/**< EAX << 48; Função para desalocar memória dinâmica. */
		MEMORY_MALLOC             ,/**< EAX << 49; Função para alocar memória dinâmica. */
		MEMORY_ALLOCATE_PAGE      ,/**< EAX << 50; Função para alocar uma página de memória. */
		MEMORY_DEALLOCATE_PAGE    ,/**< EAX << 51; Função para desalocar uma página de memória. */
		MEMORY_GET_INFO           ,/**< EAX << 52; Função para retornar informações do gerente de memória. */
		MEMORY_RESERVED_0         ,/**< EAX << 53; Reservado para uso futuro. */
		MEMORY_RESERVED_1         ,/**< EAX << 54; Reservado para uso futuro. */
		MEMORY_RESERVED_2         ,/**< EAX << 55; Reservado para uso futuro. */
		
		NFS_OPEN_DATA             ,/**< EAX << 56; Função para abrir um arquivo para leitura. */
		NFS_READ_DATA             ,/**< EAX << 57; Função para ler o próximo bloco de dados do disco. */
		NFS_WRITE_DATA            ,/**< EAX << 58, Função para escrever dados em disco. */
		NFS_CREATE_NODE           ,/**< EAX << 59; Função para criar um arquivo em disco. */
		NFS_DELETE_NODE           ,/**< EAX << 60; Função para deletar um arquivo em disco. */
		NFS_RESERVED_0            ,/**< EAX << 61; Reservado para uso futuro. */
		NFS_RESERVED_1            ,/**< EAX << 62; Reservado para uso futuro. */
		NFS_RESERVED_2            ,/**< EAX << 63; Reservado para uso futuro. */
		
		SYSTEM_REBOOT             ,/**< EAX << 64; Função para resetar o sistema. */
		SYSTEM_GET_INFO           ,/**< EAX << 65; Função para ler informações dos gerentes do sistema. */
		SYSTEM_RESERVED_0         ,/**< EAX << 66; Reservado para uso futuro. */
		SYSTEM_RESERVED_1         ,/**< EAX << 67; Reservado para uso futuro. */
		SYSTEM_RESERVED_2         ,/**< EAX << 68; Reservado para uso futuro. */
		
		CMOS_GET_TIMER            ,/**< EAX << 69; Função que retorna data e hora do sistema. */
		MOUSE_GET_INFO            ,/**< EAX << 70; Função para retornar informações do mouse */
		UTILITIES_RESERVED_0      ,/**< EAX << 71; Reservado para uso futuro. */
		UTILITIES_RESERVED_1      ,/**< EAX << 72; Reservado para uso futuro. */	
	};
	
	/** Lista de chamadas de sistema. A interface de chamadas foi construida em macros para tornar o código mais rápido.  */
	#define SYS_PROMPT_PRINT_CHAR( asciiChar ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "d"(asciiChar), "a"(PROMPT_PRINT_CHAR) : /* --- */);
		
	#define SYS_PROMPT_PRINT_STRING( asciiString ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "D"(asciiString), "a"(PROMPT_PRINT_STRING) : /* --- */);
		
	#define PROMPT_PRINT_INTEGER( number, base, align ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "D"(number),"c"(align),"b"(base),"a"(PROMPT_PRINT_INTEGER) : /* --- */);
		
	#define SYS_PROMPT_CLEAR() \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "a"(PROMPT_CLEAR) : /* --- */);
		
	#define SYS_PROMPT_CREATE( panelPtr, componentPtr ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "D"(panelPtr),"S"(componentPtr),"a"(PROMPT_CREATE) : /* --- */);	
		
	//Keyboard
	#define SYS_KEYBOARD_READ_KEY( result ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n MOV DL,DH\n .att_syntax\n": "=d" (result) : "a"(KEYBOARD_READ_KEY) : /* --- */);
		
	#define SYS_KEYBOARD_READ_STRING( buffer, size, result ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": "=b"(result) : "a"(KEYBOARD_READ_STRING),"D"(buffer),"c"(size) : /* --- */);

	#define SYS_KEYBOARD_GET_INFO( tKeyboardInfo ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "D" (tKeyboardInfo), "a"(KEYBOARD_GET_INFO) : /* --- */); 

	//Vídeo
	#define SYS_VIDEO_BGCOLOR( color ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "d"(color), "a"(VIDEO_BGCOLOR) : /* --- */ );
		
	#define SYS_VIDEO_RESET() \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "a"(VIDEO_RESET) : /* --- */ );
			
	#define SYS_VIDEO_GET_INFO( tVideoInfo ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "D" (tVideoInfo), "a"(VIDEO_GET_INFO) : /* --- */);

	#define SYS_VIDEO_CLEAR_AREA( x, y, w, h ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n PUSH BP\n MOV BP,BX\n INT 0x30\n POP BP\n .att_syntax\n": /* --- */ : "c" (x), "d"(y), "b"(w),"S"(h), "a"(VIDEO_CLEAR_AREA) : /* --- */);
	
	#define SYS_VIDEO_PAINT_RECTANGLE( x, y, w, h, color ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n PUSH BP\n MOV BP,DI\n INT 0x30\n POP BP\n .att_syntax\n": /* --- */ : "c" (x), "d"(y), "D"(w),"S"(h), "b"(color), "a"(VIDEO_PAINT_RECTANGLE) : /* --- */);
	
	#define SYS_VIDEO_DRAW_RECTANGLE( x, y, w, h, color ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n PUSH BP\n MOV BP,DI\n INT 0x30\n POP BP\n .att_syntax\n": /* --- */ : "c" (x), "d"(y), "D"(w),"S"(h), "b"(color), "a"(VIDEO_DRAW_RECTANGLE) : /* --- */);

	#define SYS_VIDEO_DRAW_BITMAP( buffer ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "S"(buffer), "a"(VIDEO_DRAW_BITMAP) :  /* --- */);

		
	//Panel
	#define SYS_PANEL_OPEN( tPanel ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "D"(tPanel), "a"(PANEL_OPEN) :  /* --- */);

	#define SYS_PANEL_CLOSE( tPanel ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "D"(tPanel), "a"(PANEL_CLOSE) : /* --- */);		
		
	#define SYS_PANEL_ADD( tPanel, tComponent ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "D"(tPanel), "S"(tComponent), "a"(PANEL_ADD) : /* --- */ );
	
	#define SYS_PANEL_REMOVE( tPanel, tComponent ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "D"(tPanel), "S"(tComponent), "a"(PANEL_REMOVE) : /* --- */ );

	#define SYS_PANEL_DRAW( tPanel ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "D"(tPanel), "a"(PANEL_DRAW) : /* --- */);		
		
	#define SYS_PANEL_DRAW_COMPONENT( tPanel, tComponent ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "S"(tPanel), "D"(tComponent), "a"(PANEL_DRAW_COMPONENT) : /* --- */);
	
	#define SYS_PANEL_DRAW_ALL() \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "a"(PANEL_DRAW_ALL) : /* --- */);

	#define SYS_PANEL_GET_INFO( tPanelInfo ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "D" (tPanelInfo), "a"(PANEL_GET_INFO) : /* --- */); 

	//Scheduler
	#define SYS_SCHEDULER_PROCESS_SLEEP() \
		__asm__ __volatile__ (".intel_syntax noprefix\n CLI\n INT 0x20\n STI\n .att_syntax\n": /* --- */ : /* --- */ : /* --- */ );	

	#define SYS_SCHEDULER_START_PROCESS( pathPtr ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n" : /* --- */ : "S"(pathPtr), "a"(SCHEDULER_START_PROCESS) : /* --- */);

	#define SYS_SCHEDULER_KILL_PROCESS( processId ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "D"(processId),"a"(SCHEDULER_KILL_PROCESS) : /* --- */);

	#define SYS_SCHEDULER_GET_INFO( result ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": "=D" (result) : "a"(SCHEDULER_GET_INFO) :  /* --- */ );
		
	//Memory
	#define SYS_MEMORY_FREE( buffer ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n" : /* --- */ : "D"(buffer), "a"(MEMORY_FREE) : /* --- */);
		
	#define SYS_MEMORY_MALLOC( result, size ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n" : "=D"(result) : "c"(size), "a"(MEMORY_MALLOC) : /* --- */);	
		
	#define SYS_MEMORY_ALLOCATE_PAGE( result, size ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": "=D" (result) : "c"(size), "a"(MEMORY_ALLOCATE_PAGE) : /* --- */);	

	#define SYS_MEMORY_DEALLOCATE_PAGE( buffer, size ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "c"(size), "D"(buffer), "a"(MEMORY_DEALLOCATE_PAGE) : /* --- */);		
		
	#define SYS_MEMORY_GET_INFO( tMemoryInfo ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "D" (tMemoryInfo), "a"(MEMORY_GET_INFO) : /* --- */);

	//Storage
	#define SYS_STORAGE_GET_INFO( tStorageInfo ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "D" (tStorageInfo), "a"(STORAGE_GET_INFO) : /* --- */);

	#define SYS_STORAGE_ALLOCATE_PAGE( drive, size, result ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": "=b" (result) : "a"(STORAGE_ALLOCATE_PAGE), "c"(size), "d"(drive)  : /* --- */);
	
	#define SYS_STORAGE_DEALLOCATE_PAGE(  drive, page, size ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "b"(page), "d"(drive), "c"(size), "a"(STORAGE_DEALLOCATE_PAGE) : /* --- */);
	
	//NFS
	#define SYS_NFS_OPEN_DATA( fc, path ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": "=D" (fc) : "S"(path), "a"(NFS_OPEN_DATA) : /* --- */);

	#define SYS_NFS_READ_DATA( fc ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n":/* --- */: "D"(fc), "a"(NFS_READ_DATA) : /* --- */);

	#define SYS_NFS_WRITE_DATA( fc ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n":/* --- */: "D"(fc), "a"(NFS_WRITE_DATA) : /* --- */);
		
	#define SYS_NFS_CREATE_NODE( fc, path, name, size, type ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": "=b" (fc): "S"(path), "D"(name), "c"(size), "d"(type),  "a"(NFS_CREATE_NODE) : /* --- */);
	
	//System
	#define SYS_SYSTEM_REBOOT() \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "a"(SYSTEM_REBOOT) : /* --- */);

	#define SYS_SYSTEM_GET_INFO( tSysInfo ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "D" (tSysInfo),"a"(SYSTEM_GET_INFO) : /* --- */);	
	
	#define SYS_CMOS_GET_TIMER( tTimerFormat ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "D" (tTimerFormat), "a"(CMOS_GET_TIMER) : /* --- */); 
	
	#define SYS_MOUSE_GET_INFO( tMouseInfo ) \
		__asm__ __volatile__ (".intel_syntax noprefix\n INT 0x30\n .att_syntax\n": /* --- */ : "D" (tMouseInfo), "a"(MOUSE_GET_INFO) : /* --- */); 
}

#endif
