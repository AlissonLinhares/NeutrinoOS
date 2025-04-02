[![GNU GPL v3.0](http://www.gnu.org/graphics/lgplv3-88x31.png)](http://www.gnu.org/licenses/lgpl.html)
[![GNU GPL v3.0](http://www.gnu.org/graphics/gplv3-88x31.png)](http://www.gnu.org/licenses/gpl.html)

##
![NeutrinoOs](https://raw.githubusercontent.com/AlissonLinhares/NeutrinoOS/master/NEUTRINO/RES/NeutrinoLogo.png)

### About
<p style="text-indent: 2em;" align="justify">
Neutrino OS is a multiprogrammed, single-threaded, monolithic, preemptive operating system with support for protected mode and a graphical interface. It is compatible with processors superior to Intel’s 486 family, and it provides an alternative implementation to existing operating system software standards. The project aims to offer greater customization capabilities and performance improvements in certain applications by using advanced assembly programming techniques.
</p>

<p style="text-indent: 2em;" align="justify">
The approaches used in the kernel’s construction allow programs to execute services directly without the kernel's intervention. Additionally, from a development perspective, the kernel offers a vast collection of code, programming techniques, organization, and more.
</p>

<p style="text-indent: 2em;" align="justify">
The greatest benefit of this project is that it has been entirely designed in x86 Assembly. As a result, it serves as a valuable reference for algorithms written in this instruction set, such as lists, queues, stacks, drivers, etc.
</p>

<p style="text-indent: 2em;" align="justify">
The kernel is distributed under the GPLv3 license. This allows programmers to modify and redistribute the core for free, enabling continuous improvements to the software. The integration libraries and interfaces are distributed under the Lesser GPLv3 license, allowing proprietary developers to keep their application code closed if they choose to do so.
</p>

### Screenshots
<p align="center">
  <img src="https://raw.githubusercontent.com/AlissonLinhares/NeutrinoOS/master/NEUTRINO/RES/NeutrinoA.png" width="45%">
  <img src="https://raw.githubusercontent.com/AlissonLinhares/NeutrinoOS/master/NEUTRINO/RES/NeutrinoB.png" width="45%">
  <br>
  <img src="https://raw.githubusercontent.com/AlissonLinhares/NeutrinoOS/master/NEUTRINO/RES/NeutrinoC.png" width="45%">
  <img src="https://raw.githubusercontent.com/AlissonLinhares/NeutrinoOS/master/NEUTRINO/RES/NeutrinoD.png" width="45%">
</p>

### Compilation
Before compiling the kernel, make sure you have the following programs installed:
1. nasm
2. gcc
3. g++
4. grub-mkrescue
5. virtualbox

To compile the project, type:
```sh
./compile.py
```
### Documentation
*(Portuguese only)* nlib v0.03: <a href="https://github.com/AlissonLinhares/NeutrinoOS/blob/master/NEUTRINO/LIB/DOC/nlib_v0.03.rar?raw=true">nlib_v0.03.rar</a><br>
*(Portuguese only)* Neutrino kernel v0.01: <a href="https://github.com/AlissonLinhares/NeutrinoOS/blob/master/NEUTRINO/KERNEL/DOC/kernel_v0.01.pdf">kernel_v0.01.pdf</a><br>

### Download
LiveCD v0.04: <a href="https://raw.githubusercontent.com/AlissonLinhares/NeutrinoOS/master/NEUTRINO/RES/LIVE.ISO">LIVE.ISO</a><br>
Installation CD v0.04: <a href="https://raw.githubusercontent.com/AlissonLinhares/NeutrinoOS/master/NEUTRINO/RES/CD.ISO">CD.ISO</a><br>
Installation 1.44MB Floppy Disk: <a href="https://raw.githubusercontent.com/AlissonLinhares/NeutrinoOS/master/NEUTRINO/RES/FLOPPY.IMG">FLOPPY.IMG</a><br>
Qemu Configured with the Neutrino OS v0.03 (windows/wine): <a href="https://raw.githubusercontent.com/AlissonLinhares/NeutrinoOS/master/NEUTRINO/RES/Qemu.rar">Qemu.rar</a><br>

### Website
*(Portuguese only)* link.: https://projetonos.wordpress.com/

##
### Note: This version of Neutrino OS has been discontinued. The kernel will be reprogrammed in C++ using the <a href="https://github.com/AlissonLinhares/NativeKit">Native Kit</a>.
