REM Copyright (C) 2011 Alisson Linhares de Carvalho.
REM All rights reserved.
REM
REM This file is part of the neutrino kernel.
REM
REM The neutrino kernel is free software: you can redistribute it and/or 
REM modify it under the terms of the GNU General Public License as 
REM published by the Free Software Foundation, either version 3 of the 
REM License, or (at your option) any later version.
REM
REM The neutrino kernel is distributed in the hope that it will be useful,
REM but WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
REM GNU General Public License for more details.
REM
REM You should have received a copy of the GNU General Public License
REM along with the neutrino kernel. If not, see <http://www.gnu.org/licenses/>.
REM
REM -------------------------------------------------------------------------------------------

@ECHO OFF

cls
echo 1. Compilando dependencias
echo  1.1. Imagens
NASM\nasm -f bin KERNEL\GUI\NIFS.ASM -o BIN\NIF.BIN

echo 2. Compilando kernel
NASM\nasm -f bin KERNEL\KERNEL.ASM -o BIN\KERNEL.BIN
NASM\nasm -f bin KERNEL\LOADER.ASM -o BIN\LOADER.BIN

echo 3. Gerando imagem de disquete
NASM\nasm -f bin APPS\INSTALLER\MAIN.ASM -o BIN\INSTALLER.BIN
NASM\nasm -f bin APPS\INSTALLER\LOADER.ASM -o BIN\FLOPPY_DISK.IMG

echo 4. Fim
pause 


