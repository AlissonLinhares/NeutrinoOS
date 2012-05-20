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

# Parâmetros de compilação
FLAGS_GCC="-fno-exceptions -fno-stack-protector -fno-rtti -fpermissive -m32"
OPTIONS_GCC="-I LIB/ -I LIB/UTIL -I LIB/GUI -I LIB/SYS -g -O2 -DNDEBUG"
OPTIONS_LD="-melf_i386 -T LIB/link.ld BIN/crt0.O"

# Salva o local do diretório atual
OLD_DIR=$PWD

# Entra no diretório de compilação
DIR=$(dirname "$0")
cd "$DIR"

# Se a pasta BIN não existir, cria
[ -e BIN ] || mkdir BIN

echo "1. Compilando dependencias"
echo " 1.1. Imagens"
nasm -f bin KERNEL/GUI/NIFS.ASM -o BIN/NIF.BIN

echo " 1.2. CRT0"
nasm -faout LIB/crt0.s -o BIN/crt0.O

# Loop sobre todos os diretórios dentro de APPS, compilando quando acha main.cpp
echo "2. Compilando programas"
for app_dir in APPS/*; do
    if [ -f "$app_dir"/main.cpp ]; then
        app_name=$(basename "$app_dir")

        g++ $OPTIONS_GCC -c "$app_dir"/main.cpp $FLAGS_GCC -o BIN/"$app_name".O
        ld $OPTIONS_LD BIN/"$app_name".O -o BIN/"$app_name".BIN

        # Progresso
        echo -n "."
    fi
done
echo

echo "3. Compilando kernel"
nasm -f bin KERNEL/KERNEL.ASM -o BIN/KERNEL.BIN
nasm -f bin KERNEL/LOADER.ASM -o BIN/LOADER.BIN

# Remove todos os arquivos ISO existentes
rm BIN/*.ISO 2> /dev/null || true # hack para não abortar se comando falhar

echo "4. Gerando imagem de disquete"
nasm -f bin APPS/INSTALLER/MAIN.ASM -o BIN/INSTALLER.BIN
nasm -f bin APPS/INSTALLER/LOADER.ASM -o BIN/FLOPPY_DISK.IMG

echo "5. Gerando imagem de cd"
mkisofs -quiet -o BIN/CD.ISO -A NeutrinoOS -b FLOPPY_DISK.IMG BIN/

echo "6. Gerando live cd"
nasm -f  bin KERNEL/LOADER.ASM -dBOOT_FROM=CD -o BIN/LOADER.BIN
mkisofs -quiet -R -no-emul-boot -boot-load-size 1 -o BIN/LIVE.ISO -A NeutrinoOS -b LOADER.BIN BIN/

# Remove arquivos temporários
rm BIN/*.BIN
rm BIN/*.O

# Inicia a máquina virtual
#virtualbox --startvm NeutrinoOS

echo "7. Fim"
read -p "<Pressione qualquer tecla para continuar>"

# Volta ao diretório que o usuário estava
cd "$OLD_DIR"
