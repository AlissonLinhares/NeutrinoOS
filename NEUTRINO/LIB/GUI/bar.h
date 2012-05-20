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

#ifndef BAR_H
#define BAR_H

#include <component.h>

namespace nlib {
	/**
	 * Registro usado para o compartilhamento de informações entre o Kernel Neutrino e a NLIB. Foi projetado para
	 * gerenciar o funcionamento de um objeto do tipo tBar.
	 * @remarks A nlib é responsável por enviar ao kernel as informações necessárias para criação dos componentes.
	 * @todo Transformar a barra em uma component ou encontrar uma forma melhor de gerenciar a barra. [Para versão 0.04].
	 *************************************************************************************************************/
	struct tBar {
		tComponent closeButton;
		tComponent minButton;
		tComponent dragButton;
		const char* name;
		tComponent maxButton;
		tComponent resizeButton;
		
		tBar( const char *name ) : name(name), 
			closeButton( 2, 2, 13, 13, COMPONENT_DEFAULT_BGCOLOR, COMPONENT_DEFAULT_TXCOLOR, Component::CLOSE_BUTTON ),
			minButton( 30, 2, 13, 13, COMPONENT_DEFAULT_BGCOLOR, COMPONENT_DEFAULT_TXCOLOR, Component::MIN_BUTTON ),
			dragButton( 44, 2, 13, 13, COMPONENT_DEFAULT_BGCOLOR, COMPONENT_DEFAULT_TXCOLOR, Component::DRAG_BUTTON ),
			maxButton( 16, 2, 13, 13, COMPONENT_DEFAULT_BGCOLOR, COMPONENT_DEFAULT_TXCOLOR, Component::MAX_BUTTON ),
			resizeButton( 2, 2, 13, 13, COMPONENT_DEFAULT_BGCOLOR, COMPONENT_DEFAULT_TXCOLOR, Component::RESIZE_BUTTON ) {
		}
	}__attribute__((__packed__));

	/**
	 * Classe responsável por gerenciar o funcionamento da barra dos paineis. A barra controla funções especiais 
	 * fornecidas pelo kernel, tais como: minimizar, maximizar, fechar etc...
	 * @remarks É recomendável o uso das funções fornecidas pela interface gráfica básica do Kernel. Essas funções são 
	 * projetadas para tornar os programas mais suscetíveis a evoluções do núcleo. Programas que utilizam a GUI padrão
	 * ocupam menos espaço em memória se comparado com alternativas construídas por terceiros.
	 * @author alisson_linhares@hotmail.com
	 * @todo Transformar a barra em uma component [Para versão 0.04].
	 *************************************************************************************************************/
	class Bar {
	public:
		/** 
		 * Construtor responsável por criar e inicializar os elementos que compõem uma barra. 
		 * @param name - Nome que será inserido na barra.
		 */
		Bar( const char *name = 0 ) : bar( name ) {

		}

		/** 
		 * Método projetado para configura as cores dos botões da barra.
		 * @param color - Nova cor para os botões.
		 */
		inline void setTextColor( const unsigned int color ) {
			bar.closeButton.textColor = color;
			bar.minButton.textColor = color;
			bar.dragButton.textColor = color;
			bar.maxButton.textColor = color;
			bar.resizeButton.textColor = color;
		}
		
		/** Método projetado para retornar as cores dos botões da barra. */
		inline unsigned int getTextColor() const {
			return bar.closeButton.textColor;
		}
		
		/** 
		 * Método projetado para configura a cor do fundo dos botões da barra.
		 * @param color - Nova cor para os botões.
		 */	
		void setBgColor( const unsigned int color ) { 
			bar.closeButton.bgColor = color;
			bar.minButton.bgColor = color;
			bar.dragButton.bgColor = color;
			bar.maxButton.bgColor = color;
			bar.resizeButton.bgColor = color;
		}
		
		/** Método projetado para retornar a cor de fundo dos botões da barra. */
		inline unsigned int getBgColor() const {
			return bar.closeButton.bgColor;
		}

		/** 
		 * Método projetado para reconfigurar o nome que será inserido na barra.
                 * @param name - Ponteiro para um nome.
		 */
		inline void setName( const char *name = 0 ) {
			bar.name = name; 
		}
		
		/** Método projetado para retornar o ponteiro para o nome contido na barra. */
		inline const char* getName() const {
			return bar.name;
		}

		/** Método projetado para retornar o ponteiro para a barra. */
		inline const tBar* getBarPtr() const {
			return &bar;
		}
		
	protected:
		tBar bar;
		
	private:

	};
}

#endif