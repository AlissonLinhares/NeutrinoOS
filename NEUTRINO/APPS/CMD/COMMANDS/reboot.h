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

#ifndef REBOOT_H
#define REBOOT_H

#include "command.h"

/** 
 * Classe projetada para gerenciar o comando reboot. Responsável por reiniciar o sistema. 
 * @author alisson_linhares@hotmail.com
 */
class Reboot : public Command {
public:
	/** 
	 * Construtor que inicializa o comando reboot.
	 * @param cmd - Ponteiro para o console. 
	 */
	Reboot( Console* cmd ) : Command( cmd, "reboot\0", "Restart the operating system.\0") {

	}
	
	/** Função abstrata definida na classe base. Executa os parâmetros do comando reboot. */
	virtual CommandResult execute( tListNode *parameters ) {
		while( parameters != 0 ) {
			if( strcmp(parameters->param->getName(),"h\0") == 0 ) {
				if( parameters->param->isEmpty() ) {
					help();
				} else
					return INVALID_VALUE;
			} else 
				return INVALID_PARAMETER;
			
			parameters = parameters->next;
		}

		return FINALIZED_WITHOUT_ERROR;	
	}

	/** Função abstrata definida na classe base. Executa o comando padrão da classe reboot. */
	virtual CommandResult execute() {
		System::reboot();
		return UNKNOWN_ERROR; //Se o sistema não reiniciar, retorna um erro para a aplicação.
	}	

	/** Função abstrata definida na classe base. Imprime informações de ajuda do comando reboot. */
	virtual void help() const {
		cmd->print("\n"
		  " reboot -h | List informations about the command show.\n"
		  " reboot    | Restart the operating system.\n\n\0");
	}

private:

};

#endif