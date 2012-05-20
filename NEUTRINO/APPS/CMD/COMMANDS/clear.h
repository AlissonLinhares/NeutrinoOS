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

#ifndef CLEAR_H
#define CLEAR_H

#include "command.h"

/** 
 * Classe projetada para gerenciar o comando clear. Responsável por limpar a tela do console. 
 * @author alisson_linhares@hotmail.com
 *************************************************************************************************************/
class Clear : public Command {
public:
	/** 
	 * Construtor que inicializa o comando clear.
	 * @param cmd - Ponteiro para o console. 
	 */
	Clear( Console* cmd ) : Command( cmd, "clear\0", "Clear the cmd screen.\0" ) {

	}
	
	/** Função abstrata definida na classe base. Executa os parâmetros do comando clear. */
	virtual CommandResult execute( tListNode *parameters ) {
		while( parameters != 0 ) {
			if( strcmp(parameters->param->getName(),"h\0") == 0 ) {
				//Verifica se o parâmetro -h possui valores
				if( !parameters->param->isEmpty() )
					return INVALID_VALUE;
					
				help();
			} else
				return INVALID_PARAMETER;
			
			parameters = parameters->next;
		}
		
		
		return FINALIZED_WITHOUT_ERROR;
	}

	/** Função abstrata definida na classe base. Apenas limpa a tela. */
	virtual CommandResult execute() {
		cmd->clear();
		return FINALIZED_WITHOUT_ERROR;
	}	
	
	/** Função abstrata definida na classe base. Imprime informações de ajuda do comando clear. */
	virtual void help() const {
		cmd->print("\n"
			" clear    | Clear the cmd screen.\n"
			" clear -h | List informations about the command clear.\n\n\0");
	}
private:

};

#endif