#ifndef PLASMA_H
#define PLASMA_H

#include "animation.h"

class Plasma : public Animation {                 
public:
	Plasma( Canvas *g ) : Animation( g ) {
	
	
	}
	
	virtual void update() {
		int x,y;
		g->setPixelColor( g->getWidth()/2, g->getHeight()/2, frame );

		for(x = 1; x < g->getWidth() - 1; x++ ) 
			for(y = 1; y < g->getHeight() - 1; y++ )
				g->setPixelColor(x,y,(g->getPixelColor(x,y + 1) + g->getPixelColor(x,y - 1) + g->getPixelColor(x + 1,y) + g->getPixelColor(x - 1,y)) / 4);
		
		frame++;
	}
	
protected:

};

#endif