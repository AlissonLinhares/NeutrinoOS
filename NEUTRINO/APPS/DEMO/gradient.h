#ifndef GRADIENT_H
#define GRADIENT_H

#include "animation.h" 

class Gradient : public Animation {                 
public:
	Gradient( Canvas *g ) : Animation( g ) {
		color = 1;
	}
	
	virtual void update() {
		int x,y;
		g->setPixelColor( g->getWidth()/2, g->getHeight()/2, frame);

		
		for(x = 0; x < g->getWidth(); x++ ) {
			for(y = 0; y < g->getHeight(); y++ )
				g->setPixelColor(x,y, color);

			if( x % 25 == 0 )
				color++;
		}
		
		frame++;
	}
	
protected:
	unsigned short color;
};

#endif