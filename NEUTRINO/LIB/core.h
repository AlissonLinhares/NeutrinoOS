/*---------------------------------------------------------------------------*
 * Copyright (C) 2011-2012 Alisson Linhares de Carvalho.                     *
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

#ifndef CORE_H
#define CORE_H

#define START_PROG_PTR 4096
#define VERSION 0.04

#include <syscalls.h>
//#include <object.h>

/** Tipo definido para os tratadores de evento. */
typedef void (tListener)(void);

/** 
 * Sobrecarga do operador new para que os programas possam trabalhar com o gerente de memória de aplicação. 
 * Ex.: int *x = new int();
 * @param nBytes Total de bytes que serão alocados.
 */
inline void* operator new( const unsigned int nBytes ) {
	using namespace nlib;
	void* result;
	
	do {
		SYS_MEMORY_MALLOC( result, nBytes)
	} while( result == 0 ); //Verifica se foi possível alocar memória.
	
	return result;
}

/** 
 * Sobrecarga do operador new[] para que os programas possam trabalhar com o gerente de memória de aplicação. 
 * Ex.: int *x = new int[10];
 * @param nBytes Total de bytes que serão alocados.
 */
inline void* operator new[]( const unsigned int nBytes) {
	using namespace nlib;
	void* result;
	
	do {
		SYS_MEMORY_MALLOC( result, nBytes)
	} while( result == 0 ); //Verifica se foi possível alocar memória.
	
	return result;
}

/** 
 * Sobrecarga do operador delete para que os programas possam trabalhar com o gerente de memória de aplicação.
 * @param buffer Ponteiro para o buffer que será desalocado.
 */
inline void operator delete( void *buffer ) {
	using namespace nlib;
	SYS_MEMORY_FREE( buffer )
}

/** 
 * Sobrecarga do operador delete[] para que os programas possam trabalhar com o gerente de memória de aplicação. 
 * @param buffer Ponteiro para o buffer que será desalocado.
 */
inline void operator delete[]( void *buffer ) { 
	using namespace nlib;
	SYS_MEMORY_FREE( buffer )
}

/** Procedimento de backup para o caso de uma chamada para funções virtuais puras não definidas. */
extern "C" void __cxa_pure_virtual() {
	using namespace nlib;
	SYS_SCHEDULER_KILL_PROCESS(0) //Matando o processo atual
}

#endif