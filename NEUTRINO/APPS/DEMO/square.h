#ifndef SQUARE_H
#define SQUARE_H

#include "animation.h" 

class Square : public Animation {                 
public:
	Square( Canvas *g ) : Animation( g ) {
		disp = 1;
	}
	
	virtual void update() {
		int x,y;
		g->setPixelColor( g->getWidth()/2, g->getHeight()/2, frame );

		for(x = 0; x < g->getWidth(); x++ ) 
			for(y = 0; y < g->getHeight(); y++ )
				g->setPixelColor(x,y,x * y % disp);
		
		if( frame % 100 == 0 ) 
			disp < 255  ? disp++ : disp = 1;
			
		frame++;
	}

protected:
	unsigned char disp;
};

#endif               
