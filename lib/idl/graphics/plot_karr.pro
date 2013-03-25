;K-Spectrum!!!!
PRO PLOT_KARR,PNG=png
RESTORE,FILENAME='karr.sav'
file        = DIR('output/kmaps/kspect/karr.ps',/PS)

CLEAR_PAGE,/NEXT

data    = ABS(karr) - MIN(ABS(karr))
sd      = STDDEV(data)
mean    = MEAN(data)

sdMult  = 6.5
scMax   = mean + sdMult*sd
kArrScale = scMax*[0,1.]

image       = GET_COLOR_INDEX(data,PARAM='power',SCALE=kArrScale,/NAN,/CONTINUOUS)
image       = REFORM(image,[nkx,nky])

kArrCharSize     = 0.60
posit   = DEFINE_PANEL(1,1,0,0,/BAR,/SQUARE)
IF ~KEYWORD_SET(bandLim) THEN bandLim = [0,0]
tsJul = julVec[0]
tfJul = julVec[nSteps-1]
IF bandLim[0] NE bandLim[1] THEN BEGIN
  bl$ = 'Band: ' + NUMSTR(bandLim[0]*1000.,2) + ' - ' + NUMSTR(bandLim[1]*1000.,2) + ' mHz'
  IF KEYWORD_SET(fir_filter) THEN BEGIN
    bl$ = 'Digital_filter '+bl$
    tsJul = vsJul
    tfJul = vfJul
  ENDIF
ENDIF ELSE bl$ = 'Band: Entire FFT Spectrum'
    time$       = '('+JUL2STRING(tsJul,/SHORT)+' - '+JUL2STRING(tfJul,/SHORT)+')'
    subtitle= STRUPCASE(radar) + ' ' + CAPITAL(param) + '!C' + time$ + '!C' + bl$ 
PLOT_TITLE,TEXTOIDL('Horizontal Wave Number'),subTitle,SUB_SIZE_FAC=0.70

kxRangeMax      = kx_max+dkx/2.
kyRangeMax      = ky_max+dky/2.
IF kxRangeMax GE kyRangeMax THEN rngMax = kxRangeMax ELSE rngMax = kyRangeMax
range           = rngMax * [-1,1]
;range   = [-0.05,0.05]

PLOT,[0,0],/NODATA                                                      $
    ,XTITLE     = 'kx'                                                  $
    ,YTITLE     = 'ky'                                                  $
    ,XRANGE     = range                                                 $
    ,YRANGE     = range                                                 $
    ,XSTYLE     = 1                                                     $   
    ,YSTYLE     = 1                                                     $   
    ,CHARSIZE   = kArrCharSize                                          $   
    ,POSITION   = posit

xx      = [!X.CRANGE[0], !X.CRANGE[0], !X.CRANGE[1], !X.CRANGE[1]]
yy      = [!Y.CRANGE[0], !Y.CRANGE[1], !Y.CRANGE[1], !Y.CRANGE[0]]

POLYFILL,xx,yy,COLOR=GET_GRAY()

FOR kk=0,N_ELEMENTS(image)-1 DO BEGIN
    ai  = ARRAY_INDICES(image,kk)
    xx  = ai[0]
    yy  = ai[1]

    x0  = kx_vec[xx] - dkx/2.
    x1  = kx_vec[xx] + dkx/2.

    y0  = ky_vec[yy] - dky/2.
    y1  = ky_vec[yy] + dky/2.

    POLYFILL,[x0,x0,x1,x1],[y0,y1,y1,y0],COLOR=image[kk],/DATA,NOCLIP=0
ENDFOR

PLOT,[0,0],/NODATA                                                      $
    ,XTITLE     = 'kx'                                                  $
    ,YTITLE     = 'ky'                                                  $
    ,XRANGE     = range                                                 $
    ,YRANGE     = range                                                 $
    ,XSTYLE     = 1                                                     $   
    ,YSTYLE     = 1                                                     $   
    ,CHARSIZE   = kArrCharSize                                          $   
    ,/NOERASE                                                           $
    ,POSITION   = posit

