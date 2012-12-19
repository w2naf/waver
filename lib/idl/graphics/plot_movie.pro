PRO PLOT_MOVIE,julVec,data,bndArr_grid,folder,TITLE=title,BEAMVEC=_beamVec,GATEVEC=_gateVec,SCAN_IDS=scan_ids,SCALE=_scale
;title: String that appears on the title of the plot.
;folder: Directory in which movie frames will be stored.

IF ~KEYWORD_SET(title) THEN title='Untitled'
IF ~KEYWORD_SET(scan_ids) THEN scan_ids = julVec*0.

COMMON RAD_DATA_BLK
COMMON MUSIC_PARAMS
SET_PARAMETER,param

IF N_ELEMENTS(_scale) NE 2 THEN _scale = [0,0]
IF _scale[0] EQ _scale[1] THEN BEGIN
  sd   = STDDEV(ABS(data))
  mean = MEAN(ABS(data))
  sdMult = 1.
  
  scMax = CEIL(mean + sdMult*sd)
  tmpScale = scMax*[-1.,1]
;  tmpParam = 'power'
  tmpParam = param
ENDIF ELSE BEGIN
  tmpScale = _scale
  tmpParam = param
ENDELSE
legend = GET_DEFAULT_TITLE(param)

nSteps = N_ELEMENTS(julVec)
dt  = julVec[1]-julVec[0]

dims    = SIZE(data,/DIM)
clrArr  = REFORM(GET_COLOR_INDEX(data,PARAM=tmpParam,SCALE=tmpScale,/NAN),dims)

IF ~KEYWORD_SET(_beamVec) THEN BEGIN
  beamVec = INDGEN(dims[1])
ENDIF ELSE beamVec = _beamVec

IF ~KEYWORD_SET(_gateVec) THEN BEGIN
  gateVec = INDGEN(dims[2])
ENDIF ELSE gateVec = _gateVec

FOR ss=0,nSteps-1 DO BEGIN
  OPEN_LOOP_PLOT,'output/kmaps/',folder,ss
  SFJUL,scanDate,scanTime,julVec[ss],/JUL_TO_DATE

  ; Plot stuff! ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  SET_FORMAT,/PORTRAIT,/SARDINES
  CLEAR_PAGE,/NEXT
  subtitle        = STRUPCASE(radar) + ' ' + FORMAT_DATE(scanDate,/HUMAN)
  PLOT_TITLE,subTitle,title

  ymaps = 2

  ;Plot original FOV.
  ;Make position span 2 rows.
  posit           =  DEFINE_PANEL(1,ymaps,0,0,/BAR)

