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

#ifndef PANEL_H
#define PANEL_H

#define PANEL_DEFAULT_X 10
#define PANEL_DEFAULT_Y 10
#define PANEL_DEFAULT_W 300
#define PANEL_DEFAULT_H 200
#define PANEL_DEFAULT_COLOR 0xFFFFFFFF
#define PANEL_SIGNATURE 0x89ABCDEF

#include <bar.h>
#include <component.h>
#include <container.h>

namespace nlib {
   
	/**
	 * Registro usado para compartilhamento de informações entre o Kernel Neutrino e a NLIB. Foi projetado para
	 * gerenciar o funcionamento dos paineis.
	 * @remarks A nlib é responsável por enviar ao kernel as informações necessárias para criação dos paineis.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	struct tPanel : tContainer {
		const tComponent *firstComp;
		const tComponent *lastComp;
		const unsigned int numberOfComp;
		const int *base;
		const unsigned char state;
		const unsigned short defaultY;
		const unsigned short defaultX;
		const unsigned short defaultH;
		const unsigned short defaultW;
		const tBar *barPtr;
		
		//Inicializando o registro para tornar o código mais seguro.
		tPanel( const unsigned short x = PANEL_DEFAULT_X, const unsigned short y = PANEL_DEFAULT_Y,
			const unsigned short width = PANEL_DEFAULT_W, const unsigned short height = PANEL_DEFAULT_H,
			const unsigned int bgColor = PANEL_DEFAULT_COLOR, const unsigned int textColor = ~PANEL_DEFAULT_COLOR
			) : tContainer( x, y, width, height, bgColor, textColor ), firstComp(0), lastComp(0), numberOfComp(0),
			base(0), state(0), defaultY(PANEL_DEFAULT_Y), defaultX(PANEL_DEFAULT_X), defaultH(PANEL_DEFAULT_H),
			defaultW(PANEL_DEFAULT_W), barPtr(0) {
		}
	}__attribute__((__packed__));


	/** 
	 * Registro usado para compartilhar informações entre o Kernel Neutrino e a NLIB. Foi projetado para retornar 
	 * informações do sistema de gerenciamento gráfico.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	struct tPanelInfo {
		const unsigned int signature;
		tPanel* focusPanel;
		tComponent* focusComponent;
		
		/** Construtor responsável por configurar o registro compartilhado. */
		tPanelInfo() : signature(PANEL_SIGNATURE) {
		  
		}
	}__attribute__((__packed__));


	/**
	 * Classe responsável por gerenciar painéis. Panel é uma abstração do sistema de gerenciamento gráfico fornecido
	 * pelo Kernel Neutrino. São áreas gráficas capazes de conter componentes. Essa classe tem como principal objetivo
	 * controlar as funções básicas de criação, deleção e renderização de painéis.
	 * @remarks É recomendável o uso das funções fornecidas pela interface gráfica básica do Kernel. Essas funções são 
	 * projetadas para tornar os programas mais suscetíveis a evoluções do núcleo. Programas que utilizam a GUI padrão
	 * ocupam menos espaço em memória se comparado com alternativas construídas por terceiros.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	class Panel : public Container {
		friend class Console;
	public:
		/** 
		* Construtor padrão.
		* @param x Posição X do painel.
		* @param y Posição Y do painel.
		* @param w Largura do painel.
		* @param h Altura do painel.
		* @param name Nome que será inserido na barra (Bar) do painel.
		* @param color Cor do painel.
		*/
		Panel( const unsigned short x = PANEL_DEFAULT_X, const unsigned short y = PANEL_DEFAULT_Y, const unsigned short w = PANEL_DEFAULT_W,
			const unsigned short h = PANEL_DEFAULT_H, const char *name = 0, const unsigned int bgColor = PANEL_DEFAULT_COLOR, 
			const unsigned int textColor = ~PANEL_DEFAULT_COLOR ) : panel( x, y, w, h, bgColor, textColor ) {
		
			//Se o nome for setado, será criada uma barra para o painel.
			if( name != 0 ) /** @todo Rever isso! Código muito ruim! [Para versão 0.04] */
				add( new Bar( name ) );
		}

		/** 
		 * Método projetado para inserir uma barra em um painel.
		 * @param comp Ponteiro para um objeto do tipo Bar.
		 * @todo Rever o gerenciamento da barra. [Para versão 0.04].
		 */
		void add( Bar *bar ) {
			const tBar *auxVar;
			
			//Removendo a barra anterior
			if( panel.barPtr != 0 ) {
				auxVar = panel.barPtr;
				panel.barPtr = 0;
				SYS_PANEL_REMOVE( &panel, &(auxVar->closeButton) )
				SYS_PANEL_REMOVE( &panel, &(auxVar->minButton) )
				SYS_PANEL_REMOVE( &panel, &(auxVar->maxButton) )
				SYS_PANEL_REMOVE( &panel, &(auxVar->dragButton) )
				SYS_PANEL_REMOVE( &panel, &(auxVar->resizeButton) )
			}
			
			//Configurando a barra para o tamanho do painel
			auxVar = bar->getBarPtr();
			const_cast<tBar*>(auxVar)->dragButton.width = panel.width - 60;
			const_cast<tBar*>(auxVar)->resizeButton.x = panel.width - 15;

			//Inserindo components no painel
			SYS_PANEL_ADD( &panel, &(auxVar->closeButton) )
			SYS_PANEL_ADD( &panel, &(auxVar->minButton) )
			SYS_PANEL_ADD( &panel, &(auxVar->maxButton) )
			SYS_PANEL_ADD( &panel, &(auxVar->dragButton) )
			SYS_PANEL_ADD( &panel, &(auxVar->resizeButton) )
			
			panel.barPtr = auxVar;
		}
		
		/** 
		 * Método projetado para inserir um componente em um painel.
		 * @param comp Ponteiro para um component.
		 */
		void add( const Component *comp ) {
			SYS_PANEL_ADD( &panel, comp->getReference() )
		}
		
		/** 
		 * Método projetado para remover um componente de um painel.
		 * @param comp Ponteiro para o component que será removido.
		 */
		void remove( const Component *comp ) {
			SYS_PANEL_REMOVE( &panel, comp->getReference() )
		}
		
		/** 
		 * Método projetado para renderizar um painel, juntamente, com seus componentes. 
		 * @remarks Está função deve ser invocada, somente, quando o painel necessitar ser redesenhado. O sistema,
		 * por padrão, gerencia essas janelas sem a necessidade de ajuda externa. 
		 */
		void draw() const {
			SYS_PANEL_DRAW( &panel )
		}
		
		/**
		 * Método projetado para renderizar componentes. Esta função foi concebida para redesenhar um componente específico. Deve 
		 * ser usada, somente, quando forem feitas alterações estruturais em componentes inseridos.
		 * @param comp Ponteiro para um component.
		 */
		void draw( const Component *comp ) const {
			SYS_PANEL_DRAW_COMPONENT( &panel, comp->getReference() )
		}

		/** 
		 * Método projetado para renderizar todas as janelas. Esta função deve ser usada com cautela. Tudo que estiver visível
 		 * será redesenhado. 
		 */
		static void drawAll() {
			SYS_PANEL_DRAW_ALL()
		}
	
		/** 
		 * Método projetado para abrir um painel. Por padrão, um painel só passará a funcionar mediante a sua abertura.
		 * @remarks É recomendável o uso da função draw() sempre que configurações manuais forem aplicadas aos painéis.
		 */
		void open() const { 
			SYS_PANEL_OPEN( &panel )
		}

		/** Método projetado para fechar um painel. Esta função apenas desativa a renderização e interação do objeto painel. */
		void close() const {  
			SYS_PANEL_CLOSE( &panel )
		}
		
		/** Método projetado para retornar o total de componentes inseridos no painel. */
		inline unsigned int getNumberOfComp() const {
			return panel.numberOfComp;
		}
		
		/** Método projetado para retornar o estado do painel. */
		inline const unsigned char getState() const {
			return panel.state;
		}
		
		/** Método projetado para retornar informações sobre o módulo que controla o funcionamento dos paineis. */
		static const tPanelInfo getInfo() {
			tPanelInfo info;
			SYS_PANEL_GET_INFO( &info )
			return info;
		}
		
		/** 
		 * Método projetado para retornar o painel, pertencente ao processo atual, que está em foco.
		 * @remarks Retorna 0 caso não exista um painel em foco.
		 */
		inline static const tPanel* getFocusPanel() {
			return getInfo().focusPanel;
		}
		
		/** 
		 * Método projetado para retornar o component, pertencente ao processo atual, que está em foco.
		 * @remarks Retorna 0 caso não exista um component em foco.
		 */
		inline static const tComponent* getFocusComponent() {
			return getInfo().focusComponent;
		}
		
		/** Destrutor padrão. */
		~Panel() {
			close();
		}

	protected:
		/** Método abstrato projetado para retornar um ponteiro para os dados do painel. */
		virtual inline const tContainer* getReference() const {
			return &panel;
		}

	private:
		tPanel panel; /**< Registro compartilhado com o kernel. */
	};
}

#endif