;Plot 0 lines.
OPLOT,!X.CRANGE,!Y.CRANGE*0,COLOR=GET_BLACK(),THICK=6
OPLOT,!X.CRANGE*0,!Y.CRANGE,COLOR=GET_BLACK(),THICK=6
OPLOT,!X.CRANGE,!Y.CRANGE*0,COLOR=GET_WHITE(),THICK=3
OPLOT,!X.CRANGE*0,!Y.CRANGE,COLOR=GET_WHITE(),THICK=3


;Find local maxima.
IF N_ELEMENTS(nMax) EQ 0 THEN nMax    = 5
locMax  = LOCMAX(data,/SORT)
locMax  = locMax[0:nMax-1]
ai      = ARRAY_INDICES(data,locMax)

kxMaxes = kx_vec[ai[0,*]]
kyMaxes = ky_vec[ai[1,*]]

kMags   = SQRT(kxMaxes^2 + kyMaxes^2)
azms    = ATAN(kxMaxes,kyMaxes) * !RADEG

;Set up frequency for phase velocity/period calculations.
fVec    = FLTARR(nMax)
nFoi    = N_ELEMENTS(foi)
IF nFoi EQ 0 THEN foi = 0
IF ~KEYWORD_SET(foi[0]) THEN BEGIN
    fVec[*]     = fMax
ENDIF ELSE IF N_ELEMENTS(foi) GE nMax THEN BEGIN
    fVec[*]     = foi[0:nMax-1]
ENDIF ELSE BEGIN
    fVec[0:nFoi-1] = foi
    fVec[nFoi:nMax-1] = foi[nFoi-1]
ENDELSE

gLats           = REPLICATE(ctrLat,nMax)
gLons           = REPLICATE(ctrLon,nMax)
mLats           = REPLICATE(ctrMLat,nMax)
mLons           = REPLICATE(ctrMLon,nMax)
mlts            = REPLICATE(FLOOR(ctrMLT)*100 + ROUND((ctrMLT MOD 1)*60.),nMax)
mazms           = GEO_TO_AACGM_AZM(glats,glons,azms)
IF KEYWORD_SET(fir_filter) THEN BEGIN
  durs            = REPLICATE((vfJul - vsJul) * 24.,nMax)
ENDIF ELSE BEGIN
  durs            = REPLICATE((fjul - sjul) * 24.,nMax)
ENDELSE


;Format parameters.
;nr$             = TRANSPOSE(NUMSTR(INDGEN(nMax)+1))
;kxMaxes$        = TRANSPOSE(STRTRIM(STRING(kxMaxes,FORMAT='(F+6.3)')))
;lambda_x$       = TRANSPOSE(STRTRIM(STRING(2*!PI/kxMaxes,FORMAT='(I4)')))
;vel_x$          = TRANSPOSE(STRTRIM(STRING((2*!PI/kxMaxes)*fVec*1000.,FORMAT='(I4)')))
;kyMaxes$        = TRANSPOSE(STRTRIM(STRING(kyMaxes,FORMAT='(F+6.3)')))
;lambda_y$       = TRANSPOSE(STRTRIM(STRING(2*!PI/kyMaxes,FORMAT='(I4)')))
;vel_y$          = TRANSPOSE(STRTRIM(STRING((2*!PI/kyMaxes)*fVec*1000.,FORMAT='(I4)')))
;kMags$          = TRANSPOSE(STRTRIM(STRING(kMags,FORMAT='(F6.3)')))
;lambda$         = TRANSPOSE(STRTRIM(STRING(2*!PI/kMags,FORMAT='(I4)')))
;gLats$          = TRANSPOSE(STRTRIM(STRING(gLats,FORMAT='(F6.1)')))
;gLons$          = TRANSPOSE(STRTRIM(STRING(gLons,FORMAT='(F6.1)')))
;azm$            = TRANSPOSE(STRTRIM(STRING(azms,FORMAT='(I+4)')))
;mLats$          = TRANSPOSE(STRTRIM(STRING(mLats,FORMAT='(F6.1)')))
;mLons$          = TRANSPOSE(STRTRIM(STRING(mLons,FORMAT='(F6.1)')))
;mlts$           = TRANSPOSE(STRTRIM(STRING(mlts,FORMAT='(I4)')))
;mAzm$           = TRANSPOSE(STRTRIM(STRING(mAzms,FORMAT='(I+4)')))
;f$              = TRANSPOSE(STRTRIM(STRING(fVec*1000,FORMAT='(F6.2)')))
;T$              = TRANSPOSE(STRTRIM(STRING(1./(60.*fVec),FORMAT='(I4)')))
;vel$            = TRANSPOSE(STRTRIM(STRING((2*!PI/kMags)*fVec*1000.,FORMAT='(I4)')))
;ctrTimes$       = TRANSPOSE(REPLICATE(JUL2STRING(ctrJul,/SHORT),nMax))
;durs$           = TRANSPOSE(STRTRIM(STRING(durs,FORMAT='(F6.1)'),2))
;radars$         = TRANSPOSE(REPLICATE(radar,nMax))
;runIDs$         = TRANSPOSE(REPLICATE(run_Id,nMax))

