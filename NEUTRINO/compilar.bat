@echo off
REM Copyright (C) 2011-2012
REM Alisson Linhares de Carvalho, Wagner Luis de Araújo Menezes Macedo.
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
REM ----------------------------------------------------------------------------

rem cls
python %~dp0%~n0.py 2> NUL

if ERRORLEVEL 1 (
    echo Python não foi encontrado. Se já instalado, configure o PATH do sistema.
    pause
)
