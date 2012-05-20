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

#ifndef CONSOLE_H
#define CONSOLE_H

#include "prompt.h"
#include "panel.h"
#include "string.h"

#define CONSOLE_DEFAULT_NAME "Console\0"
#define CONSOLE_DEFAULT_INPUT_BUFFER 78

namespace nlib {

	/**
	 * Console é um tipo de painel projetado para simular o modo texto 80x40. Essa classe deve ser usada por programas
	 * que necessitem executar em modo texto.
	 * @remarks É recomendável o uso das funções fornecidas pela interface gráfica básica do Kernel. Essas funções são 
	 * projetadas para tornar os programas mais suscetíveis a evoluções do núcleo. Programas que utilizam a GUI padrão
	 * ocupam menos espaço em memória se comparado com alternativas construídas por terceiros.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	class Console : public Prompt {
	public:
		/** 
		 * Construtor responsável por configurar o console padrão do sitema. O kernel é responsavel por criar e gerenciar
		 * esse componente.
		 * @param x - Posição X do console.
		 * @param y - Posição Y do console.
		 * @param name - Nome que será inserido na barra do console.
		 *************************************************************************************************************/
		Console( unsigned short x = PANEL_DEFAULT_X, unsigned short y = PANEL_DEFAULT_Y, const char* name = CONSOLE_DEFAULT_NAME ) 
			: panel( x, y, 80 * 7 + 4, 27 * 13 - 8, name), Prompt( 2, 16 ) {

			SYS_PROMPT_CREATE( panel.getReference(), getReference() )
		}
		
		/**
		 * Método projetado para escrever uma string ASCII no console. Ex.: var->print( string ); 
		 * @param s - Objeto string que contém o texto que será escrito no console.
		 */
		inline void print( const String &s ) const {
			SYS_PROMPT_PRINT_STRING( s.toCharArray() )
		}
		
		/**
		 * Método projetado para escrever uma string ASCII no console. Ex.: var->print( "NLIB\0" ); 
		 * @param s - Texto que será escrito no console.
		 */
		inline void print( const char *s ) const {
			SYS_PROMPT_PRINT_STRING( s )
		}

		/** 
		 * Método projetado para escrever um símbolo ASCII no console. 
		 * @param c - Símbolo que será escrito no console.
		 */
		inline void print( const char c ) const {
			SYS_PROMPT_PRINT_CHAR( c )
		}
		
		/**
		 * Método projetado para escrever um unsigned char no console. 
		 * @remarks Esse método pode escrever em outras bases numéricas. Ex.: var->print( 8, 2 ); //"1000".
		 * @param c - Valor que será escrito no console.
		 * @param base - Base numérica que será escrito o valor.
		 * @param align - Alinhamento do texto.
		 */
		inline void print( const unsigned char c, const unsigned char base = 10, const unsigned char align = 0 ) const {
			print( (unsigned int) c, base, align ); //Chamando a função que escreve valores inteiros positivos.
		}
		
		/**
		 * Método projetado para escrever um signed short no console. 
		 * @remarks Esse método pode escrever em outras bases numéricas. Ex.: var->print( 8, 2 ); //"1000".
		 * @param s - Valor que será escrito no console.
		 * @param base - Base numérica que será escrito o valor.
		 * @param align - Alinhamento do texto.
		 */
		inline void print( const signed short s, const unsigned char base = 10, const unsigned char align = 0 ) const {
			print( (signed int) s, base, align ); //Chamando a função que escreve valores inteiros negativos.			
		}
		
		/**
		 * Método projetado para escrever um unsigned short no console. 
		 * @remarks Esse método pode escrever em outras bases numéricas.  Ex.: var->print( 8, 2 ); //"1000".
		 * @param s - Valor que será escrito no console.
		 * @param base - Base numérica que será escrito o valor.
		 * @param align - Alinhamento do texto.
		 */
		inline void print( const unsigned short s, const unsigned char base = 10, const unsigned char align = 0 ) const {
			print( (unsigned int) s, base, align ); //Chamando a função que escreve valores inteiros positivos.
		}
		
		/** 
		 * Método projetado para escrever um signed int no console. 
		 * @remarks Esse método pode escrever em outras bases numéricas.  Ex.: var->print( 8, 2 ); //"1000".
		 * @param value - Valor que será escrito no console.
		 * @param base - Base numérica que será escrito o valor.
		 * @param align - Alinhamento do texto.
		 */
		inline void print( const signed int value, const unsigned char base = 10, const unsigned char align = 0 ) const {
			if( value < 0 ) { //Verifica se o numero é negativo ou positivo
				print('-');
				print( (unsigned int) -value, base, align );
			} else
				print( (unsigned int) value, base, align );
		}
		
		/** 
		 * Método projetado para escrever um unsigned int no console. 
		 * @remarks Esse método pode escrever em outras bases numéricas.  Ex.: var->print( 8, 2 ); //"1000".
		 * @param value - Valor que será escrito no console.
		 * @param base - Base numérica que será escrito o valor.
		 * @param align - Alinhamento do texto.
		 */
		inline void print( const unsigned int value, const unsigned char base = 10, const unsigned char align = 0 ) const {
			PROMPT_PRINT_INTEGER( value, base, align )
		}

		/** Método projetado para limpar o buffer do console. */
		inline void clear() const {
			SYS_PROMPT_CLEAR()
		}

		/** 
		 * Método projetado para ler uma string do console. Ex.: var->read( buffer);	
		 * @param str - Variável que receberá o texto do console.
		 */		
		inline void read( String &str ) const {
			//String é friend de Console.
			SYS_KEYBOARD_READ_STRING( str.getBufferPtr(), str.capacity() , str.strLength )
			
			//Reseta a string manualmente.
			str.strPtr = str.strBuffer;
		}
		
		/** Método projetado para ler uma tecla do buffer de teclado. */
		char readkey() const {
			char key;
			SYS_KEYBOARD_READ_KEY( key )
			return key;
		}

		/** 
		 * Método projetado para atualizar as alteraçoes feitas no buffer. O console acumula as alterações até que uma
		 * requisição de entrada de dados seja efetuada. Para forçar uma atualização podemos usar esse método. 
		 */
		void update() const {
			SYS_PANEL_DRAW_COMPONENT( panel.getReference(), getReference()  )
		}

		/** Método projetado para pausar o console. */
		void pause() const {
			print("\n<Pressione qualquer tecla para continuar>\n\0");
			update();
			readkey();
		}

	private:
		Panel panel; /**< Janela usada para controlar o terminal em modo gráfico. */
	};
}

#endif