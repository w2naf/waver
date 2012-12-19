; Plot stuff! ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SET_FORMAT,/LANDSCAPE,/SARDINES

CLEAR_PAGE,/NEXT
title           = 'Local Range Determination'
subtitle        = STRUPCASE(radar) + ' (' + JUL2STRING(scan_startJul) + ')'
PLOT_TITLE,title,subTitle

;Plot original FOV.
;Make position span 2 rows.
posit           =  DEFINE_PANEL(2,3,0,1,/BAR)
posit[3]        = (DEFINE_PANEL(2,3,0,0,/BAR))[3]

XYOUTS,posit[0],1.01*posit[3],'Raw Data',CHARSIZE=0.75,/NORMAL

MAP_PLOT_PANEL                                          $
    ,DATE               = scanDate                      $
    ,TIME               = scanTime                    $
    ,XRANGE             = lrdmapXRange                     $
    ,YRANGE             = lrdmapYRange                     $
    ,ROTATE             = lrdRotate                        $
    ,/NO_FILL                                           $
    ,POSITION           = posit

clrArr          = REFORM(GET_COLOR_INDEX(dataArr,/NAN),[nBeams,nGates])
FOR dd=0,N_ELEMENTS(clrArr)-1 DO BEGIN
    IF clrArr[dd] EQ GET_BACKGROUND() THEN CONTINUE
    bmGate      = ARRAY_INDICES(clrArr,dd)
    bm          = bmGate[0]
    rg          = bmGate[1]

    lat     = REFORM(bndArr[0,*,*,bm,rg])
    lon     = REFORM(bndArr[1,*,*,bm,rg])

    p0      = CALC_STEREO_COORDS(lat[0,0],lon[0,0],ROTATE=lrdRotate)
    p1      = CALC_STEREO_COORDS(lat[0,1],lon[0,1],ROTATE=lrdRotate)
    p2      = CALC_STEREO_COORDS(lat[1,1],lon[1,1],ROTATE=lrdRotate)
    p3      = CALC_STEREO_COORDS(lat[1,0],lon[1,0],ROTATE=lrdRotate)

    xx          = [p0[0], p1[0], p2[0], p3[0]]
    yy          = [p0[1], p1[1], p2[1], p3[1]]
    POLYFILL,xx,yy,COLOR=clrArr[dd],NOCLIP=0
ENDFOR

OVERLAY_FOV_NAME                                    $
    ,JUL            = scan_startJul                 $
    ,IDS            = stid                          $
    ,CHARSIZE       = 0.60                          $
    ,CHARTHICK      = 2.00                          $
    ,ROTATE         = lrdRotate                            $
    ,/ANNOTATE

;RAD_FIT_PLOT_SCAN_TITLE,2,3,0,0                         $
;    ,SCAN_ID            = scan_id                       $
;    ,SCAN_STARTJUL      = scan_startJul                 $
;    ,/BAR

;Plot ground scatter mapped FOV.
;Make position span 2 rows.
posit           =  DEFINE_PANEL(2,3,1,1,/BAR)
posit[3]        = (DEFINE_PANEL(2,3,1,0,/BAR))[3]

XYOUTS,posit[0],1.01*posit[3],'Slant-Range Interpolated Data',CHARSIZE=0.75,ALIGN=0,/NORMAL

MAP_PLOT_PANEL                                          $
    ,DATE               = scanDate                      $
    ,TIME               = scanTime                    $
    ,XRANGE             = lrdmapXRange                     $
    ,YRANGE             = lrdmapYRange                     $
    ,ROTATE             = lrdRotate                        $
    ,/NO_FILL                                           $
    ,POSITION           = posit

