; Plot stuff! ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SET_FORMAT,/LANDSCAPE,/SARDINES
CLEAR_PAGE,/NEXT
title           = 'Ground Scatter Range Comparison'
subtitle        = STRUPCASE(radar) + ' ' + FORMAT_DATE(scanDate,/HUMAN)
PLOT_TITLE,title,subTitle

;Plot original FOV.
;Make position span 2 rows.
posit           =  DEFINE_PANEL(2,3,0,1,/BAR)
posit[3]        = (DEFINE_PANEL(2,3,0,0,/BAR))[3]

XYOUTS,posit[0],1.01*posit[3],'No GS Range Adjustment',CHARSIZE=0.75,/NORMAL

RAD_FIT_PLOT_SCAN_PANEL                             $
    ,XRANGE             = mapXRange                 $
    ,YRANGE             = mapYRange                 $
    ,SCAN_NUMBER        = scan_number               $
    ,ROTATE             = rotate                        $
    ,/NO_FILL                                       $
    ,POSITION           = posit
    
OVERLAY_FOV_NAME                                    $
    ,JUL            = scan_startJul                 $
    ,IDS            = stid                          $
    ,CHARSIZE       = 0.60                          $
    ,ROTATE             = rotate                        $
    ,CHARTHICK      = 2.00                          $
    ,/ANNOTATE

RAD_FIT_PLOT_SCAN_TITLE,2,3,0,0                         $
    ,SCAN_ID            = scan_id                       $
    ,SCAN_STARTJUL      = scan_startJul                 $
    ,/BAR

;Plot ground scatter mapped FOV.
;Make position span 2 rows.
posit           =  DEFINE_PANEL(2,3,1,1,/BAR)
posit[3]        = (DEFINE_PANEL(2,3,1,0,/BAR))[3]

XYOUTS,posit[0],1.01*posit[3],'With GS Range Adjustment',CHARSIZE=0.75,ALIGN=0,/NORMAL

MAP_PLOT_PANEL                                          $
    ,DATE               = scanDate                      $
    ,TIME               = scanTime                    $
    ,XRANGE             = mapXRange                     $
    ,YRANGE             = mapYRange                     $
    ,ROTATE             = rotate                        $
    ,/NO_FILL                                           $
    ,POSITION           = posit

; clrArr          = REFORM(GET_COLOR_INDEX(interpArr,/NAN),[nBeams,nGates])
clrArr          = REFORM(GET_COLOR_INDEX(dataArr,/NAN),[nBeams,nGates])
FOR dd=0,N_ELEMENTS(clrArr)-1 DO BEGIN
    IF clrArr[dd] EQ GET_BACKGROUND() THEN CONTINUE
    bmGate      = ARRAY_INDICES(clrArr,dd)
    bm          = bmGate[0]
    rg          = bmGate[1]

    lat     = REFORM(bndArr[0,*,*,bm,rg])
    lon     = REFORM(bndArr[1,*,*,bm,rg])

    p0      = CALC_STEREO_COORDS(lat[0,0],lon[0,0],ROTATE=rotate)
    p1      = CALC_STEREO_COORDS(lat[0,1],lon[0,1],ROTATE=rotate)
    p2      = CALC_STEREO_COORDS(lat[1,1],lon[1,1],ROTATE=rotate)
    p3      = CALC_STEREO_COORDS(lat[1,0],lon[1,0],ROTATE=rotate)

    xx          = [p0[0], p1[0], p2[0], p3[0]]
    yy          = [p0[1], p1[1], p2[1], p3[1]]
    POLYFILL,xx,yy,COLOR=clrArr[dd],NOCLIP=0
ENDFOR

OVERLAY_FOV_NAME                                    $
    ,JUL            = scan_startJul                 $
    ,IDS            = stid                          $
    ,CHARSIZE       = 0.60                          $
    ,CHARTHICK      = 2.00                          $
    ,ROTATE             = rotate                        $
    ,/ANNOTATE

RAD_FIT_PLOT_SCAN_TITLE,2,3,1,0                         $
    ,SCAN_ID            = scan_id                       $
    ,SCAN_STARTJUL      = scan_startJul                 $
    ,/BAR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
posit           = DEFINE_PANEL(2,3,0,2,/BAR,/WITH_INFO)
clrArr          = REFORM(GET_COLOR_INDEX(dataArr,/NAN),[nBeams,nGates])
PLOT_GATE_BEAM,bndArr_no_gs,clrArr                                          $
    ,YVALS          = beamVec                                               $
    ,YCOORDS        = 'rang'                                                $
    ,XCHARSIZE      = 0.6                                                   $
    ,YCHARSIZE      = 0.6                                                   $
    ,POSITION       = posit

posit           = DEFINE_PANEL(2,3,1,2,/BAR,/WITH_INFO)
clrArr          = REFORM(GET_COLOR_INDEX(dataArr,/NAN),[nBeams,nGates])
PLOT_GATE_BEAM,bndArr,clrArr                                                $
    ,YVALS          = beamVec                                               $
    ,YCOORDS        = 'rang'                                                $
    ,XCHARSIZE      = 0.6                                                   $
    ,YCHARSIZE      = 0.6                                                   $
    ,POSITION       = posit

PLOT_COLORBAR,2,1,1,0,CHARSIZE=0.75
