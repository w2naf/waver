PRO COMP_RAW_FIR,julVec,data,bndArr_grid,FILENAME=_fileName,TITLE=title,BEAMVEC=_beamVec,GATEVEC=_gateVec,SCAN_IDS=scan_ids
;title: String that appears on the title of the plot.
;folder: Directory in which movie frames will be stored.

IF ~KEYWORD_SET(title) THEN title='Untitled'
IF ~KEYWORD_SET(scan_ids) THEN scan_ids = julVec*0.

COMMON RAD_DATA_BLK
COMMON MUSIC_PARAMS
IF KEYWORD_SET(param) THEN SET_PARAMETER,param
IF KEYWORD_SET(scatterflag) THEN RAD_SET_SCATTERFLAG,scatterflag

IF N_ELEMENTS(fir_scale) NE 2 THEN fir_scale=[0,0]
IF fir_scale[0] EQ fir_scale[1] THEN BEGIN
  sd   = STDDEV(ABS(data))
  mean = MEAN(ABS(data))
  sdMult = 1.
  
  scMax = CEIL(mean + sdMult*sd)
  tmpScale = scMax*[-1.,1]
;  tmpParam = 'power'
  tmpParam = param
ENDIF ELSE BEGIN
  tmpParam = param
  tmpScale = fir_scale
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


; Plot stuff! ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IF ~KEYWORD_SET(_fileName) THEN fileName = DIR('raw_fir_compare_rti.ps') ELSE fileName=_fileName
PS_OPEN,fileName
SET_FORMAT,/PORTRAIT,/SARDINES
CLEAR_PAGE,/NEXT
subtitle        = STRUPCASE(radar) + ' ' + FORMAT_JULDATE(julVec[0],/DATE)
PLOT_TITLE,subTitle,title

ymaps = 3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
xrange  = [MIN(julVec),MAX(julVec)]

beam    = RAD_GET_BEAM()
bmInx   = WHERE(beamVec GE beam,cnt)
IF cnt EQ 0 THEN bmInx = dims[1]-1 ELSE bmInx = bmInx[0]
beam    = beamVec[bmInx]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Standard RTI Plot ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IF N_ELEMENTS(scale) NE 2 THEN scale =[0,0]
IF scale[0] EQ scale[1] THEN BEGIN
  stndScale = GET_SCALE()
ENDIF ELSE stndScale = scale

posit   = DEFINE_PANEL(1,ymaps,0,0,/BAR)
RAD_FIT_PLOT_RTI_PANEL                                                  $
    ,COORDS             = 'gs_rang'                                     $
    ,yrange             = drange                                        $
    ,DATE               = fir_date                                      $
    ,TIME               = fir_time                                      $
    ,PARAM              = param                                         $
    ,BEAM               = beam                                          $
    ,SCALE              = scale                                         $
;    ,XTITLE             = xtitle                                        $
    ,CHARSIZE           = 0.75                                          $
;    ,/LAST                                                              $
    ,POSITION           = posit
RAD_FIT_PLOT_RTI_TITLE,1,ymaps,0,0,BEAM=beam,/BAR,ADDSTR='Raw Data'
PLOT_COLORBAR,CHARSIZE=0.75,PANEL_POSITION=posit,SCALE=stndScale
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BEAM_AZM,beam,MAGNAZM=magnAzm,GEOGAZM=geogAzm
gAzm$   = NUMSTR(geogAzm) + TEXTOIDL('^{\circ}')
mAzm$   = NUMSTR(magnAzm) + TEXTOIDL('^{\circ}')

xtitle  = 'Time [UT] - Beam '+ NUMSTR(beam)                             $
        + ' (Geog. Azm: ' + gAzm$ + ', Magn. Azm: ' + mAzm$ + ')'

xrange  = [MIN(julVec),MAX(julVec)]
xticks  = GET_XTICKS(xrange,xminor=xminor)

posit   = DEFINE_PANEL(1,ymaps,0,1,/BAR)
PLOT,[0,0]                                                              $
    ,/NODATA                                                            $   
    ,XTICKFORMAT        = 'LABEL_DATE'                                  $   
    ,CHARSIZE           = 0.75                                          $   
    ,YTITLE             = 'GS Mapped Range [km]'                        $
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

RAD_FIT_PLOT_RTI_TITLE,1,ymaps,0,1,BEAM=beam,/BAR,ADDSTR='FIR Filtered Data'
PLOT_COLORBAR,CHARSIZE=0.75,PANEL_POSITION=posit,SCALE=tmpScale,PARAMETER=tmpParam,LEGEND=legend
PS_CLOSE,/NO_FILENAME
PS2PNG,fileName
END
