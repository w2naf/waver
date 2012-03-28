; Plot stuff! ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SET_FORMAT,/LANDSCAPE,/SARDINES
file    = DIR('output/kmaps/rgnormal.ps',/PS)

SET_PARAMETER,param
scale1              = GET_DEFAULT_RANGE(param)

;scale2  = scale1

meanVal2        = MEAN(rgNormalArr,/NAN)
stdDevVal2      = STDDEV(rgNormalArr)

maxval2         = meanVal2 + 2*stdDevVal2

IF MIN(rgNormalArr,/NAN) LT 0 THEN BEGIN
    scale2      = maxVal2 * [-1.,1.]
ENDIF ELSE BEGIN
    scale2      = maxVal2 * [  0,1.]
ENDELSE

IF maxVal2 LT 8 THEN format2   = '(F3.1)'

FOR step=0,N_ELEMENTS(rgNormalArr[*,0,0])-1 DO BEGIN
    dataArr1            = REFORM(interpData[step,*,*])
    dataArr2            = REFORM(rgNormalArr[step,*,*])
    scan_startJul       = scan_sJulVec[step]
    SFJUL,scanDate,scanTime,scan_startJul,/JUL_TO_DATE

    CLEAR_PAGE,/NEXT
    title           = 'Normalized Ground Range Comparison'
    subtitle        = STRUPCASE(radar) + ' (' + JUL2STRING(scan_startJul) + ')'
    PLOT_TITLE,title,subTitle

    ;Plot original FOV.
    SET_SCALE,scale1 
    posit           =  DEFINE_PANEL(2,3,0,1,/BAR)
    posit[3]        = (DEFINE_PANEL(2,3,0,0,/BAR))[3]
    
    text$   = 'No RG Normalization'
    XYOUTS,posit[0],1.01*posit[3],text$,CHARSIZE=0.75,/NORMAL
    MAP_PLOT_PANEL                                              $
        ,DATE               = scanDate                          $
        ,TIME               = scanTime                          $
        ,XRANGE             = lrdmapXRange                      $
        ,YRANGE             = lrdmapYRange                      $
        ,ROTATE             = lrdRotate                         $
        ,/NO_FILL                                               $
        ,POSITION           = posit

    clrArr          = REFORM(GET_COLOR_INDEX(dataArr1,/NAN,SCALE=scale1),[nSelBeams,nSelGates])
    FOR dd=0,N_ELEMENTS(clrArr)-1 DO BEGIN
        IF clrArr[dd] EQ GET_BACKGROUND() THEN CONTINUE
        bmGate      = ARRAY_INDICES(clrArr,dd)
        bm          = bmGate[0]
        rg          = bmGate[1]
        
        lat     = REFORM(sel_bndArr_grid[0,*,*,bm,rg])
        lon     = REFORM(sel_bndArr_grid[1,*,*,bm,rg])

        p0      = CALC_STEREO_COORDS(lat[0,0],lon[0,0],ROTATE=lrdRotate)
        p1      = CALC_STEREO_COORDS(lat[0,1],lon[0,1],ROTATE=lrdRotate)
        p2      = CALC_STEREO_COORDS(lat[1,1],lon[1,1],ROTATE=lrdRotate)
        p3      = CALC_STEREO_COORDS(lat[1,0],lon[1,0],ROTATE=lrdRotate)

        xx          = [p0[0], p1[0], p2[0], p3[0]]
        yy          = [p0[1], p1[1], p2[1], p3[1]]
        POLYFILL,xx,yy,COLOR=clrArr[dd],NOCLIP=0
    ENDFOR
        
    OVERLAY_FOV_NAME                                            $
        ,JUL            = scan_startJul                         $
        ,IDS            = stid                                  $
        ,CHARSIZE       = 0.60                                  $
        ,CHARTHICK      = 2.00                                  $
        ,ROTATE         = lrdRotate                             $
        ,/ANNOTATE

    RAD_FIT_PLOT_SCAN_TITLE,2,3,0,0                         $
;        ,SCAN_ID            = scan_id                       $
        ,SCAN_STARTJUL      = scan_startJul                 $
        ,/BAR
    ;PLOT_COLORBAR,2,2,0,0,CHARSIZE=0.75,SCALE=scale1,LEGEND=' '
    PLOT_COLORBAR,CHARSIZE=0.75,SCALE=scale1,PANEL_POSITION=posit

    posit           = DEFINE_PANEL(2,3,0,2,/BAR,/WITH_INFO)
    PLOT_GATE_BEAM,sel_bndArr_grid,clrArr                                       $   
    ;    ,YVALS          = beamVec                                               $
        ,YCOORDS        = 'rang'                                                $   
        ,YRANGE         = dRange                                                $   
        ,XCHARSIZE      = 0.6                                                   $   
        ,YCHARSIZE      = 0.6                                                   $   
        ,POSITION       = posit


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
    ;Plot data without Range Gate Normalization
    SET_SCALE,scale2 
    posit           =  DEFINE_PANEL(2,3,1,1,/BAR)
    posit[3]        = (DEFINE_PANEL(2,3,1,0,/BAR))[3]

    xnudge      = 0.05
    posit[0]    += xnudge
    posit[2]    += xnudge
    text$   = 'With Range Gate Normalization'
    XYOUTS,posit[0],1.01*posit[3],text$,CHARSIZE=0.75,ALIGN=0,/NORMAL
    MAP_PLOT_PANEL                                              $
        ,DATE               = scanDate                          $
        ,TIME               = scanTime                          $
        ,XRANGE             = lrdmapXRange                      $
        ,YRANGE             = lrdmapYRange                      $
        ,ROTATE             = lrdRotate                         $
        ,/NO_FILL                                               $
        ,POSITION           = posit

    clrArr          = REFORM(GET_COLOR_INDEX(dataArr2,/NAN,SCALE=scale2),[nSelBeams,nSelGates])
    FOR dd=0,N_ELEMENTS(clrArr)-1 DO BEGIN
        IF clrArr[dd] EQ GET_BACKGROUND() THEN CONTINUE
        bmGate      = ARRAY_INDICES(clrArr,dd)
        bm          = bmGate[0]
        rg          = bmGate[1]

        lat     = REFORM(sel_bndArr_grid[0,*,*,bm,rg])
        lon     = REFORM(sel_bndArr_grid[1,*,*,bm,rg])

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

;    RAD_FIT_PLOT_SCAN_TITLE,2,3,1,0                         $
;;        ,SCAN_ID            = scan_id                       $
;        ,SCAN_STARTJUL      = scan_startJul                 $
;        ,/BAR

    ;PLOT_COLORBAR,2,2,1,0,CHARSIZE=0.75,SCALE=scale2,LEVEL_FORMAT='(F3.1)'
    PLOT_COLORBAR,CHARSIZE=0.75,SCALE=scale2,LEVEL_FORMAT=format2,PANEL_POSITION=posit,/KEEP

    posit           = DEFINE_PANEL(2,3,1,2,/BAR,/WITH_INFO)
    posit[0]    += xnudge
    posit[2]    += xnudge
    PLOT_GATE_BEAM,sel_bndArr_grid,clrArr                                       $   
    ;    ,YVALS          = beamVec                                               $
    ;    ,XCOORDS        = 'lon'                                                 $   
        ,YCOORDS        = 'rang'                                                $   
        ,YRANGE         = dRange                                                $   
        ,XCHARSIZE      = 0.6                                                   $   
        ,YCHARSIZE      = 0.6                                                   $   
        ,POSITION       = posit
ENDFOR

PS_CLOSE
