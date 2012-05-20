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
 
#ifndef SHOW_H
#define SHOW_H

#include <file.h>
#include <system.h>
#include <video.h>
#include <memory.h>
#include <storage.h>
#include <process.h>
#include <error.h>
#include "command.h"

/** 
 * Classe projetada para gerenciar o comando show. Responsável por listar informações do sistema. 
 * @author alisson_linhares@hotmail.com
 */
class Show : public Command { 
public:
	/**
	 * Construtor que inicializa o comando show.
	 * @param cmd - Ponteiro para o console.
	 */
	Show( Console* cmd ) : Command( cmd, "show\0", "List informations about the system.\0" ) {

	}
	
	/** Função abstrata definida na classe base. Executa os parâmetros do comando show. */
	virtual CommandResult execute( tListNode *parameters ) {
		while( parameters != 0 ) {
			const char *name = parameters->param->getName();
			
			//Procurando pela função
			if( parameters->param->isEmpty() ) {
				if( strcmp(name,"p\0") == 0 )
					show_p();
				else if( strcmp(name,"k\0") == 0 )
					show_k();
				else if( strcmp(name,"v\0") == 0 )
					show_v();
				else if( strcmp(name,"s\0") == 0 )
					show_s();
				else if( strcmp(name,"m\0") == 0 )
					show_m();
				else if( strcmp(name,"h\0") == 0 )
					help();
				else 
					return INVALID_PARAMETER;
			} else if( name == 0 ) {
				File file;
				
				do {
					//Abrindo arquivo para leitura.
					if(file.open(parameters->param->pop()))
						return SYSTEM_ERROR;
					
					//Verifica se o arquivo é suportado pelo comando show.
					if( file.getType() == File::FOLDER ) {
						show_Folder( file );
					} else if( file.getType() == File::DATA ){
						show_File( file );
					} else {
						return INVALID_VALUE;
					}
					
					file.close();
				} while( !parameters->param->isEmpty() ); 
			} else 
				return INVALID_PARAMETER;

			parameters = parameters->next;
		}
		
		return FINALIZED_WITHOUT_ERROR;
	}

	/** Função abstrata definida na classe base. Imprime informações de ajuda do comando make. */
	void help() const {
		cmd->print("\n"
			" show -p   | List informations about the process management.\n"
			" show -s   | List informations about the storage management.\n"
			" show -m   | List informations about the memory management.\n"
			" show -v   | List informations about the video management.\n"
			" show -k   | List informations about the kernel status.\n"
			" show -h   | List informations about the command show.\n"
			" show path | List informations about a specific file or folder.\n\n\0");
	}
	
private:
	/** Método para listar informações dos processos. */
	void show_p() {
		unsigned int count = 0, memUsage = 0;
		PInfo info;
		
		cmd->print("\n ---------- List of processes --------\n Stack   |Base    |Memory  |Name\n -------------------------------------\n\0");
		
		do {
			cmd->print(' ');
			cmd->print( info.getStackUsage(), 0x10, 8 );
			cmd->print(' ');
			cmd->print( info.getMemoryBase(), 0x10, 8 );
			cmd->print(' ');
			cmd->print( info.getMemoryUsage(), 0x10, 8 );
			cmd->print(' ');
			cmd->print( info.getName() );
			cmd->print('\n');
			
			if(( ++count ) % 18 == 0 )
				cmd->pause();
			
			memUsage += info.getMemoryUsage();
		} while( info.next() );
		
		cmd->print(" -------------------------------------\n Amount of processes: ");
		cmd->print(info.length());
		cmd->print("\n Memory usage: ");
		cmd->print(memUsage);
		cmd->print("\n\n\0");
	}

	/** Método para listar informações do kernel. */
	void show_k() {
		tSysInfo info = System::getInfo();

		cmd->print("\n System status: \0");
		cmd->print(info.status);
		cmd->print("\n System version: \0" );
		cmd->print((unsigned int) info.version / 100 , 0xA, 2);
		cmd->print('.');
		cmd->print((unsigned int) info.version % 100 , 0xA, 2);
		cmd->print("\n System mode: \0");
		cmd->print(info.mode);
		cmd->print("\n\n\0");
	}

	/** Método para listar informações do vídeo. */
	void show_v() {
		tVideoInfo info = Video::getInfo();
		
		cmd->print("\n Video resolution: \0");
		cmd->print(info.width);
		cmd->print('x');
		cmd->print(info.height);
		cmd->print("\n Video address: \0");
		cmd->print((unsigned int) info.memoryPtr, 0x10);
		cmd->print("\n Video bpp: \0");
		cmd->print(info.bpp);
		cmd->print("\n\n\0");
	}

	/** Método para listar informações da memória. */
	void show_m() {
		tMemoryInfo mem = Memory::getInfo();
		
		cmd->print("\n Memory usage: \0");
		cmd->print(mem.usage);
		cmd->print("\n Memory available: \0");
		cmd->print(mem.size);
		cmd->print("\n\n\0");
	}
	
	/** Método para listar informações das unidades. */
	void show_s() {
		tStorageInfo info = Storage::getInfo();
	
		cmd->print("\n ----------- Storage Info -----------\n Disk |C |Size    |Type\n ------------------------------------\n\0");
 
		for( int i = 0; i < info.numberOfDisks; i++ ) {
			cmd->print( ' ' );
			cmd->print( i, 0x10, 0x5 );
			
			if( info.disk[i].channel == 1 || info.disk[i].channel == 3 ) {
				cmd->print( " M  \0" );
			} else {
				cmd->print( " S  \0" );
			}
			
			cmd->print( info.disk[i].size, 0x10, 0x8 );
			
			switch ( info.disk[i].type ) {
				case 1:
					cmd->print( " PATA\0" );
					break;
				case 2:
					cmd->print( " PATAPI\0" );
					break;
				case 3: 
					cmd->print( " SATA\0" );
					break;
				case 4:
					cmd->print( " SATAPI\0" );
					break;
				default:
					cmd->print( " NULL\0" );
			}
			
			cmd->print('\n');
		}

		cmd->print(" ------------------------------------\n\n\0");
	}
		
	/** Método projetado para imprimir o conteúdo de um arquivo texto. */
	void show_File( File &file ) {
		char buffer[81];
		char key;
		cmd->clear();
		
		for( int i = 0; i < 24 && !file.readLine(buffer,81); i++ )
			cmd->print(buffer);
		
		while( !file.readLine(buffer,81) && key != 'q' && key != 'Q') {
			cmd->update();
			key = cmd->readkey();
			cmd->print(buffer);
		}
	}
	
	/** Método para imprimir dados de um diretório. */
	void show_Folder( File &file ) {
		unsigned int totalArq = 0;
		tSubNode reg;

		cmd->print("\n ----------- List of files -----------\n RRN     |Size    |Type|Name\n -------------------------------------\n\0");
		
		while( !file.read(&reg) && reg.dataPtr ) {

			cmd->print(' ');
			cmd->print(reg.dataPtr, 0x10, 0x8);
			cmd->print(' ');
			cmd->print(reg.size, 0x10, 0x8);
			cmd->print(' ');
			cmd->print(reg.type, 0x10, 0x4);
			cmd->print(' ');
			cmd->print(reg.name);
			cmd->print('\n');

			if(( totalArq + 1 ) % 18 == 0 )
				cmd->pause();

			totalArq++;
		}
		
		//Limpando o código de erro em caso de EOF
		Error::clear();
		
		cmd->print(  " -------------------------------------\n Amount of processes: ");
		cmd->print(totalArq);
		cmd->print("\n\n\0");
	}
};

#endif