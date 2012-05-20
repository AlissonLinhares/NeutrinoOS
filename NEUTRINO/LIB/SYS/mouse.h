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

#ifndef MOUSE_H
#define MOUSE_H

#define MOUSE_SIGNATURE 0x89ABCDEF

#include <panel.h>
#include <component.h>

namespace nlib { 

	/**
	 * Classe projetada para gerenciar os recursos relativos ao mouse de forma segura.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	class Mouse {
	public:
		/** Construtor responsável por inicializar o mouse. */
		Mouse() {
			update(); //Carregando informações do mouse.
		}
		
		/** Método projetado para retornar a posição x do mouse. */
		inline const unsigned short getX() const {
			return info.mouseX;
		}
		
		/** Método projetado para retornar a posição y do mouse. */
		inline const unsigned short getY() const {
			return info.mouseY;
		}

		/** Método projetado para retornar o estado do botão esquerdo do mouse. */
		inline const bool isLBPressed() const {
			return info.lbtnState;
		}
		
		/** Método projetado para retornar o estado do botão do meio do mouse. */
		inline const bool isMBPressed() const {
			return info.mbtnState;
		}
		
		/** Método projetado para retornar o estado do botão da direita do mouse. */
		inline const bool isRBPressed() const {
			return info.rbtnState;
		}
		
		/** Método que verifica se o mouse está arrastando algum componente.  */
		inline const bool isDragging() const {
			return info.drag;
		}
		
		/** Método projetado para retornar se o mouse está habilitado. */
		inline const bool enabled() const {
			return info.enabled;
		}
		
		/**
		 * Método projetado para atualizar os dados do mouse. 
		 * @remarks Para melhorar o desempenho, os dados trafegam entre o kernel e os programas através de blocos de dados.
		 * Assim, para evitar um número desnecessário de chamadas de sistema, todo o registro é montado uma única vez.
		 */
		void update() {
			SYS_MOUSE_GET_INFO( &info )
		}

	private:
		/** 
		  * Registro usado para compartilhar informações entre o Kernel Neutrino e a NLIB. Foi projetado para retornar 
		  * informações do mouse.
		  * @author alisson_linhares@hotmail.com
		  *************************************************************************************************************/
		struct tMouseInfo {
			const unsigned int signature;
			bool enabled;
			bool drag;
			bool lbtnState;
			bool mbtnState;
			bool rbtnState;
			unsigned short mouseY;
			unsigned short mouseX;
			
			/** Construtor responsável por inicializar o registro. */
			tMouseInfo() : signature(MOUSE_SIGNATURE) {
			  
			}
		}__attribute__((__packed__));
		
		tMouseInfo info; /**< Registro compartilhado com o kernel. */
	};
}

#endif