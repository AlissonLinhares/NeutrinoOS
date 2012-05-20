// Copyright (C) 2011-2012 Alisson Linhares de Carvalho.
// All rights reserved.
//
// This file is part of the terminal.
//
// The terminal is free software: you can redistribute it and/or 
// modify it under the terms of the GNU General Public License as 
// published by the Free Software Foundation, either version 3 of the 
// License, or (at your option) any later version.
//
// The terminal is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with the terminal. If not, see <http://www.gnu.org/licenses/>.

#ifndef START_H
#define START_H

#include "command.h"
#include <process.h>

/** 
 * Classe projetada para gerenciar o comando start. Responsável por iniciar programas do disco.
 * @author alisson_linhares@hotmail.com
 */
class Start : public Command {
public:
	/**
	 * Construtor que inicializa o comando start.
	 * @param cmd - Ponteiro para o console.
	 */
	Start( Console* cmd ) : Command( cmd, "start\0", "Start a specific program.\0" ) {

	}
	
	/** Função abstrata definida na classe base. Executa os parâmetros do comando start. */
	virtual CommandResult execute( tListNode *parameters ) {
		while( parameters != 0 ) {

			if( parameters->param->getName() == 0 ) {
			
				do {
					Process::start( parameters->param->pop() );
				} while( !parameters->param->isEmpty() );
				
			} else if( strcmp(parameters->param->getName(),"h\0") == 0 ) {
				if( !parameters->param->isEmpty() )
					return INVALID_VALUE;
				
				help();
			} else {
				return INVALID_PARAMETER;
			}
			
			parameters = parameters->next;
		}
		
		return FINALIZED_WITHOUT_ERROR;
	}

	/** Função abstrata definida na classe base. Imprime informações de ajuda do comando start. */
	void help() const {	
		cmd->print("\n"
			  " start -h   | List informations about the command start.\n"
			  " start path | Start a specific program.\n"
			  "            | start a\\boot\\cmd.bin\n\n\0");
	}
private:

};

#endif
