SET_FORMAT,/LANDSCAPE,/SARDINES
CLEAR_PAGE,/NEXT

title   = 'Beam-Linear Interpolation Results'
subtitle        = STRUPCASE(radar) + ' (' + JUL2STRING(scan_startJul) + ')'
PLOT_TITLE,title,subtitle

IF nSelBeams GE 9 THEN plotBeam = 9 ELSE plotBeam = nSelBeams

_xtitle         ='Slant Range [km]'
_ytitle         = GET_DEFAULT_TITLE(param)
_xtickname      = 0
_ytickname      = 0

xrange  = [0,MAX(ctrArr_grid[3,*,*])]

ymax    = MAX(interparr[0:plotBeam-1,*])
yrange  = [0,ymax]

posit   = DEFINE_PANEL(3,3,0,0)
FOR pp=0,plotBeam-1 DO BEGIN
    bm  = selBeamVec[pp]

    GET_RECENT_PANEL, rxmaps, rymaps, rxmap, rymap

    IF rymap EQ (rymaps-1) THEN BEGIN
        xtitle          = _xTitle
        xtickName       = _xTickName
;        IF N_ELEMENTS(_xTickFormat) NE 0 THEN xTickFormat = _xTickFormat
    ENDIF ELSE BEGIN
        xtitle          = ''
        xtickName       = REPLICATE(' ',10)
;        IF N_ELEMENTS(xTickFormat) NE 0 THEN xTickFormat = TEMPORARY(xTickFormat)
    ENDELSE

    IF rxmap EQ 0 THEN BEGIN
        ytitle          = _yTitle
        ytickName       = _yTickName
;        IF N_ELEMENTS(_yTickFormat) NE 0 THEN yTickFormat = _yTickFormat
    ENDIF ELSE BEGIN
        ytitle          = ''
        ;ytickName       = REPLICATE(' ',10)
;        IF N_ELEMENTS(yTickFormat) NE 0 THEN yTickFormat = TEMPORARY(yTickFormat)
    ENDELSE

    PLOT,[0,0]                                                  $
        ,XRANGE = xrange                                        $
        ,YRANGE = yrange                                        $
        ,/XSTYLE                                                $
        ,/YSTYLE                                                $
        ,XCHARSIZE      = 0.5                                   $
        ,YCHARSIZE      = 0.5                                   $
        ,XTITLE         = xtitle                                $
        ,YTITLE         = ytitle                                $
        ,XTICKNAME      = xtickname                             $
        ,YTICKNAME      = ytickname                             $
        ,POSITION       = posit

    ;OPLOT Raw data.
    xVals   = REFORM(ctrArr[3,bm,*])
    yVals   = REFORM(rawArr[bm,*])

    srt         = SORT(xVals)
    xVals       = xVals[srt]
    yVals       = yVals[srt]
    
    good        = WHERE(xvals GE 0)
    xvals       = xvals[good]
    yvals       = yvals[good]

    on          = WHERE(xVals GT dRange[0] AND xVals LT dRange[1])
    OPLOT,xvals[on],yvals[on],PSYM=-6,SYMSIZE=0.3

    off         = WHERE(xVals LE dRange[0],cnt)
    IF cnt NE 0 THEN OPLOT,xvals[off],yvals[off],PSYM=-6,SYMSIZE=0.3,COLOR=GET_GRAY()

    off         = WHERE(xVals GE dRange[1],cnt)
    IF cnt NE 0 THEN OPLOT,xvals[off],yvals[off],PSYM=-6,SYMSIZE=0.3,COLOR=GET_GRAY()

    ;OPLOT Interpolated Data
    xVals   = REFORM(ctrArr_grid[3,bm,*])
    yVals   = REFORM(interpArr[bm,*])

    srt         = SORT(xVals)
    xVals       = xVals[srt]
    yVals       = yVals[srt]

    OPLOT,xvals,yvals,COLOR=GET_RED(),LINESTYLE=2

    str         = 'Beam ' + NUMSTR(bm)
    xpos        = 0.03 * (!X.CRANGE[1] - !X.CRANGE[0])  + !X.CRANGE[0]
    ypos        = 0.92 * (!Y.CRANGE[1] - !Y.CRANGE[0])  + !Y.CRANGE[0]

    XYOUTS,xpos,ypos,str,CHARSIZE = 0.5,/DATA

    IF  pp NE plotBeam-1 THEN posit = DEFINE_PANEL(/NEXT)
ENDFOR

LINE_LEGEND,[0.05,0.0005],['Raw Data (Included)','Raw Data (Excluded)','Beam Interpolated Data']           $
    ,COLOR      = [0,GET_GRAY(),GET_RED()]                              $
    ,LINESTYLE  = [0,0,2]                                                 $
    ,CHARSIZE   = 0.50
