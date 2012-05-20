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

#ifndef MEMORY_H
#define MEMORY_H

#define MEMORY_SIGNATURE 0x89ABCDEF

#include <core.h>

namespace nlib {

	/** 
	 * Registro usado para compartilhar informações entre o Kernel Neutrino e a NLIB. Foi projetado para retornar 
	 * informações do sistema de gerenciamento de memória.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	struct tMemoryInfo {
		const unsigned int signature;
		unsigned int usage;
		unsigned int size;
		
		/** Construtor responsável por inicializar o registro de troca. */
		tMemoryInfo() : signature( MEMORY_SIGNATURE ) {
		
		}
	} __attribute__((__packed__));


	/** 
	 * Classe responsável por controlar as função básicas de gerenciamento de memória.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	class Memory {
	public:
		/**
		 * Método projetado para alocar uma sequência de bytes usando o gerente de memária de aplicação. Ex.: int *x = (int *) Memory.malloc(sizeof(int));
		 * @remarks É recomendável o uso do comando new no lugar do malloc. O malloc pode gerar erros fatais caso não seja corretamente utilizado.
		 * @param size - Total de bytes que será alocado.
		 * @return Ponteiro para o inicio da memária alocada ou 0 em caso de falha.
		 */
		static inline void* malloc( const unsigned int size ) {
			void* result;
			SYS_MEMORY_MALLOC( result, size )
			return result;
		}
		
		/**
		 * Método projetado para liberar a memória alocada pelo malloc.
		 * @remarks É recomendável o uso do comando delete no lugar do free. O free pode gerar erros fatais caso não seja corretamente utilizado.
		 * @param buffer - Ponteiro para a memória que será desalocada.
		 */
		static inline void free( void* buffer ) {
			SYS_MEMORY_FREE( buffer )
		}

		/**
		 * Método projetado para inicializar um bloco de bytes com um valor padrão.
		 * @param buffer - Ponteiro para a área de memória que receberá os valores.
		 * @param value - Valor que será inserido em todas as posições da memória.
		 * @param count - Total de bytes de memória.
		 */
		static inline void memset( void* buffer, const char value, int count ) {
			for( ; count > 0; ((char*)buffer)[--count] = value );
		}
		
		/**
		 * Método projetado para copiar o conteúdo de uma área de memória para outra.
		 * @param dest - Ponteiro para a área de memória que receberá os dados.
		 * @param src - Ponteiro para a área de memória que possui os dados.
		 * @param count - Total de bytes.
		 */
		static inline void memcpy( void* dest, void* src, int count ) {
			for( ; count > 0; --count, ((char*)dest)[count] = ((char*)src)[count]);
		}
		
		/**
		 * Método projetado para alocar blocos de páginas para programas.
		 * @remarks Para acessar os blocos de memória é necessário alterar os registradores de segmento para trabalhar em modo kernel.
		 * @param size - Total de páginas que serão alocadas.
		 */
		static inline const void* allocate( const unsigned int size ) {
			const void* result;
			SYS_MEMORY_ALLOCATE_PAGE( result, size )
			return result;
		}
		
		/**
		 * Método projetado para liberar a memória alocada pelo allocate.
		 * @remarks O uso incorreto desta função pode gerar falhas fatais.
		 * @param buffer - Ponteiro para a memoria que será desalocada.
		 * @param size - Total de páginas que serão desalocadas.
		 */
		static inline void deallocate( const void* buffer, const unsigned int size ) {
			SYS_MEMORY_DEALLOCATE_PAGE( buffer, size )
		}
		
		/** Método projetado para retornar informações relativas ao gerente de memória. */
		static inline tMemoryInfo getInfo() {
			tMemoryInfo info;
			SYS_MEMORY_GET_INFO( &info )
			return info;
		}
	};
}

#endif