nr$             = (NUMSTR(INDGEN(nMax)+1))
kxMaxes$        = (STRTRIM(STRING(kxMaxes,FORMAT='(F+6.3)')))
lambda_x$       = (STRTRIM(STRING(2*!PI/kxMaxes,FORMAT='(I4)')))
vel_x$          = (STRTRIM(STRING((2*!PI/kxMaxes)*fVec*1000.,FORMAT='(I4)')))
kyMaxes$        = (STRTRIM(STRING(kyMaxes,FORMAT='(F+6.3)')))
lambda_y$       = (STRTRIM(STRING(2*!PI/kyMaxes,FORMAT='(I4)')))
vel_y$          = (STRTRIM(STRING((2*!PI/kyMaxes)*fVec*1000.,FORMAT='(I4)')))
kMags$          = (STRTRIM(STRING(kMags,FORMAT='(F6.3)')))
lambda$         = (STRTRIM(STRING(2*!PI/kMags,FORMAT='(I4)')))
gLats$          = (STRTRIM(STRING(gLats,FORMAT='(F6.1)')))
gLons$          = (STRTRIM(STRING(gLons,FORMAT='(F6.1)')))
azm$            = (STRTRIM(STRING(azms,FORMAT='(I+4)')))
mLats$          = (STRTRIM(STRING(mLats,FORMAT='(F6.1)')))
mLons$          = (STRTRIM(STRING(mLons,FORMAT='(F6.1)')))
mlts$           = (STRTRIM(STRING(mlts,FORMAT='(I4)')))
mAzm$           = (STRTRIM(STRING(mAzms,FORMAT='(I+4)')))
f$              = (STRTRIM(STRING(fVec*1000,FORMAT='(F6.2)')))
T$              = (STRTRIM(STRING(1./(60.*fVec),FORMAT='(I4)')))
vel$            = (STRTRIM(STRING((2*!PI/kMags)*fVec*1000.,FORMAT='(I4)')))
ctrTimes$       = (REPLICATE(JUL2STRING(ctrJul,/SHORT),nMax))
durs$           = (STRTRIM(STRING(durs,FORMAT='(F6.1)'),2))
radars$         = (REPLICATE(radar,nMax))
runIDs$         = (REPLICATE(run_Id,nMax))

IF nMax GT 1 THEN BEGIN
    nr$      	= TRANSPOSE(nr$)
    kxMaxes$ 	= TRANSPOSE(kxMaxes$)
    lambda_x$	= TRANSPOSE(lambda_x$)
    vel_x$   	= TRANSPOSE(vel_x$)
    kyMaxes$ 	= TRANSPOSE(kyMaxes$)
    lambda_y$	= TRANSPOSE(lambda_y$)
    vel_y$   	= TRANSPOSE(vel_y$)
    kMags$   	= TRANSPOSE(kMags$)
    lambda$  	= TRANSPOSE(lambda$)
    gLats$   	= TRANSPOSE(gLats$)
    gLons$   	= TRANSPOSE(gLons$)
    azm$     	= TRANSPOSE(azm$)
    mLats$   	= TRANSPOSE(mLats$)
    mLons$   	= TRANSPOSE(mLons$)
    mlts$    	= TRANSPOSE(mlts$)
    mAzm$    	= TRANSPOSE(mAzm$)
    f$       	= TRANSPOSE(f$)
    T$       	= TRANSPOSE(T$)
    vel$     	= TRANSPOSE(vel$)
    ctrTimes$	= TRANSPOSE(ctrTimes$)
    durs$    	= TRANSPOSE(durs$)
    radars$  	= TRANSPOSE(radars$)
    runIDs$  	= TRANSPOSE(runIDs$)
