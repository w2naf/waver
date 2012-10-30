;Local Range Determinator (LRD)
FUNCTION LRD,ctrArr,HEIGHT=height,XCTR=xctr,YCTR=yCtr,CTRLAT=ctrLat,CTRLON=ctrLon
GEOTOOLS

IF N_ELEMENTS(height) NE 0 THEN hgt = height ELSE hgt = 300.

dims    = SIZE(ctrArr,/DIM)
xdim    = dims[1]
ydim    = dims[2]

result  = FLTARR(4,xdim,ydim)

;IF N_ELEMENTS(xCtr) EQ 0 THEN xCtr    = FLOOR(xDim/2)-1
;IF N_ELEMENTS(yCtr) EQ 0 THEN yCtr    = FLOOR(yDim/2)-1

xCtr    = FLOOR(xDim/2)-1
yCtr    = FLOOR(yDim/2)-1

ctrLat  = ctrArr[0,xCtr,yCtr]
ctrLon  = ctrArr[1,xCtr,yCtr]

FOR xx=0,xdim-1 DO BEGIn
    FOR yy=0,ydim-1 DO BEGIN
        lat     = ctrArr[0,xx,yy]
        lon     = ctrArr[1,xx,yy]
        
        DISTANCE,ctrLat,ctrLon,lat,lon,range
        GETAZM,ctrLat,ctrLon,lat,lon,azm
        azm     = azm * !RADEG

        result[0,xx,yy] = range * SIN(!DTOR*azm)
        result[1,xx,yy] = range * COS(!DTOR*azm)
        result[2,xx,yy] = range
        result[3,xx,yy] = azm
        ;IF xx EQ 7 AND yy EQ 8 THEN STOP
    ENDFOR
ENDFOR

return,result
END
