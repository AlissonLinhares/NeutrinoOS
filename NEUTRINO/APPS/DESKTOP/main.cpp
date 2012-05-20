#include "nanojpeg.h" //biblioteca não pertencente ao projeto neutrino.
#include <video.h>
#include <file.h>

using namespace nlib;

void clearDesktop() {
	Video::clear(0xFFFF);
	Video::reset();
}

inline short getRGB16( const unsigned char r, const unsigned char g, const unsigned char b ) {
	return ((r >> 3) | ((g >> 2) << 5) | ((b >> 3) << 11));
}

//Função principal;
int main(void) {
	File f;
	
	if( !f.open("a\\home\\desktop.jpg\0") ) {
		unsigned char* imgPtr;
		int size = f.getSize();
		
		char* buffer = new char[size + 1];
		f.read(buffer,size); //Carregando o arquivo .jpg no buffer

		//Iniciando a NanoJpeg
		njInit();
	
		if( !njDecode(buffer,size) && (imgPtr = njGetImage()) ) {
			//Convertendo de RGB24 para RGB16
			int i,j;
			for( i = 0, j = 0; i < njGetWidth() * njGetHeight(); i++, j += 3 )
				((short*)imgPtr)[i] = getRGB16( imgPtr[j +  2], imgPtr[j + 1], imgPtr[j] );
			
			//Pintando RGB16 no vídeo.
			Video::drawBitmap( (char*) imgPtr );
		} else {
			clearDesktop();
		}
		
		//Desalocando dados usados.
		njDone();
		f.close();
		delete buffer;
	} else {
		clearDesktop();
	}
	
	return 0;
}