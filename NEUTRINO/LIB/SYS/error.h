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

#ifndef ERROR_H
#define ERROR_H

#include <core.h>
#include <process.h>

namespace nlib {

	/** 
	 * Classe responsável por prover um conjunto de funcionalidade de gerenciamento de falhas para a nlib.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	class Error {
	public:
		enum tErrorCode {
			NO_ERROR = 0                 ,/**< Estado normal. */

			//Erros gerados por interrupções de hardware (Tratados pelo kernel).
			DIVIDE_BY_ZERO_EXCEPTION     ,/**< Erro de divisão por zero. */
			DEBUG_EXCEPTION              ,/**< Erro causado durante a execução de instruções de debug. */
			NMI_EXCEPTION                ,/**< Erro causado durante a execução de interrupções mascaradas.*/ 
			BREAKPOINT_EXCEPTION         ,/**< Informa que o processador encontrou um Breakpoint. */
			OVERFLOW_EXCEPTION           ,/**< Informa que ocorre um overflow. */
			BOUNDS_CHECK_EXCEPTION       ,/**< Informa que o operando excede o limite especificado. */
			INVALID_OPCODE_EXCEPTION     ,/**< Informa que o processador encontra um opcode inválido. */ 
			COPROCESSOR_NOT_AVAILABLE    ,/**< Informa que o processador não encontrou o coprocessador. */
			DOUBLE_FAULT_EXCEPTION       ,/**< Erro causado durante a execução do manipulador de exceção. */
			COPROCESSOR_SEGMENT_OVERRUN  ,/**< Erro gerado por violação do segmento de dados ou código. */
			INVALID_TSS                  ,/**< TSS do neutrino está incorreta. */
			SEGMENT_NOT_PRESENT          ,/**< Informa que o segmento de dados ou código é inválido. */
			STACK_EXCEPTION              ,/**< Informa o estouro de pilha (Um erro fatal). */ 
			GENERAL_PROTECTION_EXCEPTION ,/**< Erro gerado por falha no modo protegido. */
			PAGE_FAULT_EXCEPTIONS        ,/**< Erro gerado por falta de página. */
			COPRECESSOR_ERROR            ,/**< Falha no coprocessador. */

			//Erros gerados por falhas no kernel.
			MEMORY_PAGE_FAULT            ,/**< Informa que não existe memória suficiente para o processo. */
			STORAGE_PAGE_FAULT           ,/**< Informa que não existe espaço em disco suficiente para o processo. */
			STORAGE_INVALID_ID           ,/**< Informa que o ID passado para o sistema de arquivos é inválido. */
			NFS_INVALID_DISK             ,/**< Informa que a unidade é inválida. */
			NFS_INVALID_PATH             ,/**< Caminho até o arquivo ou pasta é inválido. */
			NFS_WRITE_ERROR              ,/**< Erro na escrita de dados no disco. */
			NFS_INVALID_SUBNODE          ,/**< Erro no caminho até o subnó em disco. */
			NFS_READ_ERROR               ,/**< Erro na leitura de dados no disco. */
			NFS_INVALID_NAME             ,/**< Nome inválido. */
			NFS_EOF_ERROR                ,/**< Informa o fim do arquivo. */
			NFS_OPEN_ERROR               ,/**< Informa que o arquivo não foi aberto */
			NFS_MAKE_ERROR               ,/**< Informa que o arquivo não foi criado */
			ATA_COMMAND_ERROR            ,/**< Erro nas controladoras PATA ou SATA. */
			ATAPI_COMMAND_ERROR          ,/**< Erro nas controladoras PATAPI ou SATAPI. */
			SYSTEM_REBOOT_ERROR          ,/**< Falha no processo de reinicialização. */
			SCHEDULER_INVALID_PROCESS    ,/**< Programa não pode ser executado. */
			EVENT_BUFFER_VIOLATION       ,/**< Falha no sistema de eventos. */
			
			//Falhas na NLIB.
			INDEX_OUT_OF_BOUND_EXCEPTION ,/**< Tentativa de violação de endereço interno da biblioteca. */
			INVALID_REFERENCE_EXCEPTION  ,/**< Tentativa de referenciar um endereço invalido na biblioteca. */	
		};
		
		/** 
		 * Método projetado para informar ao sistema a ocorrência de um erro. Caso o sistema não possua um tratador de 
		 * erros a aplicação será desativada.
		 **/
		static void notify( const tErrorCode code ) {
			setCode(code); //Setando o código do erro.
			
			//Carrega e executando o tratador de erros.
			tListener* listener = getListener();
			if( listener != 0 ) {
				listener();
				
				//Verifica se o tratador limpou o erro.
				if( getCode() == 0 )
					return;
			}

			//Desativa a aplicação.
			Process::kill();
		}
	
		/** Método projetado para retornar o estado atual do processo/systema. */
		static inline const tErrorCode getCode() {
			return (tErrorCode) ((tBCP*) (START_PROG_PTR - sizeof(tBCP)))->status;
		}
		
		/** Método projetado para configurar um código de erro. */
		static inline void setCode( const tErrorCode code ) {
			((tBCP*) (START_PROG_PTR - sizeof(tBCP)))->status = (unsigned int) code;
		}
		
		/** Método projetado para limpar a variável de erro. */
		static inline void clear() {
			((tBCP*) (START_PROG_PTR - sizeof(tBCP)))->status = 0;
		}
		
		/** 
		 * Método projetado para inserir um tratador de error para o prcesso atual. 
		 * @param listener - Tratador de erros.
		 */
		static inline void setListener( const tListener* listener ) {
			((tBCP*) (START_PROG_PTR - sizeof(tBCP)))->errorListener = listener;
		}
		
		/** Método projetado para retornar o tratador de erro do processo atual. */
		static inline const tListener* getListener() {
			return ((tBCP*) (START_PROG_PTR - sizeof(tBCP)))->errorListener;
		}
		
		/** Método projetado para remover o tratador de error do processo atual. */
		static inline void clearListener() {
			((tBCP*) (START_PROG_PTR - sizeof(tBCP)))->errorListener = 0;
		}
	};
}

#endif