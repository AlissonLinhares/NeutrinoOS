/*---------------------------------------------------------------------------* //385
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

#ifndef PROMPT_H
#define PROMPT_H

#define PROMPT_WIDTH 80
#define PROMPT_HEIGHT 25
#define PROMPT_CHAR_HEIGHT 13
#define PROMPT_CHAR_WIDTH 7 
#define PROMPT_DEFAULT_COLOR 0x8F

#include "component.h"

namespace nlib {
	
	/**
	 * Prompt é uma caixa de texto projetada para escrever caracteres ASCII em modo gráfico. Foi projetado para trabalha 
	 * com a classe Console da NLIB.
	 * @remarks É recomendável o uso deste componente em programas que necessitem escrever textos de debug durante a execução.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	class Prompt : public Component {
	public:
		/**
		 * Cores suportadas pelo modo texto. 
		 * @remarks No modo texto o computador utiliza 1byte para representar a letra e outro para a cor. 
		 */
		enum tColor { 
			BLACK,
			DARKBLUE,
			DARKGREEN,
			DARKCYAN,
			DARKRED,
			DARKMAGENTA,
			DARKYELLOW,
			LIGHTGREY,
			DARKGREY,
			BLUE,
			GREEN,
			CYAN,
			RED,
			MAGENTA,
			YELLOW,
			WHITE
		};
		
		/** 
		 * Construtor projetado para inicializar um prompt.
		 * @param x - Posição X do prompt.
		 * @param y - Posição Y do prompt.
		 * @param width - Largura do prompt.
		 * @param height - Altura do prompt.
		 */
		Prompt( const unsigned short x = COMPONENT_DEFAULT_X, const unsigned short y = COMPONENT_DEFAULT_Y, const unsigned short width = PROMPT_CHAR_WIDTH * PROMPT_WIDTH,
			const unsigned short height = PROMPT_CHAR_HEIGHT * PROMPT_HEIGHT ) : prompt( x, y, width, height ) {
		}
		
		/** Método projetado para limpar o buffer do prompt. */
		void clear() {
			unsigned int pos;
			tDataFormat data;
			
			//Criando um registro vazio
			data.value = ' ';
			data.color = prompt.color;
			
			//Limpando o vídeo do prompt.
			for( pos = 0; pos < PROMPT_WIDTH * PROMPT_HEIGHT; pos++ ) 
				prompt.bufferPtr[pos] = data;
			
			//Resetando a posição do prompt.
			prompt.position = 0;
		}

		/** 
		 * Método projetado para configurar a posição atual do cursor no prompt. 
		 * @param x Posição X do cursor.
		 * @param y Posição Y do cursor.
		 */		
		inline void setCursorPosition( const unsigned short x, const unsigned short y ) { 
			setCursorPosition( y * PROMPT_WIDTH + x );
		}

		/** 
		 * Método sobrecarregado. Projetado para configurar a posição atual do cursor no prompt. 
		 * @param position Posição do cursor dentro do buffer.
		 */
		void setCursorPosition( const unsigned short position ) {
			//Verifica se a nova posição é válida.
			if( position < PROMPT_WIDTH * PROMPT_HEIGHT )
				prompt.position = position;
		}
		
		/** Método projetado para retornar a posição atual do cursor. */
		inline unsigned short getCursorPosition() const {
			return prompt.position;
		}
		
		/** 
		 * Método projetado para configurar a cor de background dos caracteres do prompt. 
		 * @param color Cor usada para pintar o fundo dos caracteres.
		 */
		inline void setBgColor( const tColor color ) {
			prompt.color = (prompt.color & 0x0F) | (((unsigned char) color) << 4 );
		}
		
		/** Método projetado para retornar a cor de background dos caracteres do prompt. */
		inline const tColor getBgColor() const {
			return (tColor) (prompt.color >> 4); 
		}

		/** 
		 * Método projetado para configurar a cor dos caracteres do prompt. 
		 * @param color Cor usada para pintar os caracteres.
		 */
		inline void setTextColor( const tColor color ) {
			prompt.color = (prompt.color & 0xF0) | ((unsigned char) color);
		}

		/** Método projetado para retornar a cor dos caracteres do prompt. */
		inline const tColor getTextColor() const {
			return (tColor) (prompt.color & 0xF);
		}		
		
		/** 
		 * Método projetado para inserir uma letra na posição atual do buffer. 
		 * @param value Caractere que será escrito no buffer.
		 */
		inline void setChar( const char value ) { 
			prompt.bufferPtr[prompt.position].color = prompt.color;
			prompt.bufferPtr[prompt.position].value = value;
		}
		
		/** 
		 * Método projetado para inserir uma letra em uma posição do buffer. 
		 * @param x Posição X do cursor.
		 * @param y Posição Y do cursor.
		 * @param value Caractere que será escrito no buffer.
		 */
		inline void setChar( const char value, const unsigned short x, const unsigned short y ) {
			setCursorPosition(x,y);
			setChar(value);
		}
		
		/** Método projetado para retornar uma letra da posição atual do buffer. */
		inline const char getChar() const {
			return prompt.bufferPtr[prompt.position].value; 
		}
		
		/** Destrutor padrão. */
		~Prompt() {
			delete[] prompt.bufferPtr;
		}

	protected:
		/** Método abstrato projetado para retornar um ponteiro para os dados do component. */
		virtual inline const tComponent* getReference() const {
			return &prompt;
		}
		
		/** Formato dos elementos contidos no buffer do prompt. */
		struct tDataFormat {
			char value;
			char color;
		}__attribute__((__packed__));
		
		/**
		 * Registro usado para compartilhamento de informações entre o Kernel Neutrino e a NLIB. Foi projetado para 
		 * controlar o funcionamento de um Component do tipo Prompt.
		 * @remarks A nlib é responsavel por enviar ao kernel as informações necessarias para criação dos componentes.
		 * @author alisson_linhares@hotmail.com
		 *************************************************************************************************************/
		struct tPrompt : tComponent {
			tDataFormat *bufferPtr; /**< Buffer que contém o texto do prompt*/
			unsigned short position; /**< Posição do curso no texto */
			char color; /**< Cor atual do prompt. */
			
			/** 
			 * Construtor responsável por inicializar todas as variáveis compartilhadas. 
			 * @param x - Posição X do component.
			 * @param y - Posição Y do component.
			 * @param width - Largura do component.
			 * @param height - Altura do component.
			 **/
			tPrompt( const unsigned short x, const unsigned short y, const unsigned short width, const unsigned short height) : tComponent( x, 
				y, width, height, COMPONENT_DEFAULT_BGCOLOR, COMPONENT_DEFAULT_TXCOLOR, PROMPT ), color(PROMPT_DEFAULT_COLOR), position(0),
				bufferPtr( new tDataFormat[PROMPT_WIDTH * PROMPT_HEIGHT] )  {
			}
		} __attribute__((__packed__));

	private:
		tPrompt prompt; /**< Registro compartilhado com o kernel. */
	};
}
	
#endif