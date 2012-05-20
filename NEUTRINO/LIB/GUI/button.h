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

#ifndef BUTTON_H
#define BUTTON_H

#include <component.h>

namespace nlib {
	/**
	  * Registro usado para o compartilhamento de informações entre o Kernel Neutrino e a NLIB. Foi projetado para
	  * gerenciar o funcionamento de um Component do tipo Button.
	  * @remarks A nlib é responsável por enviar ao kernel as informações necessárias para criação dos componentes.
	  * @author alisson_linhares@hotmail.com
	  *************************************************************************************************************/
	struct tButton : tComponent {
		const char *name; /**< Ponteiro para o nome do botão. */
		
		/** 
		  * Construtor responsável por inicializar todas as variáveis compartilhadas. 
		  * @param x - Posição X do component.
		  * @param y - Posição Y do component.
		  * @param width - Largura do component.
		  * @param height - Altura do component.
		  * @param bgColor - Cor que será usado no fundo do botão.
		  * @param textColor - Cor que será usado no contorno e no texto usado no botão.
		  **/
		tButton( const unsigned short x, const unsigned short y, const unsigned short width, const unsigned short height, 
			  const unsigned int bgColor, const unsigned int textColor, const char *name ) : tComponent( x, y, width,
			  height, bgColor, textColor, Component::BUTTON ), name( name ) {
		}
	} __attribute__((__packed__));


	/**
	 * Button é um tipo de componente responsável por controlar ações interativas executadas pelo usuário.
	 * @remarks É recomendável o uso das funções fornecidas pela interface gráfica básica do Kernel. Essas funções são 
	 * projetadas para tornar os programas mais suscetíveis a evoluções do núcleo. Programas que utilizam a GUI padrão
	 * ocupam menos espaço em memória se comparado com alternativas construídas por terceiros.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	class Button : public Component {
	public:
		/** 
		 * Construtor responsável por criar um Component do tipo Button.
		 * @param x - Posição x do botão.
		 * @param y - Posição y do botão.
		 * @param width - Largura do botão.
		 * @param height - Altura do botão.
		 * @param name - Nome que será inserido no botão.
		 * @param bgColor - Cor que será usado no fundo do botão.
		 * @param textColor - Cor que será usado no contorno e no texto usado no botão.
		 */
		Button( unsigned short x = COMPONENT_DEFAULT_X, unsigned short y = COMPONENT_DEFAULT_Y, unsigned short width = COMPONENT_DEFAULT_W,
			unsigned short height = COMPONENT_DEFAULT_H, const char *name = 0, unsigned int bgColor = COMPONENT_DEFAULT_BGCOLOR,
			unsigned int textColor = COMPONENT_DEFAULT_TXCOLOR ) : button( x, y, width, height, bgColor, textColor, name ) {
		}
	
		/** 
		 * Método projetado para inserir um nome em um objeto do tipo Button. 
		 * @param name - Nome que será inserido no botão.
		 */
		inline void setName( const char *name = 0 ) {
			button.name = name;
		}
		
		/** Método projetado para retornar o ponteiro para o nome de um objeto do tipo Button. */
		inline const char *getName() const {
			return button.name;
		}
		
	protected:
		/** Método abstrato projetado para retornar um ponteiro para os dados do component. */
		virtual inline const tComponent* getReference() const {
			return &button;
		}
		
	private:		
		tButton button; /**< Registro compartilhado com o kernel. */
	};
}

#endif

