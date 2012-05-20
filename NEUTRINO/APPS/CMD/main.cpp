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

//Importando bibliotecas de sistema
#include <console.h>
#include <system.h>
#include <error.h>
#include <string.h>

//Importando comandos
#include "COMMANDS/command.h"
#include "COMMANDS/clear.h"
#include "COMMANDS/color.h"
#include "COMMANDS/exit.h"
#include "COMMANDS/help.h"
#include "COMMANDS/kill.h"
#include "COMMANDS/make.h"
#include "COMMANDS/reboot.h"
#include "COMMANDS/show.h" 
#include "COMMANDS/start.h"

using namespace nlib;

#define COMMAND_LIST_SIZE 9 //Total de comandos importados

/**
 * Função que decodifica e executa um comando. 
 * @param com - Ponteiro para um objeto do tipo comando.
 * @param function - Função que deve ser executada.
 * @param parameters - Parâmetros para função.
 */
inline const CommandResult decoder( Command *com[], const char* parameters, const char* function ) {
	int begin = 0;
	int end   = COMMAND_LIST_SIZE - 1;
	unsigned int middle;
	char result;
	
	//Busca binária
	do {
		middle = (begin + end) / 2;
		result = com[middle]->getName().equals(function);

		if( result == 0 )
			return com[middle]->decoder((char*) parameters );
		else if( result > 0 )
			end   = middle - 1;
		else
			begin = middle + 1;
	} while( begin <= end );
	
	return COMMAND_NOT_EXIST;
}

int main() {
	String buffer(80); //Buffer para o terminal.
	
	//Criando um console.
	Console *cmd = new Console( 50, 50, "CMD.BIN - V0.05 - 20.01.2012\0");
	cmd->clear();
	cmd->print("Copyright (C) 2011-2012 Projeto Neutrino O.S. All rights reserved. For more \n"
	           "details, see <projetonos.wordpress.com> or type <show a\\home\\license.txt>\n\0");
	
	//Criando uma lista ordenada de comandos.
	Command *com[COMMAND_LIST_SIZE] = { new Clear(cmd), new Color(cmd), new Exit(cmd), new Help(cmd,com,COMMAND_LIST_SIZE), new Kill(cmd),
					    new Make(cmd), new Reboot(cmd), new Show(cmd), new Start(cmd) };
    	
	do {
		cmd->print('>');
		cmd->read( buffer ); 
		cmd->print('\n');

		//Removendo espaços do final e do início.
		buffer.trim(); 

		//Decodificando o comando digitado.
 		switch (decoder(com, buffer.toCharArray(), buffer.split(' ') )) {
			case FINALIZED_WITHOUT_ERROR:
				break;
			case COMMAND_NOT_EXIST:
				cmd->print("\n Unknown command. Type |help| to get more information.\n\0");
				break;
			case INVALID_PARAMETER:
				cmd->print("\n Unknown parameters. Type \0");
				cmd->print( buffer.getBufferPtr() ); //Escrevendo o nome do comando
				cmd->print(" -h to get more information.\n\0");
				break;
			case INVALID_VALUE:
				cmd->print("\n An invalid value was passed for the last function. Check the list of parameters for more informations.\n\0");
				break;
			case UNKNOWN_ERROR:
				cmd->print("\n The command was executed with one or more issues.\n\0");
		}
		
		//Verifica se ocorreu alguma exceção no kernel.
		if( Error::getCode() ) {
			cmd->print("\n The system reported a problem. Check the manufacturer's information at http://projetonos.wordpress.com and try again. [Error: \0");
			cmd->print(Error::getCode());
			cmd->print(" ]\n\0");
			Error::clear();
		} 
	} while( true );
	
	return 0;
}
