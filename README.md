[![GNU GPL v3.0](http://www.gnu.org/graphics/lgplv3-88x31.png)](http://www.gnu.org/licenses/lgpl.html)
[![GNU GPL v3.0](http://www.gnu.org/graphics/gplv3-88x31.png)](http://www.gnu.org/licenses/gpl.html)

##
![NeutrinoOs](https://raw.githubusercontent.com/AlissonLinhares/NeutrinoOS/master/NEUTRINO/RES/NeutrinoLogo.png)

### Sobre
<p style="text-indent: 2em;" align="justify">
O projeto neutrino consiste em um agrupamento de conceitos sobre algo pouco explorado nas universidades brasileiras: o desenvolvimento de sistemas operacionais. Trata-se de um kernel multiprogramado, monothread, monolítico, preemptivo, com suporte a modo protegido e interface gráfica. Suportado pelas principais famílias de processadores da arquitetura x86, com ênfase nos processadores superiores à família 486 da Intel, o mesmo visa uma alternativa aos padrões de softwares existentes. Busca obter um maior poder de personalização e um ganho de desempenho em determinadas aplicações com o uso de técnicas avançadas de programação em assembly.
</p>

<p style="text-indent: 2em;" align="justify">
As abordagens utilizadas na construção do kernel possibilita que programas possam executar serviços diretamente sem o intermédio do núcleo. Além disso,do ponto de vista de desenvolvimento, o núcleo oferece um conjunto abundante de códigos, técnicas de programação, organização etc.
</p>


<p style="text-indent: 2em;" align="justify">
O maior benefício trazido por esté projeto é o fato do mesmo ter sido projetado completamente em Assembly x86. Oferecendo assim, uma grande fonte de consulta de algoritmos escritos nessa linguagem, tais como: listas, filas, pilhas, drivers etc.
</p>

<p style="text-indent: 2em;" align="justify">
O kernel é distribuído sob a licença GNUv3. Desta forma, programadores poderão alterar e redistribuir de forma gratuita o núcleo, possibilitando a melhoria contínua desse software. As bibliotecas de integração e interfaces são distribuídas sob a licença Lesser GNUv3, permitindo que desenvolvedores proprietários possam fechar o código das suas aplicações caso, assim, decidam.
</p>

### Compilação
Antes de compilar é necessário instalar os seguintes programas:
1. nasm
2. gcc
3. g++
4. grub-mkrescue
5. virtualbox

Para compilar o projeto, digite:
```sh
./compile.py
```
### Documentação
Documentação da nlib v0.03: <a href="https://github.com/AlissonLinhares/NeutrinoOS/blob/master/NEUTRINO/LIB/DOC/nlib_v0.03.rar?raw=true">nlib_v0.03.rar</a><br>
Documentação do kernel neutrino v0.01: <a href="https://github.com/AlissonLinhares/NeutrinoOS/blob/master/NEUTRINO/KERNEL/DOC/kernel_v0.01.pdf">kernel_v0.01.pdf</a><br>

### Download
LiveCD da versão 0.04 do nos: <a href="https://raw.githubusercontent.com/AlissonLinhares/NeutrinoOS/master/NEUTRINO/RES/LIVE.ISO">LIVE.ISO</a><br>
Imagem de CD do nos v0.04: <a href="https://raw.githubusercontent.com/AlissonLinhares/NeutrinoOS/master/NEUTRINO/RES/CD.ISO">CD.ISO</a><br>
Imagem de disquete do nos v0.04: <a href="https://raw.githubusercontent.com/AlissonLinhares/NeutrinoOS/master/NEUTRINO/RES/FLOPPY.IMG">FLOPPY.IMG</a><br>
Emulador com o Neutrino OS v0.03 (windows/wine): <a href="https://raw.githubusercontent.com/AlissonLinhares/NeutrinoOS/master/NEUTRINO/RES/Qemu.rar">Qemu.rar</a><br>

### Website
link.: https://projetonos.wordpress.com/

##
### Obs.: Essa versão do Neutrino OS foi descontinuada. O kernel será reprogramado em C++ usando o <a href="https://github.com/AlissonLinhares/NativeKit">Native Kit</a>.
