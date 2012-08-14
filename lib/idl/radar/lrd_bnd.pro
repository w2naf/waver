;Local Range Determinator (LRD)
FUNCTION LRD_BND,ctrArr,HEIGHT=height,CTRLAT=ctrLat,CTRLON=ctrLon
GEOTOOLS

IF N_ELEMENTS(height) NE 0 THEN hgt = height ELSE hgt = 300.

dims    = SIZE(ctrArr,/DIM)
xdim    = dims[3]
ydim    = dims[4]

result  = FLTARR(4,2,2,xdim,ydim)

;IF N_ELEMENTS(xCtr) EQ 0 THEN xCtr    = FLOOR(xDim/2)-1
;IF N_ELEMENTS(yCtr) EQ 0 THEN yCtr    = FLOOR(yDim/2)-1

IF N_ELEMENTS(ctrLat) EQ 0 THEN RETURN,-1
IF N_ELEMENTS(ctrlon) EQ 0 THEN RETURN,-1

FOR ix=0,1 DO BEGIN
    FOR iy=0,1 DO BEGIN
        FOR xx=0,xdim-1 DO BEGIn
            FOR yy=0,ydim-1 DO BEGIN
                lat     = ctrArr[0,ix,iy,xx,yy]
                lon     = ctrArr[1,ix,iy,xx,yy]
                
                ;SUB_SPHAZM1,ctrLon,ctrLat,hgt,lon,lat,azm,range
                DISTANCE,ctrLat,ctrLon,lat,lon,range
                GETAZM,ctrLat,ctrLon,lat,lon,azm
                azm     = azm * !RADEG

                result[0,ix,iy,xx,yy] = range * SIN(!DTOR*azm)
                result[1,ix,iy,xx,yy] = range * COS(!DTOR*azm)
                result[2,ix,iy,xx,yy] = range
                result[3,ix,iy,xx,yy] = azm
                ;IF xx EQ 7 AND yy EQ 8 THEN STOP
            ENDFOR
        ENDFOR
    ENDFOR
ENDFOR

return,result
END
