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

OUTPUT_FORMAT("binary")
ENTRY(__start)
SECTIONS {
	. = 0x1000; /* Iniciando o bin em 0x1000 */
	.text : {
		*(.text)
	}

	.rodata : { 
		*(.rodata)
	}

	.data : { 
		*(.data)
		*(.bss) /* Colocando os dados não inicializados depois dos dados inicializados */
		*(COMMON)
	}

	/DISCARD/ : {
		*(.comment)
		*(.eh_frame) /* Removendo suporte para rtti e exceptions */
	}
}