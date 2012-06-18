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

#ifndef ARRAY_H
#define ARRAY_H

#define ARRAY_DEFAULT_CAPACITY 10

#include <core.h>
#include <error.h>

namespace nlib {

	/**
	 * Classe responsável por gerenciar uma estrutura de dados do tipo array.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	template <class T>
	class Array {
	public:
		/**
		 * Construtor projetado para alocar um espaço de memória para um array.
		 * @param capacity - Número máximo de elementos do buffer.
		 */
		Array( const unsigned int capacity = ARRAY_DEFAULT_CAPACITY ) : capacity( capacity ) {
			if( capacity > 0 )
				buffer = new T[capacity];
			else
				buffer = 0;
		}

		/** Sobrecarga do operador[], para possibilitar a escrita e leitura de um elemento em um array. */
		inline T &operator[]( const unsigned int position ) {
			if( position >= capacity )
				Error::notify( Error::INDEX_OUT_OF_BOUNDS_EXCEPTION );

			return this->buffer[position];
		}
		
		/** Método projetado para retornar o tamanho do array (Capacidade). */
		inline const unsigned int length() const {
			return this->capacity;
		}

		/** Método projetado para verificar se o vector está vazio. */
		inline bool isEmpty() const {
			return this->capacity == 0;
		}
	
		/** Método projetado para redimensionar o vetor. */
		void resize( const unsigned short capacityIncrement ) {
			if( capacityIncrement > 0 ) {
				int size = capacity;
				capacity += capacityIncrement;
				
				//Alocando uma novo área de memória para o vetor.
				T *newBuffer = new T[capacity];
				
				//Copiando o conteúdo do primeiro buffer para o novo.
				while( --size >= 0 )
					newBuffer[size] = buffer[size];

				//Reconfigurando os ponteiros.
				if( buffer != 0 )
					delete[] buffer;

				buffer = newBuffer;
			}
		}
		
		/**
		 * Método projetado para ordenar os elementos do array. 
		 * @remarks O método de ordenação usado é o quicksort.
		 */
		inline void sort() {
			quicksort( 0, capacity - 1 );
		}
		
		/**
		 * Método projetado para ordenar os elementos de uma área do array.
		 * @remarks O método de ordenação usado é o quicksort.
		 * @param begin Índice para o inicio da área que será ordenada.
		 * @param end Índice para o final da área que será ordenada.
		 */
		inline void sort( const unsigned short begin, const unsigned short end ) {
			if( end < capacity && begin < end ) //Verifica se entrada é válida.
				quicksort( begin, end );
		}

		/** Destrutor padrão: responsável por desalocar o buffer usador pelo array. */
		~Array() {
			if( capacity > 0 && buffer != 0 ) {
				delete[] buffer;
				buffer = 0; //Segurança adicional.
			}
		}
		
	private:
		unsigned int capacity; /**< Tamanho máximo do array. */
		T* buffer; /**< Ponteiro para uma área de dados em memória. */
		
	
 		//Usando 2 variáveis globais: Otimização para tornar o quick sort mais veloz e reduzir o consumo de pilha.
		T quicksort_pivot; 
		T quicksort_aux;
		
		/** 
		 * Implementação do quicksort. Foi adaptado para trabalhar exclusivamente com a classe array.
		 * @param begin - Início do array.
		 * @param end - Final do array.
		 */
		void quicksort( const unsigned short begin, const unsigned short end ) {
			//Variáveis auxiliares.
			short i = begin;
			short j = end;
			quicksort_pivot = buffer[(begin + end) >> 1]; //Marcando o meio do array.
			
			do {
				for( ;buffer[i] < quicksort_pivot; i++ ); //Procurando por um elemento menor que o pivô.
				for( ;buffer[j] > quicksort_pivot; j-- ); //Procurando por um elemento maior que o pivô.
				
				//Troca os elementos encontrados.
				if( i <= j ) {
					quicksort_aux = buffer[i];
					buffer[i] = buffer[j];
					buffer[j] = quicksort_aux;

					i++;
					j--;
				}
			} while ( i < j );
			
			if ( j > begin ) 
				quicksort( begin, j ); //Ordenana o array da esquerda.

			if ( i < end )
				quicksort( i, end ); //Ordenana o array da direita.
		}
	};
}

#endif