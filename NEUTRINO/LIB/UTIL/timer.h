/*---------------------------------------------------------------------------*
 * Copyright (C) 2011-2012 Alisson Linhares de Carvalho.                     *
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

#include <core.h>
#include <system.h>

namespace nlib {
	/** 
	 * Classe responsável por gerenciar ações relacionadas ao relógio do sistema. 
	 * @todo Classe muito simples. Melhorar o gerenciamento de data e hora do sistema. [Parar versão 0.04]
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	 */
	class Timer {
	public:	
		/** Construtor responsável por carregar a data e hora do sistema. */
		Timer() {
			timer = System::getTimer();
		}
		
		/** Método para retorna os segundos. */
		inline unsigned char getSeconds() const {
			return timer.seconds;
		}	
		
		/** Método para retorna os minutos. */
		inline unsigned char getMinutes() const {
			return timer.minutes;
		}
		
		/** Método para retorna a hora. */
		inline unsigned char getHours() const {
			return timer.hours;
		}
		
		/** Método para retorna o dia. */
		inline unsigned char getDay() const {
			return timer.day;
		}

		/** Método para retorna o mês. */
		inline unsigned char getMonth() const {
			return timer.month;
		}
		
		/** Método para retorna o ano. */
		inline unsigned char getYear() const {
			return timer.year;
		}
		
		~Timer();
	private:
		tTimerFormat timer;
	};

}