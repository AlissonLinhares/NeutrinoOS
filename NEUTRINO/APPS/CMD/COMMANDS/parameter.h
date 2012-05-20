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

#ifndef PARAMETER_H
#define PARAMETER_H

/** 
 * Classe projetada para gerenciar parâmetros. Possui internamente uma pilha de valores.
 * @author alisson_linhares@hotmail.com
 */
class Parameter {
public:	
	/** 
	 * Construtor responsável por configurar um parâmetro.
	 * @param name - Nome do parâmetro. 
	 */
	Parameter( const char* name = 0 ) : stackPtr(0), stackSize(0), name(name) {

	}
	
	/** 
	 * Método para inserir o nome de um parâmetro. 
	 * @param name - Nome do parâmetro. 
	 */
	inline void setName( const char* name ) {
		this->name = name;
	}
	
	/** Método para retornar o nome do parâmetro. */ 	
	inline const char* getName() const {
		return name;
	}
	
	/**
	 * Método para inserir um valor na pilha.
	 * @param value - String que contém um valor para o parâmetro. 
	 */
	void push( const char* value ) {
		tStackNode *newNode = new tStackNode();
		newNode->next = stackPtr;
		newNode->value = value;
		
		stackPtr = newNode;			
		stackSize++;
	}
	
	/** Método para remover um valor da pilha. */
	const char* pop() {
		const char* value = 0;
		
		//Verifica se existe elementos na pilha
		if( stackSize > 0 ) {
			value = stackPtr->value;
			
			//Removendo elemento
			tStackNode* aux = stackPtr;
			stackPtr = stackPtr->next;
			delete aux;	
			
			stackSize--;
		}

		return value;
	}
			
	/** Método para retornar o tamanho da pilha de valores. */
	inline const unsigned int length() const {
		return stackSize;
	}
	
	/** Método que verifica se a pilha está vazia. */
	inline const bool isEmpty() const {
		return stackSize == 0;
	}

	/** Destrutor que desaloca a pilha de valores. */
	~Parameter() {
		tStackNode* aux;
		
		//Desalocando todos os valores da pilha
		for ( ;stackSize > 0; stackSize-- ) {
			aux = stackPtr;
			stackPtr = stackPtr->next;
			delete aux;
		}
	}
	
private:
	/** Registro usado para montar uma pilha de valores. */
	struct tStackNode {
		tStackNode *next;
		const char *value; 
	};
		
	tStackNode* stackPtr; /** Ponteiro para pilha de valores. */
	unsigned int stackSize; /** Tamanho da pilha de valores. */
	
protected:	
	const char* name;
};

#endif