PRO PLOT_FULL_SPECTRUM
RESTORE,'spect.sav'
sJul    = julVec[0]
fJul    = julVec[nSteps-1]

file    = DIR('output/kmaps/kspect/fullspect.ps',/PS)
SET_FORMAT,/LANDSCAPE,/SARDINES
CLEAR_PAGE,/NEXT

IF KEYWORD_SET(frange) THEN BEGIN
    inx     = WHERE(posFreqVec GE fRange[0] AND posFreqVec LE frange[1],cnt)
    IF cnt NE 0 THEN BEGIN
        posPlotFreqVec      = posFreqVec[inx]
        posPlotSpectArr     = posSpectArr[inx,*,*]
    ENDIF ELSE BEGIN
        posPlotFreqVec      = posFreqVec
        posPlotSpectArr     = posSpectArr
    ENDELSE
ENDIF ELSE BEGIN
    posPlotFreqVec      = posFreqVec
    posPlotSpectArr     = posSpectArr
ENDELSE


npf     = ULONG(N_ELEMENTS(posPlotFreqVec))
nXBins  = nSelBeams * nPf

data            = ABS(posPlotSpectArr)
sd              = STDDEV(data)
mean            = MEAN(data)
scMax           = mean + 2.*sd
specScale       = scMax*[0,1.]
dims            = SIZE(data,/DIM)

image           = GET_COLOR_INDEX(data,PARAM='power',SCALE=specScale,/NAN)
image           = REFORM(image,dims)

posit           = DEFINE_PANEL(1,1,0,0,/BAR)
subtitle        = STRUPCASE(radar) + ' ' + JUL2STRING(sJul) + ' - ' + JUL2STRING(fJul)

PLOT_TITLE,TEXTOIDL('Full Spectrum View'),subTitle
xvals           = FINDGEN(nXBins)
yvals           = FLTARR(nSelGates)
yvals[0]        = nSelGates


PLOT,xvals,yvals,/NODATA                                $
    ,CHARSIZE           = 0.85                          $
    ,XRANGE             = [0,nXBins]                    $
    ,YRANGE             = [0,nSelGates]                 $
    ,YTITLE             = 'Range Gate'                  $
    ,XTICKNAME          = REPLICATE(' ',10)             $
    ,YTICKNAME          = REPLICATE(' ',10)             $
    ,/XSTYLE                                            $
    ,/YSTYLE                                            $
    ,POSITION           = posit


FOR ff=0UL,npf-1 DO BEGIN
    FOR bb=0UL,nSelBeams-1 DO BEGIN
        x0      = ff*nSelBeams + bb
        x1      = x0 + 1
        FOR gg=0UL,nSelGates-1 DO BEGIN
            y0  = gg
            y1  = gg + 1

            xx  = [x0, x0, x1, x1]
            yy  = [y0, y1, y1, y0]

            POLYFILL,xx,yy,COLOR=image[ff,bb,gg],/DATA
        ENDFOR
    ENDFOR
ENDFOR

;X Ticks
maxXTicks       = 10
modX            = CEIL(npf / FLOAT(maxXTicks))

FOR ff=0,npf-1 DO BEGIN
    IF (ff MOD modX) NE 0 THEN CONTINUE
    ff$ = NUMSTR(posPlotFreqVec[ff]*1000.,2)
    t$  = NUMSTR(1./posPlotFreqVec[ff] / 60.)
    xpos        = nSelBeams * ff
    XYOUTS,xpos,-0.035*nSelGates,ff$,/NOCLIP,CHARSIZE=0.70
    XYOUTS,xpos,-0.065*nSelGates,t$,/NOCLIP,CHARSIZE=0.70
ENDFOR
    XYOUTS,nXBins,-0.035*nSelGates,'[mHz]',/NOCLIP,CHARSIZE=0.70
    XYOUTS,nXBins,-0.065*nSelGates,'[min]',/NOCLIP,CHARSIZE=0.70

FOR ff=0,npf-1 DO BEGIN
    OPLOT,ff*nSelBeams*[1,1],[0,nSelGates],THICK=8;,COLOR=GET_WHITE()
ENDFOR

;Y Ticks
maxYTicks       = 10
modY            = CEIL(nSelGates / FLOAT(maxYTicks))

FOR gg=0,nSelGates-1 DO BEGIN
    IF (gg MOD modY) NE 0 THEN CONTINUE
    rg$ = NUMSTR(selGateVec[gg])
    XYOUTS,-0.035*nXBins,gg+0.5,rg$,/NOCLIP,CHARSIZE=0.85
ENDFOR

IF scMax LT 0.1 THEN BEGIN
    level_format = '(E12.1)'
ENDIF ELSE IF scMax LT 8 THEN BEGIN
    level_format = '(F12.2)'
ENDIF ELSE IF N_ELEMENTS(level_format) NE 0 THEN s = TEMPORARY(level_format)

PLOT_COLORBAR,1,1,0,0                                   $
    ,SCALE              = specScale                     $
    ,LEGEND             = 'ABS(Spectral Density)'       $
    ,PARAM              = 'power'                       $
    ,LEVEL_FORMAT       = level_format                  $
    ,CHARSIZE           = 0.75                          $
    ,/KEEP_FIRST_LAST_LABEL

max$            = NUMSTR(MAX(data,/NAN),5)
min$            = NUMSTR(MIN(data,/NAN),5)
mean$           = NUMSTR(MEAN(data),5)
sd$             = NUMSTR(sd,5)
var$            = NUMSTR(sd^2,5)
txt$            = 'Max: ' + max$ + ' Min: ' + min$ + ' Mean: ' + mean$ + TEXTOIDL(' \sigma: ') + sd$ $
                + TEXTOIDL(' \sigma^2: ') + var$

XYOUTS,0.1,0.05,txt$,CHARSIZE=0.75,/NORMAL

txt$            = 'Note: Every frequency bin contains ' + NUMSTR(nSelBeams) + ' beams.'
XYOUTS,0.1,0.03,txt$,CHARSIZE=0.75,/NORMAL

PS_CLOSE
PS2PNG,file,ROTATE=270
END
