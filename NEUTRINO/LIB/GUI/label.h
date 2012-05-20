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

#ifndef LABEL_H
#define LABEL_H

#include "component.h"

namespace nlib {
	/**
	  * Registro usado para compartilhamento de informações entre o Kernel Neutrino e a NLIB. Foi projetado para 
	  * controlar o funcionamento de um Component do tipo Label.
	  * @remarks A nlib é responsável por enviar ao kernel as informações necessárias para criação dos componentes.
	  * @author alisson_linhares@hotmail.com
	  *************************************************************************************************************/
	struct tLabel : tComponent {
		const char *name; /**< Nome usado na label */
		
		/** 
		  * Construtor responsável por inicializar todas as variáveis compartilhadas. 
		  * @param x - Posição X do component.
		  * @param y - Posição Y do component.
		  * @param width - Largura do component.
		  * @param height - Altura do component.
		  * @param bgColor - Cor que será usado no fundo do botão.
		  * @param textColor - Cor que será usado no contorno e no texto usado no botão.
		  **/
		tLabel( const unsigned short x, const unsigned short y, const unsigned short width, const unsigned short height, 
			const unsigned int bgColor, const unsigned int textColor, const char *name ) : tComponent( x, y, width,
			height, bgColor, textColor, Component::LABEL ), name( name ) {
		}
	} __attribute__((__packed__));


	/**
	 * Label é um tipo de componente responsável por apresentar dados na forma de texto aos usuários.
	 * @remarks É recomendável o uso das funções fornecidas pela interface gráfica básica do Kernel. Essas funções são 
	 * projetadas para tornar os programas mais suscetíveis a evoluções do núcleo. Programas que utilizam a GUI padrão
	 * ocupam menos espaço em memória se comparado com alternativas construídas por terceiros.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	class Label : public Component {
	public:
		/** 
		 * Construtor responsável por criar um Component do tipo Label.
		 * @param x - Posição x da label.
		 * @param y - Posição y do label.
		 * @param width - Largura do label.
		 * @param height - Altura do label.
		 * @param name - Nome que será inserido no label.
		 * @param bgColor - Cor que será usado no fundo do label.
		 * @param textColor - Cor que será usado no contorno e no texto usado no label.
		 */
		Label( unsigned short x = COMPONENT_DEFAULT_X, unsigned short y = COMPONENT_DEFAULT_Y, unsigned short width = COMPONENT_DEFAULT_W,
			unsigned short height = COMPONENT_DEFAULT_H, const char *name = 0, unsigned int bgColor = COMPONENT_DEFAULT_BGCOLOR,
			unsigned int textColor = COMPONENT_DEFAULT_TXCOLOR ) : label( x, y, width, height, bgColor, textColor, name ) {
		}
		
		/** 
		 * Método projetado para inserir um nome em um objeto do tipo label. 
		 * @param name - Nome que será inserido na label.
		 */
		inline void setName( const char *name = 0 ) { 
			label.name = name;
		}
		
		/** Método projetado para retornar o ponteiro para o nome de um objeto do tipo label. */
		inline const char* getName() {
			return label.name;
		}
		
	protected:
		/** Método abstrato projetado para retornar um ponteiro para os dados do component.*/
		virtual inline const tComponent* getReference() const {
			return &label;
		}
		
	private:
		tLabel label; /**< Registro compartilhado com o kernel. */
	};
}

#endif
