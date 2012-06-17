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

#ifndef MAKE_H
#define MAKE_H

#include <file.h>
#include <integer.h>
#include "command.h"

/** 
 * Classe projetada para gerenciar o comando make. Responsável por criar arquivos e pastas.
 * @author alisson_linhares@hotmail.com
 */
class Make : public Command {
public:
	/** 
	 * Construtor que inicializa o comando make.
	 * @param cmd - Ponteiro para o console. 
	 */
	Make( Console* cmd ) : Command(cmd, "make\0", "Create a file and/or folder.\0") {
		size = 1; //Tamanho do nó.
		type = File::FOLDER; //Tipo do nó.
	}
	
	/** Função abstrata definida na classe base. Executa os parâmetros do comando make. */
	CommandResult execute( tListNode *parameters ) {
		while( parameters != 0 ) {
			if( parameters->param->isEmpty() ) {
				if( strcmp(parameters->param->getName(),"h\0") == 0 )
					help();
				else
					return INVALID_PARAMETER;
			} else if( parameters->param->getName() == 0 ) {
				char *auxPtr, *name, *path;
				File f;
				
				do {
					path = (char *) parameters->param->pop();
					
					//Procurando pela barra '\' antes do nome do nó.
					for( auxPtr = path, name = 0; *auxPtr != 0; auxPtr++ )
						if( *auxPtr == '\\' ) 
							name = auxPtr;
							
					if( name != 0 )
						*name++ = 0; //Marcando o final do path

					//Criando um nó em disco.
					if(f.make( path, name, size, type ))
						return SYSTEM_ERROR;

				} while( !parameters->param->isEmpty() );
				
			} else if( parameters->param->length() == 1 ) {
				int temp = Integer::parseInt( parameters->param->pop() );
					
				if( strcmp(parameters->param->getName(),"s\0") == 0 ) {
					
					if( temp > 0 ) {
						size = (unsigned int) temp;
					} else {
						return INVALID_VALUE;
					}
					
				} else if( strcmp(parameters->param->getName(),"t\0") == 0 ) {
					
					//Verifica se o tipo do arquivo é valido.
					if( temp > 0 && temp < File::RESERVED ) {
						type = (File::tSubNodeType) temp;
					} else {
						return INVALID_VALUE;
					}
					
				} else 
					return INVALID_PARAMETER;
			} else 
				return INVALID_VALUE;

			parameters = parameters->next;
		}
		
		return FINALIZED_WITHOUT_ERROR;
	}

	/** Função abstrata definida na classe base. Imprime informações de ajuda do comando make. */
	virtual void help() const {
		cmd->print("\n"
	 " make -h   | List informations about the command make.\n"
	 " make path | Create a new file.\n"
	 "           | >make a\\home\\folder\n"
	 " make -s n | Set default file size.\n"
	 " make -t n | Set default file type.\n"
	 "           | [1]Folder, [2]Binary, [4]Data\n\n\0"); 
	}
	
	
private:
	unsigned int size; //Tamanho do nó.
	File::tSubNodeType type; //Tipo do nó.
};

#endif