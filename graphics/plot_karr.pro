;K-Spectrum!!!!
PRO PLOT_KARR
RESTORE,FILENAME='karr.sav'
file        = DIR('output/kmaps/kspect/karr.ps',/PS)

CLEAR_PAGE,/NEXT

data    = ABS(karr) - MIN(ABS(karr))
sd      = STDDEV(data)
mean    = MEAN(data)
scMax   = mean + 2.*sd
kArrScale = scMax*[0,1.]

image       = GET_COLOR_INDEX(data,PARAM='power',SCALE=kArrScale,/NAN,/CONTINUOUS)
image       = REFORM(image,[nkx,nky])

kArrCharSize     = 0.60
posit   = DEFINE_PANEL(1,1,0,0,/BAR)
    IF KEYWORD_SET(bandLim) THEN bl$ = 'Band: ' + NUMSTR(bandLim[0]*1000.,2) + ' - ' + NUMSTR(bandLim[1]*1000.,2) + ' mHz' ELSE bl$ = 'Band: Entire FFT Spectrum'
    time$       = '('+JUL2STRING(julVec[0])+' - '+JUL2STRING(julVec[nSteps-1])+')'
    subtitle= STRUPCASE(radar) + ' ' + time$ + '!C' + bl$ 
PLOT_TITLE,TEXTOIDL('Horizontal Wave Number'),subTitle

PLOT,[0,0],/NODATA                                                      $
    ,XTITLE     = TEXTOIDL('kx [km^{-1}]')                              $   
    ,YTITLE     = TEXTOIDL('ky [km^{-1}]')                              $   
    ,XRANGE     = (kx_max+dkx/2.) * [-1.,1.]                            $
    ,YRANGE     = (ky_max+dky/2.) * [-1.,1.]                            $
    ,XSTYLE     = 1                                                     $   
    ,YSTYLE     = 1                                                     $   
    ,CHARSIZE   = kArrCharSize                                          $   
    ,POSITION   = posit

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

IF scMax LT 0.1 THEN BEGIN
    level_format = '(E12.1)'
ENDIF ELSE IF scMax LT 8 THEN BEGIN
    level_format = '(F12.2)'
ENDIF ELSE s = TEMPORARY(level_format)

PLOT_COLORBAR,1,1,0,0                                                   $
    ,SCALE              = kArrScale                                     $
    ,/KEEP_FIRST_LAST_LABEL                                             $
    ,LEGEND             = 'ABS(P(u))'                                   $
    ,PARAM              = 'power'                                       $
    ,LEVEL_FORMAT       = level_format                                       $
    ,CHARSIZE           = 0.75                                          $
    ,/CONTINUOUS

max$ = NUMSTR(MAX(data,/NAN),5)
min$ = NUMSTR(MIN(data,/NAN),5)
mean$ =NUMSTR(MEAN(data),5)
sd$  = NUMSTR(sd,5)
var$ = NUMSTR(sd^2,5)
txt$ = 'Max: ' + max$ + ' Min: ' + min$ + ' Mean: ' + mean$ + TEXTOIDL(' \sigma: ') + sd$ $
     + TEXTOIDL(' \sigma^2: ') + var$
XYOUTS,0.1,0.03,txt$,CHARSIZE=0.75,/NORMAL

PS_CLOSE
PS2PNG,file,ROTATE=270
STOP
END
