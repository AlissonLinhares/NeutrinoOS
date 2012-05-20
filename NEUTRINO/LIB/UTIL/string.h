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

#ifndef STRING_H
#define STRING_H

#include <core.h>

namespace nlib {

	/** 
	* Função para comparar duas strings.
	* @param str1 - Ponteiro para a primeira string.
	* @param str2 - Ponteiro para a segunda string.
	*/
	inline char strcmp( const char *str1, const char *str2 ) { //@todo Mover o procedimento "strcmp" para classe string.
		//Comparando as 2 strings
	    for(;*str1 == *str2 && *str2 != 0; str1++, str2++);

		//Retornando valor positivo se 	str1 > str2, negativos se str1 < str2 e 0 se str1 == str2.
	    return *(unsigned char *)str1 - *(unsigned char *)str2;
	} 
  

	/**
	 * Classe responsável por oferecer recursos básicos para o gerenciamento de strings em C++.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	class String {
		friend class Console; //Usando friend para tornar o código de leitura de strings mais rápido.	
	public:
		/**
		 * Construtor padrão. Projetado para alocar um espaço de memória para a string.
		 * @param capacity - Capacidade do buffer "em bytes".
		 */
		String( const unsigned int capacity = 0 ) : strCapacity(capacity), strLength(0), strPtr(0) {
			if( capacity > 0 )
				strBuffer = new char[capacity];
			else
				strBuffer = 0;
		}
		
		/**
		 * Construtor projetado para inicializar o objeto com um vetor de caracteres.
		 * @param str - Ponteiro para um vertor de caracteres.
		 */
		inline String( const char* str ) : strCapacity(0) {
			setStr(str, calcSize(str));
		}

		/**
		 * Construtor projetado para inicializar o objeto com uma outra String.
		 * @param str - Ponteiro para uma string.
		 */
		inline String( const String &str ) : strCapacity(0) {
			setStr(str.toCharArray(), str.length());
		}			
		
		/** Sobrecarga do operador '='. Copia o conteúdo de um vetor de caracteres. */
		inline const String &operator=( const char* str ) {
			setStr(str, calcSize(str));
		}
		
		/** Sobrecarga do operador '='. Copia o conteúdo de um objeto String. */
		inline const String &operator=( const String &str ) {
			setStr(str.toCharArray(), str.length());
		}
		
		/** Sobrecarga do operador '[]'. Escreve ou lê em uma posição da string. */
		inline char &operator[]( const unsigned int position ) {
			if( position < this->strLength )
				return this->strPtr[position];
				
			return this->strPtr[position % this->strLength]; //Evitando a violação de endereço.
		}
		
		/** Sobrecarga do operador '=='. Compara se duas strings são iguais. */
		inline const bool operator==( const String& str ) const {
			return equals(str.toCharArray()) == 0;
		}
		
		/** Sobrecarga do operador '!='. Compara se duas strings são diferentes. */
		inline const bool operator!=( const String& str ) const {
			return equals(str.toCharArray()) != 0;
		}
		
		/** Sobrecarga do operador '<'. Compara se uma string é menor que outra. */
		inline const bool operator<( const String& str ) const {
			return equals(str.toCharArray()) < 0;
		}

		/** Sobrecarga do operador '>'. Compara se uma string é maior que outra. */
		inline const bool operator>( const String& str ) const {
			return equals(str.toCharArray()) > 0;
		}

		/** Sobrecarga do operador '<='. Compara se uma string é menor ou igual a outra. */
		inline const bool operator<=( const String& str ) const {
			return equals(str.toCharArray()) <= 0;
		}

		/** Sobrecarga do operador '>='. Compara se uma string é maior ou igual a outra. */
		inline const bool operator>=( const String& str ) const {
			return equals(str.toCharArray()) >= 0;
		}	
		
		/** Método projetado para retornar o ponteiro para o buffer da string. */
		inline const char* getBufferPtr() const {
			return this->strBuffer;
		}	
		
		/** Método projetado para retornar o vetor de caracteres. */
		inline const char* toCharArray() const {
			return this->strPtr;
		}		
		
		/** Método projetado para retornar o total de letras da string. */
		inline const unsigned int length() const {
			return this->strLength;
		}

		/** Método projetado para retornar o tamanho do buffer usado pela string. */
		inline const unsigned int capacity() const {
			return this->strCapacity;
		}
				
		/** Método projetado para verificar se uma string está vazia. */
		inline bool isEmpty() const {
			return this->strLength == 0;
		}
		
		/** Método projetado pora limpar o buffer de caracteres. */
		void clear() {
			unsigned int i;
			for( i = 0; i < this->strCapacity - 1; this->strBuffer[i++] = 0 );	
			
			this->strLength = 0;	
			this->strPtr = 0;
		}