clrArr          = REFORM(GET_COLOR_INDEX(interpArr,/NAN),[nBeams,nGates])
FOR dd=0,N_ELEMENTS(clrArr)-1 DO BEGIN
    IF clrArr[dd] EQ GET_BACKGROUND() THEN CONTINUE
    bmGate      = ARRAY_INDICES(clrArr,dd)
    bm          = bmGate[0]
    rg          = bmGate[1]

    IF bm LT beamRange[0] OR bm GT beamRange[1] THEN CONTINUE
    IF rg LT gateRange[0] OR rg GT gateRange[1] THEN CONTINUE

    IF bm EQ ctrBm AND rg EQ ctrRg THEN clrArr[dd] = GET_BLACK()

    lat     = REFORM(bndArr_grid[0,*,*,bm,rg])
    lon     = REFORM(bndArr_grid[1,*,*,bm,rg])

    p0      = CALC_STEREO_COORDS(lat[0,0],lon[0,0],ROTATE=lrdRotate)
    p1      = CALC_STEREO_COORDS(lat[0,1],lon[0,1],ROTATE=lrdRotate)
    p2      = CALC_STEREO_COORDS(lat[1,1],lon[1,1],ROTATE=lrdRotate)
    p3      = CALC_STEREO_COORDS(lat[1,0],lon[1,0],ROTATE=lrdRotate)

    xx          = [p0[0], p1[0], p2[0], p3[0]]
    yy          = [p0[1], p1[1], p2[1], p3[1]]
    POLYFILL,xx,yy,COLOR=clrArr[dd],NOCLIP=0
ENDFOR

OVERLAY_FOV_NAME                                    $
    ,JUL            = scan_startJul                 $
    ,IDS            = stid                          $
    ,CHARSIZE       = 0.60                          $
    ,CHARTHICK      = 2.00                          $
    ,ROTATE         = lrdRotate                            $
    ,/ANNOTATE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
yoff            = -0.03
posit           = DEFINE_PANEL(2,3,0,2,/BAR,/WITH_INFO)
posit[1]        += yoff
posit[3]        += yoff

data            = lr[1,*,*]
sd              = STDDEV(data)
mean            = MEAN(data)
scMax           = mean + 2.*sd
scMin           = mean - 2.*sd
IF ABS(scMin) GT ABS(scMax) THEN scMax = ABS(scMin)
colorScale      = scMax*[-1,1.]


clrArr          = REFORM(GET_COLOR_INDEX(data,/NAN,SCALE=colorScale,/SHIFT),[nSelBeams,nSelGates])
title='N-S Distance From Center!C(Beam: '+NUMSTR(ctrBm)+', Gate: '+NUMSTR(ctrRg)+')'
PLOT_GATE_BEAM,sel_bndArr_grd,clrArr                                        $
    ,YVALS          = selGateVec                                            $
    ,XVALS          = selbeamVec                                            $
    ,TITLE          = title                                                     $
    ,CHARSIZE       = 0.5                                                   $
    ,POSITION       = posit

posit           = DEFINE_PANEL(2,3,1,2,/BAR,/WITH_INFO)
posit[1]        += yoff
posit[3]        += yoff

data            = lr[0,*,*]
sd              = STDDEV(data)
mean            = MEAN(data)
scMax           = mean + 2.*sd
scMin           = mean - 2.*sd
IF ABS(scMin) GT ABS(scMax) THEN scMax = ABS(scMin)
colorScale      = scMax*[-1,1.]

clrArr          = REFORM(GET_COLOR_INDEX(data,/NAN,SCALE=colorScale,/SHIFT),[nSelBeams,nSelGates])
title='E-W Distance From Center!C(Beam: '+NUMSTR(ctrBm)+', Gate: '+NUMSTR(ctrRg)+')'
PLOT_GATE_BEAM,sel_bndArr_grd,clrArr                                        $
    ,YVALS          = selGateVec                                            $
    ,XVALS          = selbeamVec                                               $
    ,TITLE          = title                                                     $
    ,CHARSIZE       = 0.5                                                   $
    ,POSITION       = posit

PLOT_COLORBAR,2,1,1,0,CHARSIZE=0.60,/SHIFT,LEGEND='Distance [km]',SCALE=colorscale


legend  = ['X [km]: ' + NUMSTR(xspread,1)       $
          ,'Y [km]: ' + NUMSTR(yspread,1)       $
          ,'Lat [deg]: ' + NUMSTR(latspread,1)       $
          ,'Lon [deg]: ' + NUMSTR(lonspread,1)]


LINE_LEGEND,[0.85,0.85],legend,TITLE='Ranges',CHARSIZE=0.5
