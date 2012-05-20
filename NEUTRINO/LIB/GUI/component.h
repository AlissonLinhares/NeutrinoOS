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

#ifndef COMPONENT_H
#define COMPONENT_H

#define COMPONENT_DEFAULT_X 0
#define COMPONENT_DEFAULT_Y 0
#define COMPONENT_DEFAULT_W 20
#define COMPONENT_DEFAULT_H 20
#define COMPONENT_DEFAULT_TXCOLOR 0
#define COMPONENT_DEFAULT_BGCOLOR 0xFFFFFFFF
#define COMPONENT_SIGNATURE 0x89ABCDEF
	
#include <container.h>

namespace nlib {

	/**
	 * Registro usado para o compartilhamento de informações entre o Kernel Neutrino e a NLIB. Foi projetado para
	 * armazenar propriedades comuns a todos os componentes gráficos.
	 * @remarks A nlib é responsável por enviar ao kernel as informações necessárias para criação dos componentes.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	struct tComponent : tContainer {
		unsigned char type; /**< Tipo do componente. "Usado pelo kernel para efetuar checagens específicas." */
		
		/** 
		 * Construtor responsável por inicializar todas as variáveis compartilhadas.
		 * @param x - Posição X do component.
		 * @param y - Posição Y do component.
		 * @param width - Largura do component.
		 * @param height - Altura do component.
		 * @param bgColor - Cor que será usado no fundo do component.
		 * @param textColor - Cor que será usado no contorno e no texto usado no component.
		 * @param type - Tipo do component.
		 *************************************************************************************************************/	
		tComponent( const unsigned short x, const unsigned short y, const unsigned short width, const unsigned short height, 
			const unsigned int bgColor, const unsigned int textColor, const unsigned char type ) :
			tContainer( x, y, width, height, bgColor, textColor ), type(type) {

		}
	} __attribute__((__packed__));


	/**
	 * Component é uma unidade gráfica projetada para simplificar a interação homem-máquina. Na forma padrão um componente
	 * não possui nenhuma utilidade. Atribuindo características especificas é possível representar formas de botões, caixas
	 * de texto, prompts de comando, labels ou qualquer outro elemento gráfico conhecido.
	 * @remarks É recomendável o uso das funções fornecidas pela interface gráfica básica do Kernel. Essas funções são 
	 * projetadas para tornar os programas mais suscetíveis a evoluções do núcleo. Programas que utilizam a GUI padrão
	 * ocupam menos espaço em memória se comparado com alternativas construídas por terceiros.
	 * @author alisson_linhares@hotmail.com	
	 *************************************************************************************************************/
	class Component : public Container {
		friend class Panel; //Necessário para o uso do método getReference() de forma segura.
	public:
		/** Identificadores de todos os componentes suportados pela versão atual do kernel. */
		enum tComponentModel {
			CLOSE_BUTTON = 0,
			MAX_BUTTON,
			MIN_BUTTON,
			RESIZE_BUTTON,
			DRAG_BUTTON,
			BUTTON,
			NIF_BUTTON,
			LABEL,
			GRAPHIC_AREA,
			PROMPT,
			INVALID
		};
		
		/** Método projetado para retornar o tipo do componente. */
		inline tComponentModel getType() const {
			return (tComponentModel) ((tComponent*) getReference())->type;
		}
	};
}
	
#endif