		/** 
		 * Método projetado para quebrar a string atual em 2 partes.
		 * @param separator - Letra de separação.
		 * @return String - Ponteiro para a string formada pelos caracteres posteriores ao separador.
		 */
		const char* split( const char separator ) {
			char *tempStr = (char*) find(separator); 
			const char* result = this->strPtr;
			
			if( tempStr != 0 ) {
 				//Marcando o final da string que será retornada
				*tempStr++ = 0;
				
				this->strLength -= tempStr - this->strPtr;
				this->strPtr = tempStr;
			} else {
				this->strPtr = 0;
				this->strLength = 0;
			}

			return result; 
		}

		/**
		 * Método projetado para procurar um caracter em uma string.
		 * @param value - Letra que será procurada.
		 * @return Ponteiro - Para o vetor de caracteres antes da letra procurada.
		 */
		const char* find( const char value ) {
			if( this->strPtr != 0 && this->strLength > 0 ) {
				const char *strAux;
				
				//Procurando pelo separador
				for( strAux = this->strPtr; *strAux != value; strAux++ ) {
					if( *strAux == 0 )
						return 0;
				}

				return strAux;
			}

			return 0;
		}

		/** Método projetado para remover espaços das extremidades de uma string. */
		void trim() {
			if( this->strPtr != 0 && this->strLength > 0 ) {
				char *tempStr = (this->strPtr + this->strLength - 1);

				//Removendo espaços do final.
				for( ; *tempStr == ' ' && tempStr > this->strPtr; *tempStr-- = 0 );

				//Removendo espaços da frente.
				for( ; *this->strPtr == ' '; this->strPtr++ );

				//Calculando o tamanho da string.
				this->strLength = tempStr - this->strPtr + 1;
			}
		}
		
		/** 
		 * Método projetado para comparar a string atual com um vetor de caracteres.
		 * @remarks 0 se igual, -[1..127] se menor e +[1..127] se maior.
		 * @param str - Ponteiro para um vetor de caracteres.
		 */
		const char equals( const char *str ) const {
			//Verifica se os dois ponteiros estão apontando para o mesmo lugar.
			if( this->strPtr != str )
				return strcmp( this->strPtr, str );
			
			return 0;
		}
		
		/** 
		 * Sobrecarga do método equals. Projetado para comparar a string atual com uma outra.
		 * @remarks 0 se igual, -[1..127] se menor e +[1..127] se maior.
		 * @param str - Ponteiro para a string que será comparada.
		 */
		inline const char equals( const String &str ) const {
			return equals( str.toCharArray() );	
		}
		
		/**
		 * Método que retorna a representação em string de um boolean.
		 * @param value - Constante booleana.
		 */
		inline static const char* valueOf( const bool value ) {
			if (value)
				return "true\0";
			
			return "false\0";
		}
		
		/** Construtor padrão. Usado para desalocar a memória usada pelo objeto string. */
		~String() {
			if( strCapacity > 0 )
				delete[] strBuffer;
		}
		
	protected:
		/**
		 * Método projetado para calcular o tamanho de uma string. Retorna o total de letras.
		 * @param str - Ponteiro para um vertor de caracteres.
		 */
		unsigned int calcSize( const char* str ) {
			if ( str != 0 ) {
				//Salvando o endereço inicial da string.
				unsigned int ptrAux = (unsigned int)&(*str);

				//Procurando pelo final da string.
				for( ; *str != 0; str++ );

				//Retornando o tamanho.
				return (unsigned int)&(*str) - ptrAux;
			}

			return 0;
		}
		
		/**
		 * Método projetado para mover os dados de um vetor de caracteres para o buffer da string.
		 * @param str - Ponteiro para um vertor de caracteres.
		 * @param length - Tamanho da string.
		 */
		void setStr( const char* str, const unsigned int length ) {

			if( str != 0 ) { 	
				//Verifica se existe espaço em memória para os dados.
				if( strCapacity <= length ) {
					if( strCapacity != 0 )
						delete[] strBuffer;
					
					strCapacity = length + 1;
				
					//Alocando memória para a string.
					strBuffer = new char[strCapacity];
				}
				
				int i;	
				for( i = 0; i <= length; i++ )
					strBuffer[i] = str[i]; //Copiando dados para a memória alocada.
	
				strLength = length;
			} else {
				strLength = 0;
			}
			
			strPtr = strBuffer;
		}

	private:
		char *strPtr;
		char *strBuffer;
		unsigned int strLength;
		unsigned int strCapacity;
	};
}

#endif
