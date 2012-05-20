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

#ifndef CANVAS_AREA_H
#define CANVAS_AREA_H

#include "component.h"

namespace nlib {
	/**
	  * Registro usado para compartilhamento de informações entre o Kernel Neutrino e a NLIB. Foi projetado para
	  * gerenciar o funcionamento de um Component do tipo Canvas.
	  * @remarks A nlib é responsável por enviar ao kernel as informações necessárias para criação dos componentes.
	  * @author alisson_linhares@hotmail.com
	  *************************************************************************************************************/
	struct tCanvas : tComponent {
		unsigned short* bufferPtr; /**< Ponteiro para o buffer compartilhado. */
		
		/** 
		  * Construtor responsável por inicializar todas as variáveis compartilhadas. 
		  * @remarks A nlib é responsavel por enviar ao kernel as informações necessarias para criação dos componentes.       	
		  * @param x - Posição X do component.
		  * @param y - Posição Y do component.
		  * @param width - Largura do component.
		  * @param height - Altura do component.
		  *************************************************************************************************************/
		tCanvas( const unsigned short x, const unsigned short y, const unsigned short width, const unsigned short height) : tComponent( x, 
			y, width, height, COMPONENT_DEFAULT_BGCOLOR, COMPONENT_DEFAULT_TXCOLOR, Component::GRAPHIC_AREA ), bufferPtr( new unsigned short[width * height] )  {
		}
	} __attribute__((__packed__));


	/**
	 * Canvas é um tipo de componente responsável por renderizar imagens.
	 * @remarks É recomendável o uso das funções fornecidas pela interface gráfica básica do Kernel. Essas funções são 
	 * projetadas para tornar os programas mais suscetíveis a evoluções do núcleo. Programas que utilizam a GUI padrão
	 * ocupam menos espaço em memória se comparado com alternativas construídas por terceiros.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	class Canvas : public Component {
	public:
		/** 
		 * Construtor responsável por criar um component do tipo Canvas e alocar um buffer de vídeo.
		 * @param x - Posição x da área gráfica.
		 * @param y - Posição y da área gráfica.
		 * @param width - Largura da área gráfica.
		 * @param height - Altura da área gráfica.
		 */
		Canvas( const unsigned short x = COMPONENT_DEFAULT_X, const unsigned short y = COMPONENT_DEFAULT_Y, const unsigned short width = COMPONENT_DEFAULT_W,
			const unsigned short height = COMPONENT_DEFAULT_H ) : gArea( x, y, width, height ) {
		}
		
		/** 
		 * Método projetado para limpar a área gráfica com uma cor.
		 * @param color - Cor usada para limpar o buffer.
		 */
		void clear( const unsigned short color = 0xFFFF ) {
			short pos;
			for( pos = 0; pos < gArea.width * gArea.height; pos++ ) 
				gArea.bufferPtr[pos] = color;
		}
		
		/** 
		 * Método projetado para retornar a cor de um pixel.
		 * @param x - Posição X do pixel.
		 * @param y - Posição Y do pixel.
		 */
		inline unsigned short getPixelColor( const short x, const short y ) const { 
			return gArea.bufferPtr[y * gArea.width + x];
		}
		
		/** 
		 * Método projetado para setar a cor de um pixel.
		 * @param x - Posição X do pixel.
		 * @param y - Posição Y do pixel.
		 * @param color - Cor do pixel.
		 */
		inline void setPixelColor( const short x, const short y, const short color ) { 
			if( x < gArea.width && y < gArea.height )
				gArea.bufferPtr[y * gArea.width + x] = color;
		}
		
		/**
		 * Método projetado para retornar um ponteiro para o buffer do component.
		 * @remarks O uso desta função é recomendavel para casos em que o desempenho é de extrema importância.
		 */
		inline unsigned short* getBufferPtr() const {
			return gArea.bufferPtr; 
		}
		
		/** 
		 * Método projetado para desenhar uma linha.
		 * @param x0 - Posição X inicial.
		 * @param x1 - Posição X final.
		 * @param y0 - Posição Y inicial.
		 * @param y1 - Posição Y final.
		 * @param color - Cor da reta.
		 * @remarks Esse método foi baseado no algoritmo de Bresenham. Consiste em uma técnica de rasterização bastante
		 * difundida em computação gráfica.
		 * @see http://en.wikipedia.org/wiki/Bresenham's_line_algorithm
		 * @see http://www.lcg.ufrj.br/Cursos/CGECI/rasterizacao-ppt
		 * @todo Remover esta função dessa class e criar uma forma apropriada de pintar figuras gráficas! [Para versão 0.04]
		 */
		void drawLine( unsigned short x0, unsigned short y0, unsigned short x1, unsigned short y1, unsigned short color ) {
			//Verificando se a reta está dentro da área do buffer.
			if( x0 < gArea.width && x1 < gArea.width && y0 < gArea.height && y1 < gArea.height ) {
				unsigned short dx,dy,sx,sy;
				short error,e2; //Trabalhando com resolução máxima de 2 ^ 15 x 2 ^ 15
				
				if ( x0 < x1 ) {
					sx = 1;
					dx = x1 - x0;
				} else {
					sx = -1;
					dx = x0 - x1;
				}
				
				if ( y0 < y1 ) {
					sy = 1; 
					dy = y1 - y0;
				} else {
					sy = -1;
					dy = y0 - y1;
				}
				
				error = dx - dy;

				do {
					//Setando a cor do pixel.
					gArea.bufferPtr[y0 * gArea.width + x0] = color;
					
					if ( x0 == x1 && y0 == y1 ) 
						break;
					
					//Multiplicando por 2.
					e2 = error << 1;
					
					if ( e2 > -dy ) { 
						error = error - dy;
						x0 += sx;
					}
					
					if ( e2 <  dx ) { 
						error = error + dx;
						y0 += sy; 
					}
				} while( true );
			}
		}
		
		/** Destrutor responsável por desalocar o buffer de vídeo usado pelo component. */
		~Canvas() {
			if( gArea.bufferPtr != 0 ) {
				delete[] gArea.bufferPtr;
				gArea.bufferPtr = 0;
			}
		}
	
	protected:
		/** Método abstrato projetado para retornar um ponteiro para os dados do component. */
		virtual inline const tComponent* getReference() const {
			return &gArea;
		}
		
	private:
		tCanvas gArea; /**< Registro compartilhado com o kernel. */
	};
}

#endif