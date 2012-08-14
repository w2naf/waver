; Plot stuff! ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SET_FORMAT,/PORTRAIT,/SARDINES

CLEAR_PAGE,/NEXT
subtitle        = STRUPCASE(radar) + ' ' + FORMAT_DATE(scanDate,/HUMAN)
PLOT_TITLE,subTitle

ymaps = 2

;Plot original FOV.
;Make position span 2 rows.
posit           =  DEFINE_PANEL(1,ymaps,0,0,/BAR)

XYOUTS,posit[0],1.01*posit[3],'Slant-Range Interpolated Data',CHARSIZE=0.75,ALIGN=0,/NORMAL
MAP_PLOT_PANEL                                          $
    ,DATE               = scanDate                      $
    ,TIME               = scanTime                    $
    ,XRANGE             = movieXRange                     $
    ,YRANGE             = movieYRange                     $
    ,/NO_FILL                                           $
    ,ROTATE             = movieRotate                        $
    ,POSITION           = posit

data    = interpArr[beamRange[0]:beamRange[1],gateRange[0]:gateRange[1]]
dims    = SIZE(data,/DIM)

dataBeamArr     = INTARR(dims)
dataGateArr     = INTARR(dims)
dataBeamVec     = INDGEN(dims[0]) + beamRange[0]
dataGateVec     = INDGEN(dims[1]) + gateRange[0]

FOR ll=0,dims[1]-1 DO dataBeamArr[*,ll] = dataBeamVec
FOR ll=0,dims[0]-1 DO dataGateArr[ll,*] = dataGateVec

clrArr          = REFORM(GET_COLOR_INDEX(data,/NAN),dims)

FOR dd=0,N_ELEMENTS(clrArr)-1 DO BEGIN
    IF clrArr[dd] EQ GET_BACKGROUND() THEN CONTINUE
;    bmGate      = ARRAY_INDICES(clrArr,dd)
;    bm          = bmGate[0]
;    rg          = bmGate[1]

    bm  = dataBeamArr[dd]
    rg  = dataGateArr[dd]

    lat     = REFORM(bndArr_grid[0,*,*,bm,rg])
    lon     = REFORM(bndArr_grid[1,*,*,bm,rg])

    p0      = CALC_STEREO_COORDS(lat[0,0],lon[0,0],ROTATE=movieRotate)
    p1      = CALC_STEREO_COORDS(lat[0,1],lon[0,1],ROTATE=movieRotate)
    p2      = CALC_STEREO_COORDS(lat[1,1],lon[1,1],ROTATE=movieRotate)
    p3      = CALC_STEREO_COORDS(lat[1,0],lon[1,0],ROTATE=movieRotate)

    xx          = [p0[0], p1[0], p2[0], p3[0]]
    yy          = [p0[1], p1[1], p2[1], p3[1]]
    POLYFILL,xx,yy,COLOR=clrArr[dd],NOCLIP=0
ENDFOR

MAP_PLOT_PANEL                                          $
    ,DATE               = scanDate                      $
    ,TIME               = scanTime                    $
    ,XRANGE             = movieXRange                     $
    ,YRANGE             = movieYRange                     $
    ,/NO_FILL                                           $
    ,ROTATE             = movieRotate                        $
    ,POSITION           = posit

OVERLAY_FOV_NAME                                    $
    ,JUL            = scan_startJul                 $
    ,IDS            = stid                          $
    ,CHARSIZE       = 0.60                          $
    ,CHARTHICK      = 2.00                          $
    ,ROTATE             = movieRotate                        $
    ,/ANNOTATE

RAD_FIT_PLOT_SCAN_TITLE,1,ymaps,0,0                         $
    ,SCAN_ID            = scan_id                       $
    ,SCAN_STARTJUL      = scan_startJul                 $
    ,/BAR
PLOT_COLORBAR,1,ymaps,0,0,CHARSIZE=0.75
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
posit[1] = 0.440
posit[3] = 0.460
xrange  = [MIN(julVec),MAX(julVec)]
xticks  = GET_XTICKS(xrange,xminor=xminor)
PLOT,[0,0]                                                              $
    ,/NODATA                                                            $   
    ,XTICKFORMAT        = 'LABEL_DATE'                                  $   
    ,CHARSIZE           = 0.75                                          $   
    ,XTITLE             = 'Time [UT]'                                   $   
    ,XRANGE             = xrange                                        $
    ,XTICKS             = xTicks                                        $   
    ,XMINOR             = xMinor                                        $   
    ,YRANGE             = [0,1]                                         $   
    ,YTICKS             = 1                                             $   
    ,YTICKNAME          = REPLICATE(' ',2)                              $   
    ,POSITION           = posit                                         $   
    ,/XSTYLE                                                            $   
    ,/YSTYLE
polyX   = [julVec[0],julVec[0],scan_startJul,scan_startJul]
polyY   = [0,1,1,0]
POLYFILL,polyX,polyY

beam    = RAD_GET_BEAM()
BEAM_AZM,beam,MAGNAZM=magnAzm,GEOGAZM=geogAzm
gAzm$   = NUMSTR(geogAzm) + TEXTOIDL('^{\circ}')
mAzm$   = NUMSTR(magnAzm) + TEXTOIDL('^{\circ}')

xtitle  = 'Time [UT] - Beam '+ NUMSTR(beam)                             $
        + ' (Geog. Azm: ' + gAzm$ + ', Magn. Azm: ' + mAzm$ + ')'

posit   = DEFINE_PANEL(1,2,0,1,/BAR,/WITH_INFO)
posit[3] = 0.380
RAD_FIT_PLOT_RTI_PANEL                                                  $
    ,COORDS             = 'mix_rang'                                    $
    ,yrange             = drange                                        $
    ,DATE               = date                                          $
    ,TIME               = time                                          $
    ,PARAM              = param                                         $
    ,XTITLE             = xtitle                                        $
    ,CHARSIZE           = 0.75                                          $
    ,/LAST                                                              $
    ,POSITION           = posit

PLOT_COLORBAR,CHARSIZE=0.75,PANEL_POSITION=posit