ENDIF

;Make and print a table of their locations
maxTab          = STRARR(9,nMax+1)
maxTab[1,0]     = 'Kx'
maxTab[2,0]     = 'Ky'
maxTab[3,0]     = '|K|'
maxTab[4,0]     = TEXTOIDL('\lambda [km]')
maxTab[5,0]     = 'Azm'
maxTab[6,0]     = 'f [mHz]'
maxTab[7,0]     = 'T [min]'
maxTab[8,0]     = 'v [m/s]'
maxTab[0,1:nMax]= nr$
maxTab[1,1:nMax]= kxMaxes$
maxTab[2,1:nMax]= kyMaxes$
maxTab[3,1:nMax]= kMags$
maxTab[4,1:nMax]= lambda$
maxTab[5,1:nMax]= azm$ + TEXTOIDL('^{\circ}')
maxTab[6,1:nMax]= f$
maxTab[7,1:nMax]= T$
maxTab[8,1:nMax]= vel$


xp      = 0.55
yp      = 0.91
cSize   = 0.40
dx      = 0.045

txt$    = STRJOIN(maxTab[0,*],'!C',/SINGLE)
XYOUTS,xp,yp,txt$,/NORMAL,CHARSIZE=cSize

txt$    = STRJOIN(maxTab[1,*],'!C',/SINGLE)
xp      += 0.02
XYOUTS,xp,yp,txt$,/NORMAL,CHARSIZE=cSize

txt$    = STRJOIN(maxTab[2,*],'!C',/SINGLE)
xp      += dx
XYOUTS,xp,yp,txt$,/NORMAL,CHARSIZE=cSize

txt$    = STRJOIN(maxTab[3,*],'!C',/SINGLE)
xp      += dx
XYOUTS,xp,yp,txt$,/NORMAL,CHARSIZE=cSize

txt$    = STRJOIN(maxTab[4,*],'!C',/SINGLE)
xp      += dx
XYOUTS,xp,yp,txt$,/NORMAL,CHARSIZE=cSize

txt$    = STRJOIN(maxTab[5,*],'!C',/SINGLE)
xp      += dx
XYOUTS,xp,yp,txt$,/NORMAL,CHARSIZE=cSize

txt$    = STRJOIN(maxTab[6,*],'!C',/SINGLE)
xp      += dx
XYOUTS,xp,yp,txt$,/NORMAL,CHARSIZE=cSize

txt$    = STRJOIN(maxTab[7,*],'!C',/SINGLE)
xp      += dx
XYOUTS,xp,yp,txt$,/NORMAL,CHARSIZE=cSize

txt$    = STRJOIN(maxTab[8,*],'!C',/SINGLE)
xp      += dx
XYOUTS,xp,yp,txt$,/NORMAL,CHARSIZE=cSize

;Plot their locations.
FOR mm=0,nMax-1 DO BEGIN
    kx  = kxMaxes[mm]
    ky  = kyMaxes[mm]
    txt$        = maxTab[0,mm+1]
    XYOUTS,kx,ky,txt$,/DATA,COLOR=GET_BLACK(),CHARSIZE=1,CHARTHICK=10
    XYOUTS,kx,ky,txt$,/DATA,COLOR=GET_WHITE(),CHARSIZE=1,CHARTHICK=5
ENDFOR

;Do fun stuff with colorbars.
IF scMax LT 0.1 THEN BEGIN
    level_format = '(E12.1)'
ENDIF ELSE IF scMax LT 8 THEN BEGIN
    level_format = '(F12.2)'
ENDIF ELSE s = TEMPORARY(level_format)

