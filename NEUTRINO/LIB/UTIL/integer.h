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

#ifndef INTEGER_H
#define INTEGER_H

#include <core.h>
#include <string.h>

namespace nlib {

	/**
	 * Classe responsável por oferecer recursos básicos para o gerenciamento de inteiros em C++.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	class Integer {
	public:
		/** 
		 * Método para converter um vetor de caracteres para int.
		 * @param str - Ponteiro para um vertor de caracteres.
		 */
		static int parseInt( const char *str ) {
			register unsigned int result;
			bool sign = (*str == '-') && str++;
			
			//Convertendo de string para integer
			for(result = 0; *str >= '0' && *str <= '9'; str++ )
				result = (result << 3) + (result << 1) + *str - '0';
	
			//Verifica se o número é negativo.
			if( sign )
				return -result;
			
			return result;
		}
		
		/** 
		 * Método para converter uma string para int.
		 * @param str - Ponteiro para uma string.
		 */
		inline static int parseInt( const String &str ) {
			return parseInt( str.toCharArray() );
		}
	private:

	};
}

#endif