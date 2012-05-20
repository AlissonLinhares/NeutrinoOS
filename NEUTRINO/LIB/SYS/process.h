/*---------------------------------------------------------------------------*
 * Copyright (C) 2011 Alisson Linhares de Carvalho.                          *
 * All rights reserved.                                                      *
 *                                                                           *
 * This file is part of the neutrino lib.                                    *
 *                                                                           *
 * The neutrino lib is free software: you can redistribute it and/or         *
 * modify it under the terms of the GNU Lesser General Public License as     *
 * published by the Free Software Foundation, either version 3 of the        *
 * License, or (at your option) any later version.                           *
 *                                                                           *
 * The neutrino lib is distributed in the hope that it will be useful,       *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of            *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             *
 * GNU Lesser General Public License for more details.                       *
 *                                                                           *
 * You should have received a copy of the GNU Lesser General Public License  *
 * along with the neutrino lib. If not, see <http://www.gnu.org/licenses/>.  *
 *---------------------------------------------------------------------------*/

#ifndef PROCESS_H
#define PROCESS_H

#include <core.h>

namespace nlib {
	/** 
	 * @remarks Formato do bloco de controle de processo. 
	 * @see SCHEDULER.ASM
	 * @author alisson_linhares@hotmail.com
	 **/
	struct tBCP {
		const void* next;  /**< Ponteiro para o endereço do próximo processo. */
		const void* prior; /**< Ponteiro para o endereço do processo anterior. */ 
		
		/* Dados relativos ao processador. */
		const unsigned int eax;    /**< Registrador acumulador. */
		const unsigned int ebx;    /**< Registrador base. */
		const unsigned int ecx;    /**< Registrador contador. */
		const unsigned int edx;    /**< Registrador de dados. */
		const unsigned int edi;    /**< Registrador de índice de destino. */
		const unsigned int esi;    /**< Registrador de índice de origem. */
		const unsigned int esp;    /**< Ponteiro para pilha. */
		const unsigned int ebp;    /**< Resgistrador base para pilha. */ 
		const unsigned short code; /**< Segmento de código. */
		const unsigned short data; /**< Segmento de dados. */
		
		/* Dados de controle. */
		unsigned int status;     /**< Estado do processo. */
		const unsigned int base; /**< Endereço de memória do processo. */
		char name[11];           /**< Nome do processo. */
		
		/* Dados relativos ao coprocessador. */
		const unsigned short controlWord;  /**< Registrador de controla da FPU. */
		const unsigned short reserved_0;   /**< Reservado. */
		const unsigned short statusWord;   /**< Status da FPU. */
		const unsigned short reserved_1;   /**< Reservado. */
		const unsigned short tagWord;      /**< Estado dos registradores da FPU. */
		const unsigned short reserved_2;   /**< Reservado. */
		const unsigned int ip;             /**< Ponteiro para a próxima instrução. */
		const unsigned short cs;           /**< Segmento de código usado */
		const unsigned short reserved_3;   /**< Reservado. */
		const unsigned int operandAddress; /**< Endereço dos operandos. */
		const unsigned short ds;           /**< Segmento de dados usado. */
		const unsigned short reserved_4;   /**< Reservado. */
		const unsigned char st0[10];       /**< Registrador STR0 da FPU. */
		const unsigned char st1[10];       /**< Registrador STR1 da FPU. */
		const unsigned char st2[10];       /**< Registrador STR2 da FPU. */
		const unsigned char st3[10];       /**< Registrador STR3 da FPU. */
		const unsigned char st4[10];       /**< Registrador STR4 da FPU. */
		const unsigned char st5[10];       /**< Registrador STR5 da FPU. */
		const unsigned char st6[10];       /**< Registrador STR6 da FPU. */
		const unsigned char st7[10];       /**< Registrador STR7 da FPU. */

		/* Dados gerenciais. */
		const unsigned int memoryUsage; /**< Memória usada pelo processo. */
		const void* heapPtr;            /**< Ponteiro para área de memória interna do programa. */
		const void* promptPtr;          /**< Reservado para o modo compatibilidade do prompt. */
		const void* promptPanelPtr;     /**< Reservado para o modo compatibilidade do prompt. */
		tListener *errorListener;       /**< Ponteiro para um tratador de erros. */
		const unsigned int signature;   /**< Assinatura do BCP. "BCP!" */
	} __attribute__((__packed__));


	/** 
	 * Classe responsável por controlar as função básicas do gerente de processos. 
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	class Process {
	public:
		/** Método projetado para trocar o contexto de execução do programa atual. */
		static void sleep() {    
			SYS_SCHEDULER_PROCESS_SLEEP()
		}
		
		/** 
		 * Método projetado para iniciar um programa do disco. Ex.: Process::start("a\\prog\\cprog.bin\0");
		 * @param path - Caminho completo até um binário.
		 */
		static void start( const char *path ) {
			SYS_SCHEDULER_START_PROCESS( path )
		}

		/** 
		 * Método projetado para matar processos. Process::kill(10000); 
		 * @param id - Número do processo que será desalocado. 
		 * @remarks kill() para matar o processo atual; kill(-1) para matar todos os processos.
		 */
		static void kill( const unsigned int id = 0 ) {
			SYS_SCHEDULER_KILL_PROCESS( id )
		}
	private:

	};


	/** 
	 * Classe criada para oferecer uma segurança adicional no tratamento das informações enviadas pelo gerente de 
	 * processos. 
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	class PInfo {
	public:	
		/** Construtor responsável por inicializar a class PInfo. */
		PInfo() : index(1) {
			SYS_SCHEDULER_GET_INFO( buffer )
			
			current = (const tPInfo*) (buffer + sizeof(int));
		}
		
		/** 
		 * Move o cursor interno para o próximo bloco de informações. 
		 * @return Retorna false se a lista terminou.
		 */
		bool next() {
			if ( index < length() ) {
				current = (const tPInfo*) (buffer + index * sizeof(tPInfo) + sizeof(int));
				index++;
				return true;
			}
			
			return false;
		}
		
		/** Método projetado para retornar o total de processos. */
		inline unsigned int length() const {
			return (unsigned int) *buffer;
		}
		
		/** Método projetado para retornar o total de bytes usados na pilha do processo atual. */
		inline unsigned int getStackUsage() const {
			return current->stackUsage;
		}
		
		/** Método projetado para retornar o endereço de memória do processo atual. */
		inline unsigned int getMemoryBase() const {
			return current->memoryBase;
		}
		
		/** Método projetado para retornar o total de páginas usadas pelo processo atual. */
		inline unsigned int getMemoryUsage() const {
			return current->memoryUsage;
		}
		
		/** Método projetado para retornar o nome do processo atual.*/
		inline const char* getName() const {
			return current->name;
		}
		
		/** Destrutor projetado para desalocar o buffer compartilhado entre o kernel e PInfo*/
		~PInfo() {
			if( buffer != 0 ) {
				delete buffer;
				buffer = 0; //Proteção adicional.
			}
		}

	private:
		/** Registro usado para troca de informações entre a nlib e o kernel. */
		struct tPInfo {
			unsigned int stackUsage;
			unsigned int memoryBase;
			unsigned int memoryUsage;
			const char name[12];
		} __attribute__((__packed__));
	
		const tPInfo *current;
		unsigned short index;
		const char *buffer;
	};
}
#endif