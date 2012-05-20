#include <canvas.h>
#include <panel.h>
#include <button.h> 
#include <label.h>
#include <system.h>

#include "animation.h"
#include "plasma.h"
#include "linear.h"
#include "gradient.h"
#include "square.h"

#define TOTAL_ANIME 4
#define VIDEO_AREA_W 280
#define VIDEO_AREA_H 280

using namespace nlib;

unsigned char anim = 0;
char fpsStr[] = {'F','p','s',':',' ','0','0','0','0','0','0','0','0','\0'};
	
//Procedimento para trocar de anima��o; 
void nextAnim() {
	anim >= TOTAL_ANIME - 1 ? anim = 0 : anim++; //Escolhendo a pr�xima anima��o;
}

//Procedimento para trocar de anima��o;
void priorAnim() {
	anim <= 0 ? anim = TOTAL_ANIME - 1 : anim--; //Escolhendo a anima��o anterior;
}

int main(void) {
	char i;
	unsigned int fps = 0;
	unsigned int frame = 0;
	unsigned int lastTime = 0;
	unsigned int currentTime = 0;

	//Criando um bot�o "prior" e inserindo um tratador;
	Button *prior = new Button( 2, 18, 38, 20, "prior\0" );
	prior->setListener( priorAnim, Component::ON_MOUSE_DOWN_L );
	
	//Criando um bot�o "next" e inserindo um tratador;
	Button *next = new Button( 42, 18, 34, 20, "next\0" );
	next->setListener( nextAnim, Component::ON_MOUSE_DOWN_L );

	//Criando um label para renderizar o total de fps;
	Label *fpsLabel = new Label( 90, 20, 100, 20, fpsStr ) ;
	
	//Criando uma tela gr�fica;
	Canvas *g = new Canvas( 2, 40, VIDEO_AREA_W, VIDEO_AREA_H );
	g->clear(0);
	
	//Criando um painel e inserindo todos os componentes;
	Panel *panel = new Panel( 10, 10, 284, 322, "C++ Canvas exemplo\0" );
	panel->add(prior);
	panel->add(next);
	panel->add(fpsLabel);
	panel->add(g);
	panel->open();
	panel->draw();
	
	//Criando um array de anima��es;
	Animation *animation[] = { new Plasma( g ), new Linear( g ), new Gradient( g ), new Square( g ) };
	
	//Update loop;
	do {
		animation[anim]->update(); //Renderizando o pr�ximo quadro;
		panel->draw(g);            //Renderizando a GraphicArea;
		
		//Carregando a hora do sistema;
		tTimerFormat timer = System::getTimer();
		currentTime = timer.seconds + timer.minutes * 60;
	
		//Verifica se o tempo atual � maior que o anterior;
		if( currentTime > lastTime ) {
			fps = frame / (currentTime - lastTime); //Calculando o total de fps;
			lastTime = currentTime;
			frame = 0; //Resetando o frame;

			//Converte de int para char;
			for( i = 13; i >= 5; i-- ) {
				if ( fps > 0 ) {
					fpsStr[i] = fps % 10 + '0';
					fps = fps / 10;
				} else
					fpsStr[i] = '0';
			}	

			//Escrevendo o fps na tela;
			panel->draw(fpsLabel);
		} else	
			frame++;
			
	} while( true );
	
	return 0;
}
