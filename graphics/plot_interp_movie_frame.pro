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
movieXrange     = [-2, 7]
movieYrange     = [-35,-27]
MAP_PLOT_PANEL                                          $
    ,DATE               = scanDate                      $
    ,TIME               = scanTime                    $
    ,XRANGE             = movieXRange                     $
    ,YRANGE             = movieYRange                     $
    ,/NO_FILL                                           $
    ,ROTATE             = rotate                        $
    ,POSITION           = posit

clrArr          = REFORM(GET_COLOR_INDEX(interpArr,/NAN),[nBeams,nGates])
FOR dd=0,N_ELEMENTS(clrArr)-1 DO BEGIN
    IF clrArr[dd] EQ GET_BACKGROUND() THEN CONTINUE
    bmGate      = ARRAY_INDICES(clrArr,dd)
    bm          = bmGate[0]
    rg          = bmGate[1]

    lat     = REFORM(bndArr_grid[0,*,*,bm,rg])
    lon     = REFORM(bndArr_grid[1,*,*,bm,rg])

    p0      = CALC_STEREO_COORDS(lat[0,0],lon[0,0],ROTATE=rotate)
    p1      = CALC_STEREO_COORDS(lat[0,1],lon[0,1],ROTATE=rotate)
    p2      = CALC_STEREO_COORDS(lat[1,1],lon[1,1],ROTATE=rotate)
    p3      = CALC_STEREO_COORDS(lat[1,0],lon[1,0],ROTATE=rotate)

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
    ,ROTATE             = rotate                        $
    ,POSITION           = posit

OVERLAY_FOV_NAME                                    $
    ,JUL            = scan_startJul                 $
    ,IDS            = stid                          $
    ,CHARSIZE       = 0.60                          $
    ,CHARTHICK      = 2.00                          $
    ,ROTATE             = rotate                        $
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

