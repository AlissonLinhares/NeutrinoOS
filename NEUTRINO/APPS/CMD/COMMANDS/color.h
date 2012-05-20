/*---------------------------------------------------------------------------*
 * Copyright (C) 2011-2012 Alisson Linhares de Carvalho.                     *
 * All rights reserved.                                                      *
 *                                                                           *
 * This file is part of the terminal.                                        *
 *                                                                           *
 * The terminal is free software: you can redistribute it and/or             *
 * modify it under the terms of the GNU General Public License as            *
 * published by the Free Software Foundation, either version 3 of the        *
 * License, or (at your option) any later version.                           *
 *                                                                           *
 * The terminal is distributed in the hope that it will be useful,           *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of            *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             *
 * GNU General Public License for more details.                              *
 *                                                                           *
 * You should have received a copy of the GNU General Public License         *
 * along with the terminal. If not, see <http://www.gnu.org/licenses/>.      *
 *---------------------------------------------------------------------------*/

#ifndef COLOR_H
#define COLOR_H

#include "command.h"
#include <integer.h>

/** 
 * Classe projetada para gerenciar o comando Color. Responsável por trocar a cor do texto do console.
 * @author alisson_linhares@hotmail.com
 *************************************************************************************************************/
class Color : public Command {
public:

	/** 
	 * Construtor que inicializa o comando color.
	 * @param cmd - Ponteiro para o console. 
	 */
	Color( Console* cmd ) : Command( cmd, "color\0", "Change the font color.\0" ) {

	}
	
	/** Função abstrata definida na classe base. Executa os parâmetros do comando Color. */
	virtual CommandResult execute( tListNode *parameters ) {
		while( parameters != 0 ) {
			const char* name = parameters->param->getName();
	
			if( parameters->param->length() == 1 ) {
				if( strcmp(name,"t\0") == 0 ) {
					int val = Integer::parseInt(parameters->param->pop());
				
					if( val < 0 || val > 15 )
						return INVALID_VALUE;

					cmd->setTextColor((Prompt::tColor) val);
				} else if( strcmp(name,"b\0") == 0 ) {
					int val = Integer::parseInt(parameters->param->pop());
					
					if( val < 0 || val > 15 )
						return INVALID_VALUE;

					cmd->setBgColor((Prompt::tColor) val);
				} else
					return INVALID_PARAMETER;

			} else if( parameters->param->isEmpty() ) {
				if( strcmp(name,"h\0") == 0 ) {
					help(); 
				} else if( strcmp(name,"d\0") == 0 ) {
					return execute();
				} else
					return INVALID_PARAMETER;

			} else 
				return INVALID_PARAMETER;
		
			parameters = parameters->next;
		}
		
		return FINALIZED_WITHOUT_ERROR;
	}
	
	/** Função abstrata definida na classe base. Reseta as cores do console. */
	virtual CommandResult execute() {
		cmd->setTextColor(Prompt::WHITE);
		cmd->setBgColor(Prompt::DARKGREY);
		return FINALIZED_WITHOUT_ERROR;
	}
		
	/** Função abstrata definida na classe base. Imprime informações de ajuda do comando color. */
	void help() const {
		cmd->print("\n"
			" color -d   | Set default color.\n"
			" color -t n | Set new text color.\n"
			" color -b n | Set new background color.\n"
			" color -h   | List informations about the command color.\n\n"
			" ---------- Table of Colors ----------\n"
			" 0 - Black          -  8  - Dark gray\n"
			" 1 - Dark blue      -  9  - Blue\n"
			" 2 - Dark green     -  10 - Green\n"
			" 3 - Dark cyan      -  11 - Gray\n"
			" 4 - Dark red       -  12 - Red\n"
			" 5 - Dark margenta  -  13 - Margenta\n"
			" 6 - Dark yellow    -  14 - Yellow\n"
			" 7 - Light gray     -  15 - White\n"
			" -------------------------------------\n\n\0");
	}
private:
	
};

#endif