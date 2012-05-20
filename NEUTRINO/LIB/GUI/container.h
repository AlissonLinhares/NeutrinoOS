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


#ifndef CONTAINER_H
#define CONTAINER_H

#define CONTAINER_DEFAULT_X 0
#define CONTAINER_DEFAULT_Y 0
#define CONTAINER_DEFAULT_W 20
#define CONTAINER_DEFAULT_H 20
#define CONTAINER_DEFAULT_TXCOLOR 0
#define CONTAINER_DEFAULT_BGCOLOR 0xFFFFFFFF
#define CONTAINER_SIGNATURE 0x89ABCDEF
#define EVENT_LIST_SIZE 11

#include <core.h>

namespace nlib {
		
	/** Função compartilhada responsável por limpar todos os tratadores de eventos. */
	void clearAllListeners( const tListener **listeners ) {
		int i;
		for( i = 0; i < EVENT_LIST_SIZE; i++ )
			listeners[i] = 0; //Limpando todos os tratadores;
	}

	/**
	 * Registro usado no compartilhamento de informações entre o Kernel Neutrino e a NLIB. Foi projetado para
	 * armazenar propriedades comuns a todos os elementos gráficos.	
	 * @remarks A nlib é responsável por enviar ao kernel as informações necessárias para criação dos componentes.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	struct tContainer {
		//Variáveis controladas pelo kernel.
		const unsigned int signature; /**< Assinatura o componente. */
		const tContainer *nextPtr; /**< Próximo elemento gráfico. */
		const tContainer *priorPtr; /**< Elemento gráfico anterior ao atual. */
		
		//Variáveis controladas pela NLIB.
		unsigned short y; /**< Posição vertical do elemento gráfico. */
		unsigned short x; /**< Posição horizontal do elemento gráfico. */
		unsigned short height; /**< Altura do elemento gráfico. */
		unsigned short width; /**< Largura do elemento gráfico. */
		unsigned int bgColor; /**< Cor do fundo do elemento gráfico. */ 
		unsigned int textColor; /**< Cor do texto/elemento gráfico. */
		
		//Lista de eventos suportados pelos componentes.
		tListener *listener[EVENT_LIST_SIZE]; /**< Lista de eventos suportados pelo sistema gráfico. */
			
