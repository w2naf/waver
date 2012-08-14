PRO PLOT_LRD_BND,positionArr,colorArr                           $
    ,XVALS              = xVals                                 $
    ,YVALS              = yVals                                 $
    ,XTITLE             = xTitle                                $
    ,YTITLE             = ryitle                                $
    ,XRANGE             = xRange                                $
    ,YRANGE             = yRange                                $
    ,XSTYLE             = xStyle                                $
    ,YSTYLE             = yStyle                                $
    ,XTICKINTERVAL      = xTickInterval                         $
    ,xTickLen           = xTickLen                              $
    ,XMINOR             = xMinor                                $
    ,POSITION           = position                              $
    ,_EXTRA             = _extra

xc          = 0
xMin        = MIN(positionArr[xc,*,*,*,*],/NAN)
xMax        = MAX(positionArr[xc,*,*,*,*],/NAN)

yc      = 1
yMin        = MIN(positionArr[yc,*,*,*,*],/NAN)
yMax        = MAX(positionArr[yc,*,*,*,*],/NAN)

IF ~KEYWORD_SET(xRange) THEN xRange = [xMin,xMax]
IF ~KEYWORD_SET(yRange) THEN yRange = [yMin,yMax]

IF ~KEYWORD_SET(xTitle) THEN xTitle = 'Relative Distance [km]'
IF ~KEYWORD_SET(yTitle) THEN yTitle = 'Relative Distance [km]'

IF N_ELEMENTS(xstyle) EQ 0 THEN xStyle = 1
IF N_ELEMENTS(ystyle) EQ 0 THEN yStyle = 1

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
    
    xx      = FLTARR(4)
    xx[0]   = positionArr[xc,0,0,bm,rg]
    xx[1]   = positionArr[xc,0,1,bm,rg]
    xx[2]   = positionArr[xc,1,1,bm,rg]
    xx[3]   = positionArr[xc,1,0,bm,rg]

    yy      = FLTARR(4)
    yy[0]   = positionArr[yc,0,0,bm,rg]
    yy[1]   = positionArr[yc,0,1,bm,rg]
    yy[2]   = positionArr[yc,1,1,bm,rg]
    yy[3]   = positionArr[yc,1,0,bm,rg]

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