;  XYOUTS,posit[0],1.01*posit[3],title,CHARSIZE=0.75,ALIGN=0,/NORMAL
  MAP_PLOT_PANEL                                          $
      ,DATE               = scanDate                      $
      ,TIME               = scanTime                    $
      ,XRANGE             = movieXRange                     $
      ,YRANGE             = movieYRange                     $
      ,/NO_FILL                                           $
      ,ROTATE             = movieRotate                        $
      ,POSITION           = posit


  FOR bm=0,dims[1]-1 DO BEGIN
    FOR rg=0,dims[2]-1 DO BEGIN
        IF clrArr[ss,bm,rg] EQ GET_BACKGROUND() THEN CONTINUE

        lat     = REFORM(bndArr_grid[0,*,*,bm,rg])
        lon     = REFORM(bndArr_grid[1,*,*,bm,rg])

        p0      = CALC_STEREO_COORDS(lat[0,0],lon[0,0],ROTATE=movieRotate)
        p1      = CALC_STEREO_COORDS(lat[0,1],lon[0,1],ROTATE=movieRotate)
        p2      = CALC_STEREO_COORDS(lat[1,1],lon[1,1],ROTATE=movieRotate)
        p3      = CALC_STEREO_COORDS(lat[1,0],lon[1,0],ROTATE=movieRotate)

        xx          = [p0[0], p1[0], p2[0], p3[0]]
        yy          = [p0[1], p1[1], p2[1], p3[1]]
        POLYFILL,xx,yy,COLOR=clrArr[ss,bm,rg],NOCLIP=0
      ENDFOR
  ENDFOR

  MAP_PLOT_PANEL                                      $
      ,DATE               = scanDate                  $
      ,TIME               = scanTime                  $
      ,XRANGE             = movieXRange               $
      ,YRANGE             = movieYRange               $
      ,/NO_FILL                                       $
      ,ROTATE             = movieRotate               $
      ,POSITION           = posit

  OVERLAY_FOV_NAME                                    $
      ,JUL            = julVec[ss]                    $
      ,IDS            = stid                          $
      ,CHARSIZE       = 0.60                          $
      ,CHARTHICK      = 2.00                          $
      ,ROTATE         = movieRotate                   $
      ,/ANNOTATE

  RAD_FIT_PLOT_SCAN_TITLE,1,ymaps,0,0                 $
      ,SCAN_ID            = scan_ids[ss]              $
      ,SCAN_STARTJUL      = julVec[ss]                $ 
      ,/BAR

  PLOT_COLORBAR,1,ymaps,0,0,CHARSIZE=0.75,SCALE=tmpScale,PARAMETER=tmpParam,LEGEND=legend

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

  polyX   = [julVec[0],julVec[0],julVec[ss],julVec[ss]]
  polyY   = [0,1,1,0]
  POLYFILL,polyX,polyY

  beam    = RAD_GET_BEAM()
  bmInx   = WHERE(beamVec GE beam,cnt)
  IF cnt EQ 0 THEN bmInx = dims[1]-1 ELSE bmInx = bmInx[0]
  beam    = beamVec[bmInx]

  BEAM_AZM,beam,MAGNAZM=magnAzm,GEOGAZM=geogAzm
  gAzm$   = NUMSTR(geogAzm) + TEXTOIDL('^{\circ}')
  mAzm$   = NUMSTR(magnAzm) + TEXTOIDL('^{\circ}')

  xtitle  = 'Time [UT] - Beam '+ NUMSTR(beam)                             $
          + ' (Geog. Azm: ' + gAzm$ + ', Magn. Azm: ' + mAzm$ + ')'

  posit   = DEFINE_PANEL(1,2,0,1,/BAR,/WITH_INFO)
  posit[3] = 0.380
  PLOT,[0,0]                                                              $
      ,/NODATA                                                            $   
      ,XTICKFORMAT        = 'LABEL_DATE'                                  $   
      ,CHARSIZE           = 0.75                                          $   
      ,YTITLE             = 'GS Mapped Range!C[km]'                       $
      ,XTITLE             = xTitle                                        $   
      ,XRANGE             = xrange                                        $
      ,XTICKS             = xTicks                                        $   
      ,XMINOR             = xMinor                                        $   
      ,YRANGE             = drange                                        $   
      ,POSITION           = posit                                         $   
      ,/XSTYLE                                                            $   
      ,/YSTYLE

    FOR ts=0,nSteps-1 DO BEGIN
      FOR rg=0,dims[2]-1 DO BEGIN
        IF clrArr[ts,bmInx,rg] EQ GET_BACKGROUND() THEN CONTINUE
        x0 = julVec[ts]
        x1 = x0 + dt
        y0 = bndArr_grid[3,0,0,bmInx,rg]
        y1 = bndArr_grid[3,0,1,bmInx,rg]

        xx          = [x0, x0, x1, x1]
        yy          = [y0, y1, y1, y0]
        POLYFILL,xx,yy,COLOR=clrArr[ts,bmInx,rg],NOCLIP=0
        print,ts,bmInx,rg,clrArr[ts,bmInx,rg] 
      ENDFOR
    ENDFOR
;      ,PARAM              = param                                         $

  PLOT_COLORBAR,CHARSIZE=0.75,PANEL_POSITION=posit,SCALE=tmpScale,PARAMETER=tmpParam,LEGEND=legend
ENDFOR
PS_CLOSE
END
