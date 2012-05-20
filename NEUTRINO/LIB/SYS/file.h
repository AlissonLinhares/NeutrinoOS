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

#ifndef FILE_H
#define FILE_H

#include <core.h>
#include <error.h>
#include <storage.h>

namespace nlib {

	/** 
	 * Formato de um registro do nfs (neutrino file system).
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	struct tSubNode {
		unsigned int dataPtr; /**< Ponteiro para o bloco de dados em disco. */
		unsigned int size;    /**< Total de páginas usadas pelo bloco. */
		unsigned char type;   /**< Tipo do bloco de páginas. */
		char name[23];        /**< Nome do nó. */
	} __attribute__((__packed__));

	/**
	 * File é uma classe projetada para simplificar o uso do nfs (neutrino file system). Apresenta uma estrutura 
	 * básica de controle de buffer em alto nível, com o intuito de melhorando o desempenho das aplicações.
	 * @author alisson_linhares@hotmail.com
	 *************************************************************************************************************/
	class File {
	public:
		enum tSubNodeType {
			INVALID = 0,
			FOLDER,
			BINARY,
			LIBRARY,
			DATA,
			RESERVED
		};

		/** Construtor padrão. Apenas inicializa as variáveis de controle. */
		File() : unsavedChanges(true), fc(0), cachePos(0)  {

		}

		/** 
		 * Método projetado para abrir nós em disco. 
		 * @remarks “Nós” são blocos de páginas que podem representar qualquer estrutura de dados "pastas, programas etc..."
		 * @param path - String contendo o caminho completo até o nó em disco. Ex.: var->open("a\\prog\\\0");
		 */
		Error::tErrorCode open( const char *path ) {
			close(); //Verifica se existe algum arquivo aberto.
			
			//Abrindo o nó.
			SYS_NFS_OPEN_DATA( fc, path )

			//Se o arquivo for aberto sem erros, é carregada a primeira página do disco.
			if( !fc )
				return Error::NFS_OPEN_ERROR; //Retornando código de erro
			
			SYS_NFS_READ_DATA( fc )
			return (Error::tErrorCode) fc->error;
		}
		
		/**
		 * Método projetado para criar nós em disco. Ex.: var->make( "a\\prog\\\0", "data.bin\0", 4, File::BINARY );
		 * @param path - String contendo o caminho completo até o nó em disco.
		 * @param name - String contendo o nome do nó que será criado.
		 * @param size - Total de páginas reservadas para o arquivo.
		 * @param type - Tipo do nó que será criado.
		 */
		Error::tErrorCode make( const char *path, const char *name, const unsigned int size = 1, const tSubNodeType type = FOLDER ) {
			close(); //Verifica se existe algum arquivo aberto.
			
			//Criando o arquivo em disco e retornando o novo fc.
			SYS_NFS_CREATE_NODE( fc, path, name, size, (unsigned char) type )
			
			//Verifica se o make retornou erro.
			if( !fc )
				return Error::NFS_MAKE_ERROR;

			return (Error::tErrorCode) fc->error;
		}
		
		
		/**
		 * Método projetado para ler uma linha de um arquivo. Ex.: var->readLine( &buffer, 80 );
		 * @param buffer - Variável usada para armazenar o conteúdo do arquivo.
		 * @param size - Tamanho máximo da linha.
		 */
		Error::tErrorCode readLine( char buffer[], int size ) {
			int i;
			
			for( i = 0; (i < size - 1) && !read(&buffer[i]) && buffer[i] != '\n'; i++ ) {
				if( !buffer[i] ) {
					cachePos--; //Coloca o ponteiro antes do final de arquivo.
					return Error::NFS_EOF_ERROR;
				}
			}
			
			buffer[i + 1] = 0;
			return (Error::tErrorCode) fc->error;
		}
		
		/**
		 * Método projetado para ler dados do disco. Ex.: var->read( &buffer );
		 * @param buffer - Variável usada para armazenar o conteúdo do disco.
		 */
		template<class T> 
		Error::tErrorCode read( T *buffer, unsigned int size = sizeof(T) ) {
			unsigned int pos, page;
			
			//Verifica se os atributos são válidos.
			if( fc != 0 && buffer != 0 ) {
				for( pos = 0; pos < size; pos++ ) {
					
					page = (cachePos / STORAGE_PAGE_SIZE);
					
					//Verifica se deve carregar uma nova página.
					if( page != fc->currentPage && loadCache(page) )
						return (Error::tErrorCode) fc->error; //Retornando o código de erro
				
					//Carregando os dados da cache de disco para o buffer. 
					((char*) buffer)[pos] = fc->cache[cachePos % STORAGE_PAGE_SIZE];
					cachePos++;
				}
			}
		
			return (Error::tErrorCode) fc->error;
		}
		
		/**
		 * Método projetado para escrever dados no disco. Ex.: var->write( &buffer );
		 * @param buffer - Ponteiro para o conteúdo que será gravado no disco.
		 */
		template<class T>
		Error::tErrorCode write( const T *buffer, unsigned int size = sizeof(T) ) {
			unsigned int pos, page;
			
			//Verifica se os atributos são válidos.
			if( fc != 0 && buffer != 0 ) {
				for( pos = 0; pos < size; pos++ ) {
					page = ( cachePos / STORAGE_PAGE_SIZE );

					//Verifica se deve carregar uma nova página.
					if( page != fc->currentPage ) {
						if(loadCache(page)) //Salvando e carregando nova cache
							return (Error::tErrorCode) fc->error; //Retornando o código de erro
						
						unsavedChanges = true;
					}
					
					//Movendo dados do buffer para cache de disco
					fc->cache[cachePos++ % STORAGE_PAGE_SIZE] = ((char*) buffer)[pos];
				}
			}
			
			return (Error::tErrorCode) fc->error;
		}
		
		/** Método projetado para fechar o arquivo atual. */
		void close() { 
			if( fc != 0 ) {
				//Caso ocorra erros ao salvar a cache, o buffer é desalocado e o tratador erros será executado
				saveCache(); 
				delete fc;
				fc = 0; //Fazendo o ponteiro apontar para vazio
			}
			
			this->cachePos = 0;
		}
		
		/**
		 * Método projetado para navegar em um nó aberto. Ex.: var->seek( 20 );
		 * @param position - Posição do buffer.
		 */	
		inline void seek( const unsigned long position = 0 ) {
			cachePos = position;
		}

		/** Método projetado para retornar a posição do ponteiro de dentro do arquivo. */
		inline unsigned long ftell() {
			return cachePos;
		}
		
		/** Método projetado para retornar o tamanho em bytes do arquivo atual. */	
		inline const long getSize() const {
			return fc != 0 ? fc->size * STORAGE_PAGE_SIZE : 0;
		}

		/** Método projetado para retornar o tipo do arquivo atual. */
		inline const tSubNodeType getType() const {
			return (tSubNodeType) ( fc != 0 ? fc->type : INVALID );
		}
		
		/** Destrutor padrão */
		~File() {
			close();
		}
		
	protected:
		/** 
		 * Registro usado para compartilhar informações entre o Kernel Neutrino e a NLIB. Foi projetado para retornar 
		 * informações de um arquivo.
		 * @author alisson_linhares@hotmail.com
		 *************************************************************************************************************/
		struct tFileController {
			char cache[STORAGE_PAGE_SIZE]; //Cache compartilhada entre o kernel e os programas.
			unsigned int currentPage;
			unsigned int storage;
			unsigned int dataPtr;
			unsigned int size;
			unsigned char type;
			unsigned char error;
		} __attribute__((__packed__));

		/** Método projetado para salvar o conteúdo da cache em disco. */
		Error::tErrorCode saveCache() {
			if( unsavedChanges ) {
				SYS_NFS_WRITE_DATA( fc )
				
				//Verifica se foi possível salvar a cache em disco.
				if( !fc->error )
					unsavedChanges = false;
			}
			
			return (Error::tErrorCode) fc->error;
		}
		
		/** 
		 * Método projetado para carregar o conteúdo do disco na cache.
		 * @param page - Página que será carregada em memória
		 */
		Error::tErrorCode loadCache( const unsigned int page ) {
			//Salvando as modificações na cache em disco
			if( !saveCache() ) {
				//Carregando nova página do disco na cache
				fc->currentPage = page;
				SYS_NFS_READ_DATA( fc )
			}
			
			return (Error::tErrorCode) fc->error;
		}
		
	//private:
	public:
		bool unsavedChanges;
		long cachePos;
		tFileController *fc;
	};
}

#endif