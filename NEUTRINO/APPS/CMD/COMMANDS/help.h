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

#ifndef HELP_H
#define HELP_H

#include "command.h"

/** 
 * Classe projetada para gerenciar o comando help. Responsável por listar informações do console. 
 * @author alisson_linhares@hotmail.com
 */
class Help : public Command {
public:
	/** 
	 * Help é um comando que recebe a lista de comandos para imprimir dados das funções.
	 * @param cmd - Ponteiro para o console. 
	 * @param com - Lista de comandos do terminal.
	 * @param listSize - Tamanho da lista.
	 */
	Help( Console* cmd, Command *com[], const unsigned char listSize ) : Command(cmd, "help\0", "List all available commands.\0") {
		this->com = com;
		this->listSize = listSize;
	}
	
	/** O help não possui subfunções. Retorna erro caso esse procedimento seja executado. */
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

	/** Função abstrata definida na classe base. Lista informações de todos os comandos. */
	virtual CommandResult execute() {
		unsigned char space;

		cmd->print("\n -------------- List of commands -------------\n\0");
		
		for( unsigned char i = 0; i < listSize; i++ ) {
			cmd->print(' ');
			cmd->print( com[i]->getName() );
			
			//Inserindo espaços entre o nome do comando e a descrição. O nome do comando não deve ser maior que 8!
			if( com[i]->getName().length() < 8 )
				cmd->setCursorPosition( cmd->getCursorPosition() + 8 - com[i]->getName().length() );
			
			cmd->print("- \0");
			cmd->print( com[i]->getDescription() );
			cmd->print('\n');
			
			if(( i + 1 ) % 18 == 0 )
				cmd->pause();
		}
		
		cmd->print(" ---------------------------------------------\n Commands available: ");
		cmd->print(listSize);
		cmd->print("\n\n\0");
		
		return FINALIZED_WITHOUT_ERROR;
	}	
	
	/** Função abstrata definida na classe base. Método para imprimir informações de todos os comandos cadastrados no console. */
	virtual void help() const {
		cmd->print("\n"
			" help    | List all available commands.\n"
			" help -h | List informations about the command color. \n\n\0");
	}
	
private:
	Command **com;
	unsigned char listSize; //Suporte para 255 comandos
};

#endif