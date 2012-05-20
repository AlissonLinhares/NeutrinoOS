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

#ifndef KILL_H
#define KILL_H

#include "command.h"
#include <process.h>
#include <integer.h>

/** 
 * Classe projetada para gerenciar o comando kill. Responsável por terminar um processos. 
 * @author alisson_linhares@hotmail.com
 */
class Kill : public Command {
public:
	/**
	 * Construtor que inicializa o comando kill.
	 * @param cmd - Ponteiro para o console.
	 */
	Kill( Console* cmd ) : Command( cmd, "kill\0", "kill a specific process.\0" ) {

	}
	
	/** Função abstrata definida na classe base. Executa os parâmetros do comando kill. */
	CommandResult execute( tListNode *parameters ) {
		while( parameters != 0 ) {
			if( parameters->param->isEmpty() ) {
				if( strcmp(parameters->param->getName(),"h\0") == 0 ) {
					help();
				} else if( strcmp(parameters->param->getName(),"all\0") == 0 ) {
					Process::kill(-1);
				} else
					return INVALID_PARAMETER;
			} else if( parameters->param->getName() == 0 ) {
				do {
					Process::kill( Integer::parseInt(parameters->param->pop()) );
				} while( !parameters->param->isEmpty() );
			} else {
				return INVALID_PARAMETER;
			}
			
			parameters = parameters->next;
		}
		
		return FINALIZED_WITHOUT_ERROR;
	}

	/** Função abstrata definida na classe base. Imprime informações de ajuda do comando kill. */
	void help() const {	
		cmd->print("\n"
			  " kill -h    | List informations about the command kill.\n"
			  " kill -all  | kill all process.\n"
			  " kill id    | kill a specific process.\n\n\0");
	}
private:

};

#endif
