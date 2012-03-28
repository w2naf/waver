PRO PLOT_GATE_BEAM,positionArr,colorArr                         $
    ,XVALS              = xVals                                 $
    ,YVALS              = yVals                                 $
    ,XTITLE             = xTitle                                $
    ,YTITLE             = ryitle                                $
    ,XRANGE             = xRange                                $
    ,YRANGE             = yRange                                $
    ,XSTYLE             = xStyle                                $
    ,YSTYLE             = yStyle                                $
    ,XCOORDS            = xCoords                               $
    ,YCOORDS            = yCoords                               $
    ,XTICKINTERVAL      = xTickInterval                         $
    ,xTickLen           = xTickLen                              $
    ,XMINOR             = xMinor                                $
    ,POSITION           = position                              $
    ,_EXTRA             = _extra

IF ~KEYWORD_SET(xcoords) THEN xcoords = 'beam'
IF ~KEYWORD_SET(ycoords) THEN ycoords = 'gate'

IF xcoords NE 'beam' THEN BEGIN
    xc          = 1
    xMin        = MIN(positionArr[xc,*,*,*,*],/NAN)
    xMax        = MAX(positionArr[xc,*,*,*,*],/NAN)
ENDIF ELSE BEGIN
    IF ~KEYWORD_SET(xVals) THEN xVals = FINDGEN(N_ELEMENTS(colorArr[*,0]))
    xMin        = MIN(xVals)
    xMax        = MAX(xVals)+1

    IF N_ELEMENTS(xTickInterVal) EQ 0 THEN xTickInterval = 1
    IF N_ELEMENTS(xTickLen) EQ 0      THEN xTickLen      = 1
    IF N_ELEMENTS(xMinor) EQ 0        THEN xMinor        = 1
    IF N_ELEMENTS(xStyle) EQ 0        THEN xStyle        = 1
ENDELSE

IF yCoords NE 'gate' THEN BEGIN
    CASE ycoords OF
        'rang': yc  = 3
         'lat': yc  = 0
    ENDCASE
    yMin        = MIN(positionArr[yc,*,*,*,*],/NAN)
    yMax        = MAX(positionArr[yc,*,*,*,*],/NAN)
ENDIF ELSE BEGIN
    IF ~KEYWORD_SET(yVals) THEN yVals = FINDGEN(N_ELEMENTS(colorArr[0,*]))
    yMin        = MIN(yVals)
    yMax        = MAX(yVals)+1
    IF N_ELEMENTS(yStyle) EQ 0        THEN yStyle        = 1
ENDELSE

IF ~KEYWORD_SET(xRange) THEN xRange = [xMin,xMax]
IF ~KEYWORD_SET(yRange) THEN yRange = [yMin,yMax]

IF ~KEYWORD_SET(xTitle) THEN BEGIN
    CASE xCoords OF
        'beam': xTitle = 'Beam'
         'lon': xTitle = 'Longitude [deg]'
    ENDCASE
ENDIF

IF ~KEYWORD_SET(yTitle) THEN BEGIN
    CASE ycoords OF
        'gate': yTitle = 'Range Gate'
        'rang': yTitle = 'Slant Range [km]'
        'lat' : yTitle = 'Latitude [deg]'
    ENDCASE
ENDIF

PLOT,[0,0],/NODATA                                              $
    ,XTITLE             = xTitle                                $
    ,YTITLE             = yTitle                                $
    ,XRANGE             = xRange                                $
    ,YRANGE             = yRange                                $
    ,POSITION           = position                              $
    ,XTICKINTERVAL      = xTickInterval                         $
    ,XTICKLEN           = xTickLen                              $
    ,XMINOR             = xMinor                                $
    ,XSTYLE             = xStyle                                $
    ,YSTYLE             = yStyle                                $
    ,COLOR              = GET_BACKGROUND()                      $
    ,_EXTRA             = _extra

FOR dd=0,N_ELEMENTS(colorArr)-1 DO BEGIN
    IF colorArr[dd] EQ GET_BACKGROUND() THEN CONTINUE
    bmGate      = ARRAY_INDICES(colorArr,dd)
    bm          = bmGate[0]
    rg          = bmGate[1]
    
    IF xCoords NE 'beam' THEN BEGIN
        xx      = FLTARR(4)
        xx[0]   = positionArr[xc,0,0,bm,rg]
        xx[1]   = positionArr[xc,0,1,bm,rg]
        xx[2]   = positionArr[xc,1,1,bm,rg]
        xx[3]   = positionArr[xc,1,0,bm,rg]
    ENDIF ELSE BEGIN
        xx      = xVals[bm] + [0,0,1,1]
    ENDELSE

    IF yCoords NE 'gate' THEN BEGIN
        yy      = FLTARR(4)
        yy[0]   = positionArr[yc,0,0,bm,rg]
        yy[1]   = positionArr[yc,0,1,bm,rg]
        yy[2]   = positionArr[yc,1,1,bm,rg]
        yy[3]   = positionArr[yc,1,0,bm,rg]
    ENDIF ELSE BEGIN
        yy      = yVals[rg] + [0,1,1,0]
    ENDELSE
    POLYFILL,xx,yy,COLOR=colorArr[dd],NOCLIP=0,/DATA
ENDFOR

;Plot again to make axes nice.
PLOT,[0,0],/NODATA                                              $
    ,XTITLE             = xTitle                                $
    ,YTITLE             = yTitle                                $
    ,XRANGE             = xRange                                $
    ,YRANGE             = yRange                                $
    ,POSITION           = position                              $
    ,XTICKINTERVAL      = xTickInterval                         $
    ,XTICKLEN           = xTickLen                              $
    ,XMINOR             = xMinor                                $
    ,XSTYLE             = xStyle                                $
    ,YSTYLE             = yStyle                                $
    ,_EXTRA             = _extra

END
