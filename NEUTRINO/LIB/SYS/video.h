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

#ifndef VIDEO_H
#define VIDEO_H

#define VIDEO_SIGNATURE 0x89ABCDEF /**< Assinatura padrão do gerente de vídeo. */

#include <core.h>

namespace nlib {

	/** 
	 * Registro usado para compartilhar informações entre o Kernel Neutrino e a NLIB. Foi projetado para retornar 
	 * informações do sistema de gerenciamento de vídeo.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	struct tVideoInfo {
		const unsigned int signature; /**< Assinatura do registro.       */
		const void* bufferPtr;        /**< Endereço do buffer de vídeo.  */
		const void* memoryPtr;        /**< Endereço da memória de vídeo. */
		unsigned int resolution;      /**< Resolução do vídeo.           */ 
		unsigned short height;        /**< Tamanho vertical do vídeo.    */
		unsigned short width;         /**< Tamanho horizontal do vídeo.  */
		unsigned char bpp;            /**< Total de bytes por pixel.     */
		
		/** Construtor responsável por configurar o registro compartilhado. */
		tVideoInfo() : signature( VIDEO_SIGNATURE ) {
		  
		}
	} __attribute__((__packed__));


	/** 
	 * Classe responsável por gerenciar as funções básicas de gerenciamento de vídeo.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	class Video {
	public:
		/** 
		 * Método projetado para pintar o vídeo com uma cor sólida.
		 * @param color - Cor que será usada na pintura.
		 */
		static inline void clear( const short color ) {
			SYS_VIDEO_BGCOLOR( color )
		}
		
		/** Método projetado para passar dados do buffer de vídeo para a memória de vídeo. */
		static inline void reset() {
			SYS_VIDEO_RESET()
		}
		
		/** Método projetado para retornar um bloco de informações de vídeo. */
		static inline tVideoInfo getInfo() {
			tVideoInfo info;
			SYS_VIDEO_GET_INFO( &info )
			return info;
		}
		
		static inline void drawBitmap( char *buffer ) {
			SYS_VIDEO_DRAW_BITMAP( buffer );
		}
	private:

	};
}

#endif