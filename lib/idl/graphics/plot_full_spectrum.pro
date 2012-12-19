PRO PLOT_FULL_SPECTRUM
RESTORE,'spect.sav'
IF N_ELEMENTS(bandLim) NE 2 THEN bandLim = [0,0]
sJul    = julVec[0]
fJul    = julVec[nSteps-1]

file    = DIR('output/kmaps/kspect/fullspect.ps',/PS)

LOADCT,GET_NAMES=ctNames
;FOR ct=0,39 DO BEGIN
ct=1    ;Blue/white color table.
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

image           = GET_COLOR_INDEX(data,PARAM='power',SCALE=specScale,/CONTINUOUS,/NAN)
image           = REFORM(image,dims)

IF bandLim[0] NE bandLim[1] AND ~KEYWORD_SET(fir_filter) THEN BEGIN
  bl0_inx = WHERE(posPlotFreqVec GE bandLim[0],cnt)
  IF cnt GT 0 THEN BEGIN
    bl0_inx = bl0_inx[0]
    bl0 = posPlotFreqVec[bl0_inx]
  ENDIF ELSE bl0 = !VALUES.F_NAN

  bl1_inx = WHERE(posPlotFreqVec LE bandLim[1],cnt)
  IF cnt GT 0 THEN BEGIN
    bl1_inx = bl1_inx[cnt-1]
    bl1 = posPlotFreqVec[bl1_inx]
  ENDIF ELSE bl1 = !VALUES.F_NAN
ENDIF ELSE BEGIN
  bl0_inx = 0
  bl0 = posPlotFreqVec[bl0_inx]
  bl1_inx = N_ELEMENTS(posPlotFreqVec)-1
  bl1 = posPlotFreqVec[bl1_inx]
ENDELSE

;Average PSD
avg_psd         = FLTARR(nPf)
FOR ff=bl0_inx,bl1_inx DO avg_psd[ff] = MEAN(data[ff,*,*])
avg_psd         = avg_psd/MAX(avg_psd) * scMax
avg_image       = GET_COLOR_INDEX(avg_psd,PARAM='power',SCALE=specScale,/CONTINUOUS,/NAN)


posit           = DEFINE_PANEL(1,1,0,0,/BAR)

subtitle        = STRUPCASE(radar) + ' ' + CAPITAL(param) + ' (' + JUL2STRING(sJul,/SHORT) + ' to ' + JUL2STRING(fJul,/SHORT)+')'

IF bandLim[0] NE bandLim[1] THEN BEGIN
  bl$ = 'Band: ' + NUMSTR(bandLim[0]*1000.,2) + ' - ' + NUMSTR(bandLim[1]*1000.,2) + ' mHz'
  IF KEYWORD_SET(fir_filter) THEN bl$ = 'Digital Filter '+bl$
  subtitle = subtitle + '!C' + bl$
ENDIF

;New color tables!!

DAVIT_LOADCT,ct
PLOT_TITLE,TEXTOIDL('Full Spectrum View'),subTitle
xvals           = FINDGEN(nXBins)
yvals           = FLTARR(nSelGates)
yvals[0]        = nSelGates


PLOT,xvals,yvals,/NODATA                                $
    ,CHARSIZE           = 0.85                          $
    ,XRANGE             = [0,nXBins]                    $
    ,YRANGE             = [0,nSelGates+1]               $
    ,YTITLE             = 'Range Gate'                  $
    ,XTICKS             = 1                             $
    ,YTICKS             = 1                             $
    ,XTICKNAME          = REPLICATE(' ',10)             $
    ,YTICKNAME          = REPLICATE(' ',10)             $
    ,/XSTYLE                                            $
    ,/YSTYLE                                            $
    ,POSITION           = posit

;Plot Spectrum
sep     = 0.1
FOR ff=0UL,npf-1 DO BEGIN
    FOR bb=0UL,nSelBeams-1 DO BEGIN
        x0      = nSelBeams*(ff + 0.5*sep) + bb*(1-sep)
        x1      = x0 + (1-sep)
        FOR gg=0UL,nSelGates-1 DO BEGIN
            y0  = gg
            y1  = gg + 1

            xx  = [x0, x0, x1, x1]
            yy  = [y0, y1, y1, y0]

            POLYFILL,xx,yy,COLOR=image[ff,bb,gg],/DATA
        ENDFOR
    ENDFOR
ENDFOR

;Plot average values.
DAVIT_LOADCT,22
FOR ff=0UL,npf-1 DO BEGIN
    x0      = nSelBeams*(ff + 0.5*sep)
    x1      = x0 + nSelBeams*(1-sep)
    y0      = nSelGates
    y1      = nSelGates + 1
    xx      = [x0, x0, x1, x1]
    yy      = [y0, y1, y1, y0]
    POLYFILL,xx,yy,COLOR=avg_image[ff],/DATA
ENDFOR
DAVIT_LOADCT,ct

;X Ticks
maxXTicks       = 10
modX            = CEIL(npf / FLOAT(maxXTicks))

