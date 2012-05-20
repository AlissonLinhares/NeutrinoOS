/*---------------------------------------------------------------------------*
 * Copyright (C) 2011-2012 Alisson Linhares de Carvalho.                     *
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

#ifndef STORAGE_H
#define STORAGE_H

#define STORAGE_PAGE_SIZE 512
#define STORAGE_SIGNATURE 0x89ABCDEF
#define STORAGE_NUM_OF_DISKS 6
#define STORAGE_BPU 4 //Total de bits por unidade. "Tamanho do tStorage do kernel".

#include <core.h>

namespace nlib {
	
	/** 
	 * Registro usado para compartilhar informações entre o Kernel Neutrino e a NLIB. Foi projetado para retornar 
	 * informações gerais do sistema de armazenamento.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	struct tStorageInfo {
		const unsigned int signature;
		unsigned char numberOfDisks; /**< Total de unidades montadas. */
			
		struct {
			char type; /**< Formato da unidade [PATA,SATA,PATAPI,SATAPI,SCSI] */ 
			char channel; /**< Posição da unidade. */ 
			unsigned int size; /**< Total de setores da unidade. */ 
		} __attribute__((__packed__)) disk[6]; /**< Array com informações dos discos instalados. */
	
		/** Construtor responsável por inicializar o registro de troca. */
		tStorageInfo() : signature( STORAGE_SIGNATURE ) {
		
		}
	} __attribute__((__packed__));

	/**
	 * Classe responsável por controlar as função básicas do gerente de armazenamento do kernel neutrino. 
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	class Storage {
	public:
		/** 
		 * Método usado para alocar páginas em disco. Retorna o endereço do bloco de páginas ou 0 em caso de erro.
		 * @param drive - Número da unidade. 0...255
		 * @param size - Total de páginas que serão alocadas.
		 */
		static unsigned long allocate( const unsigned char drive, const unsigned int size ) {
			unsigned long result;
			SYS_STORAGE_ALLOCATE_PAGE( drive << STORAGE_BPU, size, result )
			return result;
		}
		
		/** 
		 * Método usado para desalocar páginas em disco. 
		 * @remarks O deallocate pode gerar erros fatais caso não seja corretamente utilizado.
		 * @param drive - Número da unidade. 0...255
		 * @param size - Total de páginas que serão desalocadas.
		 * @param page - Endereço do bloco de páginas.
		 */
		static void deallocate( const unsigned char drive, const unsigned long page, const unsigned int size ) {
			SYS_STORAGE_DEALLOCATE_PAGE( drive << STORAGE_BPU, page, size )
		}
		
		/** Método usado para retornar informações de armazenamento. */
		static inline tStorageInfo getInfo() {
			tStorageInfo result;
			SYS_STORAGE_GET_INFO( &result )
			return result;
		}
	private:
	
	};
}

#endif