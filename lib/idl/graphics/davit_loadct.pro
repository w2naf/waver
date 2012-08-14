PRO DAVIT_LOADCT,ct

newct   = ct

black   = [  0,   0,   0]       ;0  
gray    = [200, 200, 190]       ;254
white   = [255, 255, 255]       ;255

LOADCT,newCt
TVLCT,red,green,blue,/GET

red[0]          = black[0]
green[0]        = black[1]
blue[0]         = black[2]

red[254]        = gray[0]
green[254]      = gray[1]
blue[254]       = gray[2]

red[255]        = white[0]
green[255]      = white[1]
blue[255]       = white[2]

TVLCT,red,green,blue

END