txt$    = TEXTOIDL('[CB Max: \mu + ' + NUMSTR(sdMult,1) + '\sigma]')
PLOT_COLORBAR                                                           $
    ,PANEL_POSITION     = posit                                         $
    ,SCALE              = kArrScale                                     $
    ,/KEEP_FIRST_LAST_LABEL                                             $
    ,LEGEND             = 'ABS(P(u)) ' + txt$                           $
    ,PARAM              = 'power'                                       $
    ,LEVEL_FORMAT       = level_format                                  $
    ,CHARSIZE           = 0.60                                          $
    ,/CONTINUOUS

max$ = NUMSTR(MAX(data,/NAN),5)
min$ = NUMSTR(MIN(data,/NAN),5)
mean$ =NUMSTR(MEAN(data),5)
sd$  = NUMSTR(sd,5)
var$ = NUMSTR(sd^2,5)
txt$ = 'Max: ' + max$ + ' Min: ' + min$ + ' Mean: ' + mean$ + TEXTOIDL(' \sigma: ') + sd$ $
     + TEXTOIDL(' \sigma^2: ') + var$
XYOUTS,0.1,0.03,txt$,CHARSIZE=0.75,/NORMAL


PS_CLOSE,/NO_FILENAME,NOTE='Run ID: ' + run_id
IF KEYWORD_SET(png) THEN PS2PNG,file,ROTATE=270

output_file     = 'output/kmaps/kspect/karr.txt'
; Output to text file. ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OPENW,1,output_file,WIDTH=500;,/APPEND
PRINTF,1,'$ ' + varNames$
PRINTF,1,'  ' + event$
PRINTF,1,''


;str$    = '# Location and time information for center of field of view.'
;PRINTF,1,str$
;str$ = '> ctrLat  = ' + NUMSTR(ctrLat,2)
;PRINTF,1,str$
;str$ = '> ctrLon  = ' + NUMSTR(ctrLon,2)
;PRINTF,1,str$
;str$ = '> ctrMLat = ' + NUMSTR(ctrMLat,2)
;PRINTF,1,str$
;str$ = '> ctrMLon = ' + NUMSTR(ctrMLon,2)
;PRINTF,1,str$
;
;ctrMLT$ = STRING(FLOOR(ctrMLT)*100 + ROUND((ctrMLT MOD 1)*60.),FORMAT='(I04)')
;str$ = '> ctrMLT  = ' + NUMSTR(ctrMLT,2) + '  ; (' + ctrMLT$ + ' MLT)'
;PRINTF,1,str$
;str$ = "> ctrJul  = '" + JUL2STRING(ctrJul) + "'"
;PRINTF,1,str$
;PRINTF,1,''

format  = '(1A-1,1A-3, 18A-9, 1A-18, 1A-7, 1A-7, 1A-15)'
str$    = ['#', 'Nr', 'Kx', 'lam_x',   'v_x', 'Ky', 'lam_y',   'v_y', '|K|', 'lambda',     'v',     'f',     'T',  'gLat', 'gLon',  'gAzm',   'mLat',  'mLon', 'MLT', 'mAzm', 'ctrTime',  'dur', 'radar', 'runID']
PRINTF,1,str$,FORMAT=format
str$    = ['#,',  '',   '',  '[km]', '[m/s]',   '',  '[km]', '[m/s]',    '',   '[km]', '[m/s]', '[mHz]', '[min]', '[deg]', '[deg]', '[deg]', '[deg]', '[deg]',    '', '[deg]',       '', '[hr]',      '',      '']
PRINTF,1,str$,FORMAT=format

spc     = nr$
spc[*]  = ' '
str$    = [spc,nr$, kxMaxes$, lambda_x$, vel_x$, kyMaxes$, lambda_y$, vel_y$, kMags$, lambda$, vel$, f$, T$, gLats$, gLons$, azm$, mLats$, mLons$, mlts$, mAzm$, ctrTimes$, durs$, radars$, runIds$]
PRINTF,1,str$,FORMAT=format

PRINTF,1,''
PRINTF,1,'# Run ID: ' + run_id
CLOSE,1

END
