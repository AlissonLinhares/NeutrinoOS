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

#ifndef SYSTEM_H
#define SYSTEM_H

#define SYSTEM_SIGNATURE 0x89ABCDEF  /**< Assinatura padrão do sistema. */

#include <core.h>
#include <error.h>

namespace nlib {
	/** 
	 * Registro usado para compartilhar informações entre o Kernel Neutrino e a NLIB. Foi projetado para retornar 
	 * informações gerais do sistema.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	struct tSysInfo {
		const unsigned int signature; /**< Assinatura do registro.  */
		Error::tErrorCode status;     /**< Estado atual do sistema. */
		unsigned short version;       /**< Versão atual do kernel */
		unsigned char mode;           /**< Modo de operação do sistema [DEBUG_MODE: 2, TEXT_MODE: 1, GRAPHICS_MODE: 0] */
		
		/** Construtor responsável por configurar o registro compartilhado. */
		tSysInfo() : signature( SYSTEM_SIGNATURE ) {
		
		}
	} __attribute__((__packed__));


	/** 
	 * Registro usado para compartilhar informações entre o Kernel Neutrino e a NLIB. Foi projetado para retornar/configurar
	 * data e a hora do sistema.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	struct tTimerFormat {
		unsigned char hours;
		unsigned char minutes;
		unsigned char seconds;
		unsigned char day;
		unsigned char month;
		unsigned char year;
	} __attribute__((__packed__));


	/** 
	 * Classe responsável por controlar as funcionalidades básicas de sistema, tais como: reniciar, desligar, retornar 
	 * informações etc... 
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	class System {
	public:
		/** Método projetado para reiniciar o sistema. */
		static inline void reboot() {            
			SYS_SYSTEM_REBOOT()
		}

		/** Método projetado para retornar informações gerais do sistema. */
		static inline tSysInfo getInfo() {
			tSysInfo info;
			SYS_SYSTEM_GET_INFO(&info)
			return info;
		}
		
		/** Método projetado para retornar a data e hora do sistema. */
		static inline tTimerFormat getTimer() {
			tTimerFormat timer;
			SYS_CMOS_GET_TIMER( &timer )
			return timer;
		}
	private:
		
	};
}

#endif