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

#ifndef COMMAND_H
#define COMMAND_H

#include <console.h>
#include <string.h>
#include "parameter.h"

using namespace nlib;


enum CommandResult {
	FINALIZED_WITHOUT_ERROR = 0,
	INVALID_PARAMETER,
	INVALID_VALUE,
	COMMAND_NOT_EXIST,
	UNKNOWN_ERROR,
	SYSTEM_ERROR
};

/** 
 * Classe que controla o funcionamento básico do terminal. 
 * @author alisson_linhares@hotmail.com
 */
class Command {                 
public:
	/** Registro usado para montar uma lista de parâmetros. */
	struct tListNode {
		tListNode *next;
		Parameter *param; 
	};

	/** 
	 * Construtor responsável por inicializar um comando. 
	 * @param cmd - Ponteiro para um console.
	 * @param name - Nome do comando.
	 * @param description - Descrição básica do comando.
	 */
	Command( Console *cmd, const String name, const String description ) : cmd(cmd), name(name), description(description) {

	}
	
	/** Método responsável por retornar o nome do comando. */
	inline const String getName() const {
		return name;
	}

	/** Método responsável por retornar a descrição do comando. */
	inline const String getDescription() const {
		return description;
	}

	/** 
	 * Método responsável por quebrar uma string em tokens e executar as funções. 
	 * @param buffer - String com vários parâmetros e valores. Ex.: "-a 3 -b 10 -c 10\0" 
	 */
	CommandResult decoder( char* buffer ) {
		CommandResult result = UNKNOWN_ERROR;
		tListNode *listOfParam = 0; 
		tListNode *currentNode = 0;

		do {
		    //Removendo espaços em branco do buffer
			for( ;*buffer == ' '; *(buffer++) = 0 );
			
			//Verifica se terminou a lista e executa os parâmetros
			if( *buffer == 0 ) {
				if( listOfParam != 0 ) //Se não for passado nenhum parâmetro é executado a função padrão
					result = execute( listOfParam );
				else
					result = execute();
					
				break;
			} else if( *buffer == '-' ) { //Verifica se deve inserir um novo parâmetro na lista
				*(buffer++) = 0;
				
				//Não é permitido '-' ou '- ' como parâmetro.
				if( *buffer == 0 || *buffer == ' ' ) { 
					result = INVALID_PARAMETER; 
					break;
				} else if( listOfParam != 0 ) { 
					currentNode->next = new tListNode();
					currentNode = currentNode->next; 
				} else {
					//Cria a lista de parâmetros se a lista estiver nula.
					listOfParam = new tListNode(); 
					currentNode = listOfParam;
				}	

				currentNode->param = new Parameter(buffer);
				currentNode->next = 0; //Marcando o final da lista	
			} else {
				//Inserindo um novo atributo para o parâmetro
				if( listOfParam == 0 ){
					listOfParam = new tListNode(); 
					currentNode = listOfParam;
					currentNode->param = new Parameter();
					currentNode->next = 0; //Marcando o final da lista	
				}
				
				currentNode->param->push( buffer );
			}
			
			//Indo para o final do parâmetro/atributo
			for( ;*buffer != ' ' && *buffer != 0 && *buffer != '-'; buffer++ ); 
		} while( true );

		//Desalocando memória usada pela lista de atributos
		while( listOfParam != 0 ) {
			currentNode = listOfParam;
			listOfParam = listOfParam->next;
			delete currentNode;
		}

		return result;
	}
	
	/** 
	 * Método abstrato para executar uma lista de parâmetros. 
	 * @param parameters - Ponteiro para lista de parâmetros.
	 */
	virtual CommandResult execute( tListNode *parameters ) = 0;
	
	/** Método para executar funções default. */
	virtual CommandResult execute() {
		help(); //Executa o help por padrão.
		return FINALIZED_WITHOUT_ERROR;
	}
	
	/** Método abstrato para executar o help do comando. */
	virtual void help() const = 0;

private:
	const String name;
	const String description;
	
protected:
	Console *cmd; 
};

#endif