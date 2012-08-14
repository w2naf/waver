PRO MULTIPLOT,xDataArr,yDataArr                         $
    ,PLOTBEAM           = plotBeam                      $
    ,PLOTGATE           = plotGate                      $
    ,BEAMARR            = beamArr                       $
    ,GATEARR            = gateArr                       $
    ,GEOMETRY           = geometry                      $
    ,LEGEND             = legend                        $
    ,OPLOT_XAXIS        = oPlot_xAxis                   $
    ,OPLOTARR           = oPlotArr                      $
    ,OPLOTLEGEND        = oPlotLegend                   $
    ,CELLTEXT           = cellText                      $
    ,SORT               = sort                          $
    ,BANDLIM            = bandLim                       $
    ,YRANGE             = _yrangeIn                     $
    ,XTITLE             = _xTitleIn                     $
    ,YTITLE             = _yTitleIn                     $
    ,XTICKNAME          = _xTickNameIn                  $
    ,YTICKNAME          = _yTickNameIn                  $
    ,XTICKFORMAT        = _xTickFormat                  $
    ,YTICKFORMAT        = _yTickFormat                  $
    ,_EXTRA             = _extra

IF ~KEYWORD_SET(_xTitleIN) THEN _xTitle = '' ELSE _xTitle = _xTitleIN
IF ~KEYWORD_SET(_yTitleIN) THEN _yTitle = '' ELSE _yTitle = _yTitleIN
IF ~KEYWORD_SET(_xTickNameIn) THEN _xTickName = 0 ELSE _xTickName = _xTickNameIn
IF ~KEYWORD_SET(_yTickNameIn) THEN _yTickName = 0 ELSE _yTickName = _yTickNameIn

xmaps   = geometry[0]
ymaps   = geometry[1]
posit   = DEFINE_PANEL(xmaps,ymaps,0,0)

beamInxArr      = plotBeam
gateInxArr      = plotGate

;Find the indices of the cells that we want to plot.
FOR kk=0,N_ELEMENTS(plotBeam)-1 DO BEGIN
    IF N_ELEMENTS(beamArr) GT 0 THEN BEGIN
        beamInxArr[kk] = WHERE(beamArr[*,0] EQ plotBeam[kk],cnt) 
        IF cnt EQ 0 THEN CONTINUE
    ENDIF ELSE beamInxArr[kk] = plotBeam[kk]

    IF N_ELEMENTS(gateArr) GT 0 THEN BEGIN
        gateInxArr[kk] = WHERE(gateArr[0,*] EQ plotGate[kk],cnt) 
        IF cnt EQ 0 THEN CONTINUE
    ENDIF ELSE gateInxArr[kk] = plotGate[kk]
ENDFOR

;Auto Y-Ranging
IF ~KEYWORD_SET(_yrangeIn) THEN BEGIN
    yMax    = MAX(yDataArr[*,beamInxArr,gateInxArr],/NAN,MIN=yMin)
    IF KEYWORD_SET(oplotArr) THEN BEGIN
        oMax    = MAX(oPlotArr[*,beamInxArr,gateInxArr],/NAN,MIN=oMin)
    ENDIF ELSE BEGIN
        oMin = 0
        oMax = 0
    ENDELSE

    IF (yMin LT 0) || (oMin LT 0) THEN BEGIN
        yMax        = MAX(ABS(yDataArr[*,beamInxArr,gateInxArr]),/NAN)
        IF KEYWORD_SET(oMax) THEN BEGIN
            oMax        = MAX(ABS(oPlotArr[*,beamInxArr,gateInxArr]),/NAN) 
            IF oMax GT yMax THEN yMax = oMax
        ENDIF
        yrange      = yMax * [-1,1]
    ENDIF ELSE BEGIN
        IF oMax GT yMax THEN yMax = oMax
        yrange = [0, yMax]
    ENDELSE
    yStyle      = 1
ENDIF ELSE yrange = _yrangeIn
    
