#ifndef LINEAR_H
#define LINEAR_H

#include "animation.h" 

class Linear : public Animation {                 
public:
	Linear( Canvas *g ) : Animation( g ) {
		
	}
	
	virtual void update() {
		int x,y;

		for(x = 0; x < g->getWidth(); x++ ) 
			for(y = 0; y < g->getHeight(); y++ )
				g->setPixelColor( x, y, x * y * frame );
		
		frame++;
	}
	
protected:

};

#endif