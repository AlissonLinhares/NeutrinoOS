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

#ifndef VECTOR_H
#define VECTOR_H

#define VECTOR_CAPACITY_INCREMENT 10

#include <core.h>
#include <error.h>

namespace nlib {

	/**
	 * Classe responsável por gerenciar uma estrutura de dados do tipo vetor.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	template <class T>
	class Vector {
	public:
		/**
		 * Construtor projetado para alocar um espaço de memória para o vetor e configurar o total de bytes alocados a cada incremento.
		 * @param capacity - Número máximo de elementos do buffer.
		 * @param capacityIncrement - Espaço aumentado a cada incremento.
		 **/
		Vector( const unsigned int capacity = VECTOR_CAPACITY_INCREMENT, const unsigned short capacityIncrement = VECTOR_CAPACITY_INCREMENT ) : 
			capacityIncrement(capacityIncrement), capacity(capacity), size(0), begin(0) {
				
			if( capacity > 0 ) {
				buffer = new T[capacity];
				end = capacity - 1;
			} else {
				buffer = 0;
			}
		}

		/**
		 * Sobrecarga do operador[]. Possibilitar a escrita e leitura de elementos no vetor. 
		 * @remarks O tempo de leitura e escrita direta é custoso.
		 * @param position Posição do elemento no vetor.
		 */
		T &operator[]( const unsigned int position ) {	
			int index;
			
			//Verifica se a posição é válida.
			if( position >= size )
				Error::notify( Error::INDEX_OUT_OF_BOUNDS_EXCEPTION );

			//Calculando a posição no array.
			index = begin - 1 - position;

			if( index < 0 )
				return this->buffer[this->capacity + index];

			return this->buffer[index];
		}

		/** Método projetado para retornar o tamanho do vector. */
		inline const unsigned int length() const {
			return this->size;
		}

		/** Método projetado para verificar se o vector está vazio. */
		inline bool isEmpty() const {
			return this->size == 0;
		}
		
		/** 
		 * Método projetado adicionar um elemento no topo do buffer.
		 * @param value - Valor que será inserido no buffer.
		 */
		void push_back( const T &value ) {
			if( size >= capacity || buffer == 0 )
				resize(); //Alocando mais memória para o buffer.
			
			//Inserindo elemento no buffer.
			buffer[end] = value;

			//Verifica se deve resetar a inserção. "Obs: Os operadores % e \ consomem muitos ciclos de clock."
			if( end <= 0 )
				end = capacity - 1;
			else
				end--;

			size++;
		} 
		
		/** Método projetado para remover um elemento do topo do buffer. */
		const T pop_back() {
			//Verifica se pode remover um item.
			if( size <= 0 )
				Error::notify( Error::INDEX_OUT_OF_BOUNDS_EXCEPTION );
			
			size--;
			
			//Removendo elemento do buffer.
			if( end >= capacity - 1 )
				end = 0;
			else
				end++;

			return buffer[end];
		}
		
		/** 
		 * Método projetado adicionar um elemento no inicio do buffer.
		 * @param value - Valor que será inserido no buffer.
		 */
		void push_front( const T &value ) {
			if( size >= capacity || buffer == 0 )
				resize(); //Alocando mais memória para o buffer.
			
			//Inserindo elemento no buffer.
			buffer[begin] = value;
			
			//Verifica se deve resetar a inserção. "Obs: Os operadores % e \ consomem muitos ciclos de clock."
			if( begin >= capacity - 1 )
				begin = 0;
			else
				begin++;

			size++;
		}

		/** Método projetado para remover um elemento do inicio do buffer. */
		const T pop_front() {
			//Verifica se pode remover um item.
			if( size <= 0 )
				Error::notify( Error::INDEX_OUT_OF_BOUNDS_EXCEPTION );
				
			size--;
			
			//Removendo elemento do buffer.
			if( begin <= 0 )
				begin = capacity - 1;
			else
				begin--;

			return buffer[begin];
		}

		/** Destrutor padrão: responsável por desalocar o buffer usado pelo vetor. */
		~Vector() {
			if( capacity > 0 && buffer != 0 ) {
				delete[] buffer;
				buffer = 0; //Segurança adicional.
			}	
		}

	protected:
		/** Método projetado para redimensionar e reorganizar o vetor. */
		void resize() {
			int i;
			int maxSize = size - 1;
			
			//Alocando uma novo área de memória para o vetor.
			capacity += capacityIncrement + 1; //capacityIncrement não pode ser 0.
			T *newBuffer = new T[capacity];
			
			//Copiando o conteúdo do primeiro buffer para o novo.
			for( i = 0; i < size; i++ ) {
				if( end >= maxSize )
					end = 0;
				else
					end++;
					
				newBuffer[i] = buffer[end];
			}

			//Reconfigurando os ponteiros.
			if( buffer != 0 )
				delete[] buffer;

			buffer = newBuffer;
			begin = size;
			end = capacity - 1;
		}

	private:
		int begin; /**< Índice para o inicio do vetor. */
		int end;   /**< Índice para o fim do vetor. */
		
		unsigned int size;     /**< Total de elementos contidos no vetor. */
		unsigned int capacity; /**< Tamanho máximo do vetor. */
		const unsigned short capacityIncrement; /**< Tamanho do incremento para o vetor. */
		
		T* buffer; /**< Ponteiro para uma área de dados em memória. */
	};
}

#endif