FOR kk=0,N_ELEMENTS(plotBeam)-1 DO BEGIN
    beamInx     = beamInxArr[kk]
    gateInx     = gateInxArr[kk]
    xData       = xDataArr
    yData       = REFORM(yDataArr[*,beamInx,gateInx])

    GET_RECENT_PANEL, rxmaps, rymaps, rxmap, rymap

    IF rymap EQ (rymaps-1) THEN BEGIN
        xtitle          = _xTitle
        xtickName       = _xTickName
        IF N_ELEMENTS(_xTickFormat) NE 0 THEN xTickFormat = _xTickFormat
    ENDIF ELSE BEGIN
        xtitle          = ''
        xtickName       = REPLICATE(' ',10)
        IF N_ELEMENTS(xTickFormat) NE 0 THEN xTickFormat = TEMPORARY(xTickFormat)
    ENDELSE

    IF rxmap EQ 0 THEN BEGIN
        ytitle          = _yTitle
        ytickName       = _yTickName
        IF N_ELEMENTS(_yTickFormat) NE 0 THEN yTickFormat = _yTickFormat
    ENDIF ELSE BEGIN
        ytitle          = ''
        ;ytickName       = REPLICATE(' ',10)
        IF N_ELEMENTS(yTickFormat) NE 0 THEN yTickFormat = TEMPORARY(yTickFormat)
    ENDELSE

    PLOT,xData,yData                                    $
        ,XTITLE         = xTitle                        $
        ,YTITLE         = yTitle                        $
        ,XTICKNAME      = xTickName                     $
        ,YTICKNAME      = yTickName                     $
        ,XTICKFORMAT    = xTickFormat                   $
        ,YTICKFORMAT    = yTickFormat                   $
        ,YRANGE         = yRange                        $
        ,YSTYLE         = yStyle                        $
        ,_EXTRA         = _extra                        $
        ,POSITION       = posit

    IF KEYWORD_SET(oPlotArr) THEN BEGIN
        IF ~KEYWORD_SET(oPlot_xAxis) THEN oPlot_xAxis = xDataArr
        OPLOT,oPlot_xAxis,oPlotArr[*,beamInx,gateInx],LINESTYLE=2,COLOR=GET_RED()
    ENDIF

    IF KEYWORD_SET(bandLim) THEN BEGIN
        bandLimColor    = GET_GREEN()
        bandLimLineStyle= 2
        bandLimThick    = 3
        OPLOT,bandLim[0]*[1,1],!Y.CRANGE,LINESTYLE=bandLimLineStyle,COLOR=bandLimColor,THICK=bandLimThick
        OPLOT,bandLim[1]*[1,1],!Y.CRANGE,LINESTYLE=bandLimLineStyle,COLOR=bandLimColor,THICK=bandLimThick
    ENDIF



    str         = 'Beam ' + NUMSTR(plotBeam[kk]) + ', Gate ' + NUMSTR(plotGate[kk])
    xpos        = 0.03 * (!X.CRANGE[1] - !X.CRANGE[0])  + !X.CRANGE[0]
    ypos        = 0.92 * (!Y.CRANGE[1] - !Y.CRANGE[0])  + !Y.CRANGE[0]

    XYOUTS,xpos,ypos,str,CHARSIZE = 0.5,/DATA

    IF KEYWORD_SET(cellText) THEN BEGIN
        xpos        = 0.97 * (!X.CRANGE[1] - !X.CRANGE[0])  + !X.CRANGE[0]
        ypos        = 0.92 * (!Y.CRANGE[1] - !Y.CRANGE[0])  + !Y.CRANGE[0]

        XYOUTS,xpos,ypos,cellText[beamInx,gateInx],CHARSIZE = 0.5,/DATA,/ALIGNMENT
    ENDIF

    IF  kk NE N_ELEMENTS(plotBeam)-1 THEN posit = DEFINE_PANEL(/NEXT)
ENDFOR

IF KEYWORD_SET(oPlotLegend) THEN BEGIN
    LINE_LEGEND,[0.05,0.01],oPlotLegend,COLOR=GET_RED(),LINESTYLE=2
ENDIF

IF KEYWORD_SET(bandLim) THEN BEGIN
    xpos = 0.05
    IF KEYWORD_SET(oPlotLegend) THEN xpos += 0.20
    str = NUMSTR(bandLim[0],1) + '-' + NUMSTR(bandlim[1],1) + ' mHz'
    LINE_LEGEND,[xpos,0.01],str                         $
        ,LINESTYLE      = bandLimLineStyle              $
        ,COLOR          = bandLimColor                  $
        ,THICK          = bandLimThick                  $
        ,CHARSIZE       = 0.65                          $
        ,TITLE          = 'Band Limits'
ENDIF

END