		/** 
		 * Construtor responsável por inicializar todas as variáveis do container.
		 * @param x - Posição X do container.
		 * @param y - Posição Y do container.
		 * @param width - Largura do container.
		 * @param height - Altura do container.
		 * @param bgColor - Cor que será usado no fundo do container.
		 * @param textColor - Cor que será usado no contorno e no texto usado no container.
		 *************************************************************************************************************/	
		tContainer( const unsigned short x, const unsigned short y, const unsigned short width, const unsigned short height, 
			const unsigned int bgColor, const unsigned int textColor ) : signature(CONTAINER_SIGNATURE),
			nextPtr(0), priorPtr(0), y(y), x(x), width(width), height(height), bgColor(bgColor), textColor(textColor) 
		{
			clearAllListeners( listener ); //Limpando todos os tratadores de eventos.
		}
	} __attribute__((__packed__));
	
	/**
	 * Container é um elemento usado como base para o gerenciamento gráfico do neutrino.
	 * @remarks É recomendável o uso das funções fornecidas pela interface gráfica básica do Kernel. Essas funções são 
	 * projetadas para tornar os programas mais suscetíveis a evoluções do núcleo. Programas que utilizam a GUI padrão
	 * ocupam menos espaço em memória se comparado com alternativas construídas por terceiros.
	 * @author alisson_linhares@hotmail.com	
	 *************************************************************************************************************/
	class Container {
	public:
		/** Identificadores de todos os eventos suportados pela versão atual do kernel. */
		enum tEventListener {
			ON_KEY_DOWN = 0,
			ON_KEY_UP,
			ON_MOUSE_OVER,
			ON_MOUSE_OUT,
			ON_FOCUS,
			ON_MOUSE_DOWN_L,
			ON_MOUSE_DOWN_R,
			ON_MOUSE_DOWN_M,
			ON_MOUSE_UP_L,
			ON_MOUSE_UP_R,
			ON_MOUSE_UP_M
		};

		/**
		 * Método projetado para configura a largura de um elemento gráfico.
		 * @param w - Valor para nova largura.
		 */
		inline void setWidth( const unsigned short w ) { 
			const_cast<tContainer*>(getReference())->width = w; 
		}
		
		/** Método projetado para retornar a largura de um elemento gráfico. */
		inline unsigned short getWidth() const { 
			return getReference()->width; 
		}
		
		/**
		 * Método projetado para configura a altura de um elemento gráfico.
		 * @param h - Valor para nova altura.
		 */	
		inline void setHeight( const unsigned short h ) { 
			const_cast<tContainer*>(getReference())->height = h;
		}
		
		/** Método projetado para retornar a altura de um elemento gráfico. */
		inline unsigned short getHeight() const {
			return getReference()->height;
		}
		
		/**
		 * Método projetado para configura a posição x de um elemento gráfico.
		 * @param x - Valor da nova posição no eixo x.
		 */
		inline void setX( const unsigned short x ) { 
			const_cast<tContainer*>(getReference())->x = x;
		}
		
		/** Método projetado para retornar a posição x de um elemento gráfico. */
		inline unsigned short getX() const { 
			return getReference()->x;
		}
		
		/** 
		 * Método projetado para configura a posição y de um elemento gráfico.
		 * @param y - Valor da nova posição no eixo y.
		 */
		inline void setY( const unsigned short y ) {
			const_cast<tContainer*>(getReference())->y = y; 
		}
		
		/** Método projetado para retornar a posição y de um elemento gráfico. */
		inline unsigned short getY() const {
			return getReference()->y;
		}
		
		/** 
		 * Método projetado para configurar a cor do texto/contorno de um elemento gráfico. 
		 * @param color - Nova cor para os textos/contorno.
		 */
		inline void setTextColor( const unsigned int color ) { 
			const_cast<tContainer*>(getReference())->textColor = color;
		}
		
		/** Método projetado para retornar a cor do texto/contorno de um elemento gráfico. */
		inline unsigned int getTextColor() const {
			return getReference()->textColor;
		}
		
		/** 
		 * Método projetado para configurar a cor de background de um elemento gráfico.
		 * @param color - Nova cor para o background.
		 */
		inline void setBgColor( const unsigned int color ) {
			const_cast<tContainer*>(getReference())->bgColor = color;
		}
		
		/** Método projetado para retornar a cor de background de um elemento gráfico. */
		inline unsigned int getBgColor() const {
			return getReference()->bgColor;
		}

		/** 
		 * Método projetado para registrar um tratador de enventos para um elemento gráfico. 
		 * @param listener - Tratador de eventos "Procedimento que será invocado sempre que um evento do tipo informado ocorrer".
		 * @param type - Tipo de evento que será registrado.
		 */
		inline void setListener( const tListener *listener, const tEventListener type ) {
			const_cast<tContainer*>(getReference())->listener[type] = listener;
		}
		
		/** 
		 * Método projetado para retornar um tratador de enventos para um elemento gráfico. 
		 * @param type - Tipo de evento registrado.
		 */
		inline const tListener* getListener( const tEventListener type ) const {
			return getReference()->listener[type];
		}

		/** 
		 * Método projetado para remover um tratador de enventos de um elemento gráfico. *
		 * @param type - Tipo do evento registrado.
		 */
		inline void clearListener( const tEventListener type ) {
			const_cast<tContainer*>(getReference())->listener[type] = 0;
		}
		
		/** Método projetado para limpar todos os tratadores de enventos do componente. */
		inline void clearListener() {
			clearAllListeners( const_cast<tContainer*>(getReference())->listener ); //Limpando todos os tratadores de eventos.
		}
	
	protected:
		/** 
		 * Método abstrato projetado para retornar um ponteiro para os dados do component.
		 * @remarks Todos os componentes possuem variáveis em comum, porém em virtude da insegurança no alinhamento de dados de troca, 
		 * dentro das classes, foram construídas estruturas (Registros de compartilhamento) para agrupar os dados relativos a cada 
		 * componente gráfico. Essa abordagem é reflexo da escolha da construção da NLIB inteiramente em C++.
		 *************************************************************************************************************/
		virtual const tContainer* getReference() const = 0;
		
	private:
		/** Função compartilhada responsável por limpar todos os tratadores de eventos. */
		friend void clearAllListeners( const tListener **listeners );
	};
}
	
#endif