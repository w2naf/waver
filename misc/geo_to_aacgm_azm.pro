FUNCTION GEO_TO_AACGM_AZM,gLat,gLon,gAzm
GEOTOOLS

IF ~KEYWORD_SET(height) THEN height = 300.
IF ~KEYWORD_SET(distance) THEN distance = 1000.


np      = N_ELEMENTS(gLat)
mAzm    = FLTARR(np)

FOR kk=0,np-1 DO BEGIN
    glat0       = gLat[kk]
    gLon0       = gLon[kk]
    gAzm0       = gAzm[kk]

    GETENDPOINT,gLat0,gLon0,gAzm0,distance,gLat1,gLon1

    aacgm0      = CNVCOORD(gLat0,gLon0,height)
    aacgm1      = CNVCOORD(gLat1,gLon1,height)

    GETAZM,aacgm0[0],aacgm0[1],aacgm1[0],aacgm1[1],mAzm0
    mAzm[kk]    = mAzm0
ENDFOR
mAzm    = mAzm * !RADEG

RETURN,mAzm
END
