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

#ifndef EXIT_H
#define EXIT_H

#include "command.h"
#include <process.h>

/** 
 * Classe projetada para gerenciar o comando exit. Responsável por sair do terminal. 
 * @author alisson_linhares@hotmail.com
 */
class Exit : public Command {
public:
	/**
	 * Construtor que inicializa o comando exit.
	 * @param cmd - Ponteiro para o console.
	 */
	Exit( Console* cmd ) : Command(cmd, "exit\0", "Close the command prompt.\0" ) {

	}
	
	/** Função abstrata definida na classe base. Executa os parâmetros do comando exit. */
	CommandResult execute( tListNode *parameters ) {
		while( parameters != 0 ) {
			if( strcmp(parameters->param->getName(),"h\0") == 0 ) {
				if( !parameters->param->isEmpty() ) {
					return INVALID_VALUE;
				} else {
					help();
				}
			}

			parameters = parameters->next;
		}
		
		return FINALIZED_WITHOUT_ERROR;
	}
		
	/** Função abstrata definida na classe base. Termina o processo atual. */
	virtual CommandResult execute() {
		Process::kill();
		return UNKNOWN_ERROR;
	}	
		
	/** Função abstrata definida na classe base. Imprime informações de ajuda do comando exit. */
	void help() const {
		cmd->print("\n"
			  " exit -h | List informations about the command exit.\n"
			  " exit    | Close the command prompt.\n\n\0");
	}
private:

};

#endif
