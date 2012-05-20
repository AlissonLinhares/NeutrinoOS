#ifndef ANIMATION_H
#define ANIMATION_H

#include <canvas.h> 

using namespace nlib;

class Animation {                 
public:
	Animation( Canvas *g ) {
		frame = 0;
		this->g = g;
	}
	
	virtual void update() = 0;
	
protected:
	unsigned int frame;
	Canvas *g;
};

#endif