fCharSize= 0.60
FOR ff=0,npf-1 DO BEGIN
    IF (ff MOD modX) NE 0 THEN CONTINUE
    ff$ = NUMSTR(posPlotFreqVec[ff]*1000.,2)
    t$  = NUMSTR(1./posPlotFreqVec[ff] / 60.)
    xpos        = nSelBeams * (ff + 0.1) 
    XYOUTS,xpos,-0.035*nSelGates,ff$,/NOCLIP,CHARSIZE=fCharSize
    XYOUTS,xpos,-0.065*nSelGates,t$,/NOCLIP,CHARSIZE=fCharSize
ENDFOR
    XYOUTS,nXBins,-0.035*nSelGates,'freq [mHz]',/NOCLIP,CHARSIZE=fCharSize
    XYOUTS,nXBins,-0.065*nSelGates,'Per. [min]',/NOCLIP,CHARSIZE=fCharSize

;Plot separator bars.
FOR ff=0,npf-1 DO BEGIN
    OPLOT,ff*nSelBeams*[1,1],[-0.5,nSelGates+1],THICK=4,NOCLIP=1;,COLOR=GET_WHITE()
ENDFOR

;Plot bandlimit box.
RAD_LOAD_COLORTABLE
IF bandLim[0] NE bandLim[1] AND ~KEYWORD_SET(fir_filter) THEN BEGIN
  blThick=8
  OPLOT,bl0_inx*nSelBeams*[1,1],[0,nSelGates],THICK=blThick,NOCLIP=1,COLOR=GET_RED()
  OPLOT,(bl1_inx+1)*nSelBeams*[1,1],[0,nSelGates],THICK=blThick,NOCLIP=1,COLOR=GET_RED()
  OPLOT,[bl0_inx*nSelBeams,(bl1_inx+1)*nSelBeams],[0,0],THICK=blThick,NOCLIP=1,COLOR=GET_RED()
  OPLOT,[bl0_inx*nSelBeams,(bl1_inx+1)*nSelBeams],nSelGates*[1,1],THICK=blThick,NOCLIP=1,COLOR=GET_RED()
ENDIF

;Y Ticks
maxYTicks       = 10
modY            = CEIL(nSelGates / FLOAT(maxYTicks))

FOR gg=0,nSelGates-1 DO BEGIN
    IF (gg MOD modY) NE 0 THEN CONTINUE
    rg$ = NUMSTR(selGateVec[gg])
    XYOUTS,-0.035*nXBins,gg+0.5,rg$,/NOCLIP,CHARSIZE=0.85
ENDFOR
    rg$ = 'Norm!CAvg!CPSD'
    XYOUTS,-0.030*nXBins,gg+0.6,rg$,/NOCLIP,CHARSIZE=0.60,ALIGN=0.5

PLOT,xvals,yvals,/NODATA                                $
    ,CHARSIZE           = 0.85                          $
    ,XRANGE             = [0,nXBins]                    $
    ,YRANGE             = [0,nSelGates+1]               $
    ,YTITLE             = 'Range Gate'                  $
    ,XTICKS             = 1                             $
    ,YTICKS             = 1                             $
    ,XTICKNAME          = REPLICATE(' ',10)             $
    ,YTICKNAME          = REPLICATE(' ',10)             $
    ,/XSTYLE                                            $
    ,/YSTYLE                                            $
    ,POSITION           = posit

IF scMax LT 0.1 THEN BEGIN
    level_format = '(E12.1)'
ENDIF ELSE IF scMax LT 8 THEN BEGIN
    level_format = '(F12.2)'
ENDIF ELSE IF N_ELEMENTS(level_format) NE 0 THEN s = TEMPORARY(level_format)

DAVIT_LOADCT,ct
PLOT_COLORBAR,1,1,0,0                                   $
    ,SCALE              = specScale                     $
    ,LEGEND             = 'ABS(Spectral Density)'       $
    ,PARAM              = 'power'                       $
    ,LEVEL_FORMAT       = level_format                  $
    ,CHARSIZE           = 0.75                          $
    ,/CONTINUOUS                                        $
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

IF N_ELEMENTS(posPlotFreqVec) EQ 1 THEN BEGIN
  PRINFO,'WARNING!!!!'
  PRINT,'There is only 1 FFT bin.  Did you choose a time period with enough samples in it???'
  PRINT,"I don't think you did.  You had better re-evaluate things."
  PRINT,"I'm just going to stop right here until you work out your issues."
  PRINT,''
  STOP
ENDIF
df      = NUMSTR((posPlotFreqVec[1] - posPlotFreqVec[0])*1000.,2)
txt$    = 'df = ' + df + ' mHz'
XYOUTS,0.1,0.01,txt$,CHARSIZE=0.75,/NORMAL

;ENDFOR ;Loop through color tables.
PS_CLOSE,/NO_FILENAME,NOTE='Run ID: ' + run_id
PS2PNG,file,ROTATE=270
RAD_LOAD_COLORTABLE
END
