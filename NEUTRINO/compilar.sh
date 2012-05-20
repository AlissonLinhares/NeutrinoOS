#!/bin/bash
#
# Copyright (C) 2011-2012
# Alisson Linhares de Carvalho, Wagner Luis de Araújo Menezes Macedo.
# All rights reserved.
#
# This file is part of the neutrino kernel.
#
# The neutrino kernel is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# The neutrino kernel is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the neutrino kernel. If not, see <http://www.gnu.org/licenses/>.
#
#--------------------------------------------------------------------------------------------

# Parâmetro do bash que aborta o script se algum comando falhar (retornar != 0)
set -e

FLAGS_GCC="-fno-exceptions -fno-stack-protector -fno-rtti -fpermissive -m32"
OPTIONS_GCC="-I LIB/ -I LIB/UTIL -I LIB/GUI -I LIB/SYS -g -O2 -DNDEBUG"
OPTIONS_LD="-melf_i386 -T LIB/link.ld BIN/crt0.O"

OLD_DIR=$(pwd)
DIR="$(dirname "$0")"

cd "$DIR"

echo "1. Compilando dependencias"
echo " 1.1. Imagens"
nasm -f bin KERNEL/GUI/NIFS.ASM -o BIN/NIF.BIN

echo " 1.2. CRT0"
nasm -faout LIB/crt0.s -o BIN/crt0.O

echo "2. Compilando programas"
echo " 2.1. Terminal"
g++ $OPTIONS_GCC -c APPS/CMD/main.cpp $FLAGS_GCC -o BIN/CMD.O
ld $OPTIONS_LD BIN/CMD.O -o BIN/CMD.BIN
#ndisasm BIN/CMD.BIN -b 32

echo " 2.2. Desktop"
g++ $OPTIONS_GCC -c APPS/DESKTOP/main.cpp $FLAGS_GCC -o BIN/DESKTOP.O
ld $OPTIONS_LD BIN/DESKTOP.O -o BIN/DESKTOP.BIN
#ndisasm BIN/DESKTOP.BIN -b 32

echo " 2.3. Exemplos"
g++ $OPTIONS_GCC -c APPS/DEMO/main.cpp $FLAGS_GCC -o BIN/DEMO.O
ld $OPTIONS_LD BIN/DEMO.O -o BIN/DEMO.BIN
#ndisasm BIN/DEMO.BIN -b 32

echo "3. Compilando kernel"
nasm -f bin KERNEL/KERNEL.ASM -o BIN/KERNEL.BIN
nasm -f bin KERNEL/LOADER.ASM -o BIN/LOADER.BIN

rm BIN/*.ISO

echo "4. Gerando imagem de disquete"
nasm -f bin APPS/INSTALLER/MAIN.ASM -o BIN/INSTALLER.BIN
nasm -f bin APPS/INSTALLER/LOADER.ASM -o BIN/FLOPPY_DISK.IMG

echo "5. Gerando imagem de cd"
mkisofs -quiet -o BIN/CD.ISO -A NeutrinoOS -b FLOPPY_DISK.IMG BIN/

echo "6. Gerando live cd"
nasm -f  bin KERNEL/LOADER.ASM -dBOOT_FROM=CD -o BIN/LOADER.BIN
mkisofs -quiet -R -no-emul-boot -boot-load-size 1 -o BIN/LIVE.ISO -A NeutrinoOS -b LOADER.BIN BIN/

rm BIN/*.BIN
rm BIN/*.O

virtualbox --startvm NeutrinoOS

echo "7. Fim"
read -p "<Pressione qualquer tecla para continuar>"

cd $OLD_DIR