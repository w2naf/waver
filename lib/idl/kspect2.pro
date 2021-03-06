PRO KSPECT2
COMMON RAD_DATA_BLK
COMMON MUSIC_PARAMS

RESTORE

IF N_ELEMENTS(gl) EQ 0 THEN gl = 0
scanDate        = dateVec[0]
;@event

IF KEYWORD_SET(sim) THEN BEGIN
    rgNormalArr  = gwsim(LR=lr,BNDLR=lrBnd,JULS=scan_sJulVec,KEEP_LR=keep_lr)
    IF gl GE 2 THEN BEGIN
        @comp_sim_tid.pro
    ENDIF
ENDIF ELSE BEGIN
    ;rgNormalArr  = NORMALIZE_RANGE(interpData)
    rgNormalArr = interpData
    ;IF gl GE 3 THEN @plot_range_dep_remove.pro
ENDELSE


SPAWN,'rm -f output/kmaps/kspect/*'
SPAWN,'mkdir -p output/kmaps/kspect/'

thick           = 4
!P.THICK        = thick
!P.CHARTHICK    = thick
!X.THICK        = thick
!Y.THICK        = thick

interpData      = rgNormalArr

;plotBeam = [  5, 10, 15,  5, 10, 15,  5, 10, 15]
;plotGate = [ 42, 42, 42, 32, 32, 32, 22, 22, 22]
;
;plotBeam = [  2,  6,  10,  2,  6,  10,  2,  6,  10]
;plotGate = [ 40, 40, 40, 36, 36, 36, 32, 32, 32]

beamMin = MIN(selBeamVec)
beamMed = MEDIAN(selBeamVec)
beamMax = MAX(selBeamVec)

gateMin = MIN(selGateVec)
gateMed = MEDIAN(selGateVec)
gateMax = MAX(selGateVec)

plotBeam = INTARR(9)
plotGate = INTARR(9)

plotBeam[[0,3,6]] = beamMin
plotBeam[[1,4,7]] = beamMed
plotBeam[[2,5,8]] = beamMax

plotGate[[8,7,6]] = gateMin
plotGate[[5,4,3]] = gateMed
plotGate[[2,1,0]] = gateMax

plotBeamInx = plotBeam
plotGateInx = plotGate
FOR ii=0,N_ELEMENTS(plotBeam)-1 DO BEGIN
   plotBeamInx[ii] = WHERE(selBeamArr[*,0] EQ plotBeam[ii]) 
   plotGateInx[ii] = WHERE(selGateArr[0,*] EQ plotGate[ii]) 
ENDFOR

mpGl    = 3
IF gl GE mpGl THEN BEGIN
    SET_FORMAT,/LANDSCAPE,/SARDINES
    file            = DIR('output/kmaps/kspect/multi.ps',/PS)
ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Time interpolation - Fit everything onto julVec grid.
dims       = SIZE(interpData,/DIM)
timeInterpArr = FLTARR(nSteps,nSelBeams,nSelGates)
FOR bb=0,dims[1]-1 DO BEGIN
    FOR gg=0,dims[2]-1 DO BEGIN
        good    = WHERE(FINITE(interpData[*,bb,gg]),cnt)
        IF cnt NE 0 THEN timeInterpArr[*,bb,gg] = INTERPOL(interpData[good,bb,gg],scan_sJulVec[good],julVec)
    ENDFOR
ENDFOR

scan_ids = PARAM_REGRID(scan_sJulVec,scan_ids,julVec)

IF gl GE mpGL THEN BEGIN
    CLEAR_PAGE,/NEXT
    PLOT_TITLE,'Time Series of Selected Cells',STRUPCASE(radar) + ' ' + FORMAT_DATE(scanDate,/HUMAN)
    yRange  = [0,5]

    yMax    = MAX(interpdata[*,plotBeamInx,plotGateInx],/NAN,MIN=yMin)
    IF yMin LT 0 THEN BEGIN
        yMax        = MAX(ABS(interpdata[*,plotBeamInx,plotGateInx]),/NAN)
        yrange      = yMax * [-1,1]
    ENDIF ELSE yrange = [0, yMax]

    MULTIPLOT,scan_sJulVec,interpData                                       $
        ,PLOTGATE           = plotGate                                      $
        ,PLOTBEAM           = plotBeam                                      $
        ,BEAMARR            = selBeamArr                                    $
        ,GATEARR            = selGateArr                                    $
    ;    ,YRANGE             = yRange                                        $
        ,OPLOTARR           = timeInterpArr                                 $
        ,OPLOT_XAXIS        = julVec                                        $
        ,OPLOTLEGEND        = 'Time Interpolated Data'                      $
        ,/YSTYLE                                                            $
        ,XTITLE             = 'UT'                                          $
        ,XTICKFORMAT        = 'LABEL_DATE'                                  $
        ,/XSTYLE                                                            $
        ,YTITLE             = 'Power [dB]'                                  $
        ,XCHARSIZE          = 0.5                                           $
        ,YCHARSIZE          = 0.5                                           $
        ,GEOMETRY           = [3,3]
ENDIF   ;mpGL

interpData      = timeInterpArr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;FIR Filtering
IF KEYWORD_SET(fir_filter) THEN BEGIN
  dims       = SIZE(interpData,/DIM)
  filtArr    = interpData
  IF gl GE mpGl THEN BEGIN
    SET_FORMAT,/GUPPIES,/PORTRAIT
    CLEAR_PAGE,/NEXT
  ENDIF
  FOR bb=0,dims[1]-1 DO BEGIN
      FOR gg=0,dims[2]-1 DO BEGIN
          IF bb EQ 0 AND gg EQ 0 AND gl GE mpGL THEN plot_info = 1 ELSE plot_info=0
          filt = FIR_FILT(REFORM(julVec),REFORM(interpData[*,bb,gg]),FLOW=bandLim[0],FHIGH=bandLim[1],PLOT_INFO=plot_info,VALIDJULS=validJuls)
          filtArr[*,bb,gg] = filt
  ;       filtArr[*,bb,gg] = interpData[*,bb,gg]
      ENDFOR
  ENDFOR
  interpData = filtArr

  IF N_ELEMENTS(fir_date) EQ 2 AND N_ELEMENTS(fir_time) EQ 2 THEN BEGIN
    SFJUL,fir_date,fir_time,vsjul,vfjul
    validJuls[0] = vsjul
    validJuls[1] = vfjul
  ENDIF

  good        = WHERE(julVec GE validJuls[0] AND julVec LE validJuls[1],filtNSteps,COMPLEMENT=bad)

  IF ~KEYWORD_SET(zero_padding) THEN BEGIN
    julVec      = julVec[good]
    interpData  = interpData[good,*,*]
    filtJulVec  = julVec
    filtArr     = interpData
    nsteps = filtNsteps
  ENDIF ELSE BEGIN
    interpData[bad,*,*] = 0
    filtJulVec  = julVec[good]
    filtArr     = interpData[good,*,*]
  ENDELSE

  IF gl GE mpGL THEN BEGIN
      SET_FORMAT,/LANDSCAPE,/SARDINES
      CLEAR_PAGE,/NEXT
      PLOT_TITLE,'Filtered Time Series of Selected Cells',STRUPCASE(radar) + ' ' + FORMAT_DATE(scanDate,/HUMAN)
      MULTIPLOT,julVec,interpData                                         $
          ,PLOTGATE           = plotGate                                      $
          ,PLOTBEAM           = plotBeam                                      $
          ,BEAMARR            = selBeamArr                                    $
          ,GATEARR            = selGateArr                                    $
      ;    ,YRANGE             = yrange                                        $
  ;        ,OPLOTARR           = linFitArr                                     $
  ;        ,OPLOTLEGEND        = 'Linear Fit'                                  $
          ,/YSTYLE                                                            $
          ,XTITLE             = 'UT'                                          $
          ,XTICKFORMAT        = 'LABEL_DATE'                                  $
          ,/XSTYLE                                                            $
          ,YTITLE             = 'Power [dB]'                                  $
          ,XCHARSIZE          = 0.5                                           $
          ,YCHARSIZE          = 0.5                                           $
          ,GEOMETRY           = [3,3]
  ENDIF   ;mpGL
ENDIF ;fir_filter

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Linear detrending
dims       = SIZE(interpData,/DIM)
linFitArr  = interpData
FOR bb=0,dims[1]-1 DO BEGIN
    FOR gg=0,dims[2]-1 DO BEGIN
        coefs = REGRESS(REFORM(julVec),REFORM(interpData[*,bb,gg]),STATUS=fitStatus,YFIT=yfit)
        IF fitStatus NE 0 THEN STOP
        linFitArr[*,bb,gg] = yfit
    ENDFOR
ENDFOR

IF gl GE mpGL THEN BEGIN
    CLEAR_PAGE,/NEXT
    PLOT_TITLE,'Time Series of Selected Cells',STRUPCASE(radar) + ' ' + FORMAT_DATE(scanDate,/HUMAN)
    MULTIPLOT,julVec,interpData                                         $
        ,PLOTGATE           = plotGate                                      $
        ,PLOTBEAM           = plotBeam                                      $
        ,BEAMARR            = selBeamArr                                    $
        ,GATEARR            = selGateArr                                    $
    ;    ,YRANGE             = yrange                                        $
        ,OPLOTARR           = linFitArr                                     $
        ,OPLOTLEGEND        = 'Linear Fit'                                  $
        ,/YSTYLE                                                            $
        ,XTITLE             = 'UT'                                          $
        ,XTICKFORMAT        = 'LABEL_DATE'                                  $
        ,/XSTYLE                                                            $
        ,YTITLE             = 'Power [dB]'                                  $
        ,XCHARSIZE          = 0.5                                           $
        ,YCHARSIZE          = 0.5                                           $
        ,GEOMETRY           = [3,3]
ENDIF   ;mpGL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
interpData      = interpData - linFitArr
;Calculate Cell Mean - just a check on things
dims    = SIZE(interpData,/DIM)
meanArr = FLTARR(dims[1],dims[2])
meanArr$= STRING(meanArr)
FOR bb=0,dims[1]-1 DO BEGIN
    FOR gg=0,dims[2]-1 DO BEGIN
        meanArr[bb,gg]  = MEAN(interpData[*,bb,gg],/NAN)
        meanArr$[bb,gg] = 'Mean: ' + NUMSTR(meanArr[bb,gg],1)
    ENDFOR
ENDFOR

;Calculate Hanning Window Array
dims       = SIZE(interpData,/DIM)
hanningVec = HANNING(nSteps)
hanningArr = interpData
FOR bb=0,dims[1]-1 DO BEGIN
    FOR gg=0,dims[2]-1 DO BEGIN
        hanningArr[*,bb,gg] = hanningVec
    ENDFOR
ENDFOR

IF gl GE mpGL THEN BEGIN
    CLEAR_PAGE,/NEXT
    PLOT_TITLE,'Time Series of Selected Cells (Detrended)',STRUPCASE(radar) + ' ' + FORMAT_DATE(scanDate,/HUMAN)
    det_Yrange      = [-1, 1] * 2.
    MULTIPLOT,julVec,interpData                                         $
        ,PLOTGATE           = plotGate                                      $
        ,PLOTBEAM           = plotBeam                                      $
        ,BEAMARR            = selBeamArr                                    $
        ,GATEARR            = selGateArr                                    $
        ,OPLOTARR           = det_yRange[1]*hanningArr                      $
        ,OPLOTLEGEND        = NUMSTR(det_YRange[1],1)+'*Hanning Window'     $
    ;    ,YRANGE             = det_Yrange                                    $
        ,/YSTYLE                                                            $
        ,XTITLE             = 'UT'                                          $
        ,XTICKFORMAT        = 'LABEL_DATE'                                  $
        ,/XSTYLE                                                            $
        ,YTITLE             = 'Power [dB]'                                  $
        ,XCHARSIZE          = 0.5                                           $
        ,YCHARSIZE          = 0.5                                           $
        ,GEOMETRY           = [3,3]
ENDIF   ;mpGL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
interpData      = interpData * hanningArr
IF gl GE mpGL THEN BEGIN
    CLEAR_PAGE,/NEXT
    PLOT_TITLE,'Time Series of Selected Cells (Pre-FFT)',STRUPCASE(radar) + ' ' + FORMAT_DATE(scanDate,/HUMAN)
    MULTIPLOT,julVec,interpData                                         $
        ,PLOTGATE           = plotGate                                      $
        ,PLOTBEAM           = plotBeam                                      $
        ,BEAMARR            = selBeamArr                                    $
        ,GATEARR            = selGateArr                                    $
    ;    ,YRANGE             = det_Yrange                                    $
        ,/YSTYLE                                                            $
        ,XTITLE             = 'UT'                                          $
        ,XTICKFORMAT        = 'LABEL_DATE'                                  $
        ,/XSTYLE                                                            $
        ,YTITLE             = 'Power [dB]'                                  $
        ,XCHARSIZE          = 0.5                                           $
        ,YCHARSIZE          = 0.5                                           $
        ,GEOMETRY           = [3,3]
ENDIF   ; mpGL


;Calculate FFT Window Array
;Calculate Frequency Vector
dt_sec     = timeStep * 60.
even    = ~(nsteps MOD 2)
freqVec = INDGEN(nSteps)
IF KEYWORD_SET(even) THEN BEGIN
    shift = nSteps / 2 - 1
    n21 = nSteps/2 + 1
    freqVec[n21] = n21 - nSteps + FINDGEN(n21-2)
ENDIF ELSE BEGIN
    shift = nSteps / 2
    n21 = (nSteps+1)/2
    freqVec[n21] = n21 - nSteps + FINDGEN(n21-1)
ENDELSE
freqVec = SHIFT(freqVec/(nSteps*dt_sec),shift)

dims       = SIZE(interpData,/DIM)
spectArr   = COMPLEXARR(dims)
FOR bb=0,dims[1]-1 DO BEGIN
    FOR gg=0,dims[2]-1 DO BEGIN
        spectArr[*,bb,gg] = SHIFT(FFT(interpData[*,bb,gg]),shift)
    ENDFOR
ENDFOR

; Full FFT Plots ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IF gl GE mpGL THEN BEGIN
    xAxis           = freqVec * 1000.
    yAxis           = REAL_PART(spectArr)
    legend          = 'Real Part'
    oPlotArr        = IMAGINARY(spectArr)
    oPlotLegend     = 'Imaginary'

    ;Set fftYRange
    oPlotMin    = MIN(oPlotArr[*,plotBeamInx,plotGateInx],/NaN) 
    yAxisMin    = MIN(yAxis[*,plotBeamInx,plotGateInx],/NaN) 
    IF oPlotMin LT yAxisMin THEN fftMin = oPlotMin ELSE fftMin = yAxisMin

    oPlotMax    = MAX(oPlotArr[*,plotBeamInx,plotGateInx],/NaN) 
    yAxisMax    = MAX(yAxis[*,plotBeamInx,plotGateInx],/NaN)
    IF oPlotMax GT yAxisMax THEN fftMax = oPlotMax ELSE fftMax = yAxisMax

    fftYrange   = [fftMin, fftMax]
    IF ~KEYWORD_SET(fftXmax) THEN BEGIN
        IF KEYWORD_SET(fftxrange) THEN s=TEMPORARY(fftXrange)
    ENDIF ELSE fftXrange = fftXMax *[-1,1]

    ;xaxis   = findgen(N_elements(xaxis))
    CLEAR_PAGE,/NEXT
    PLOT_TITLE,'Temporal Spectrum',STRUPCASE(radar) + ' ' + FORMAT_DATE(scanDate,/HUMAN)
    MULTIPLOT,xAxis,yAxis                                                   $
        ,PLOTGATE           = plotGate                                      $
        ,PLOTBEAM           = plotBeam                                      $
        ,BEAMARR            = selBeamArr                                    $
        ,GATEARR            = selGateArr                                    $
        ,OPLOTARR           = oPlotArr                                      $
        ,OPLOTLEGEND        = oPlotLegend                                   $
        ,LEGEND             = legend                                        $
        ,/YSTYLE                                                            $
        ,XTITLE             = 'Frequency [mHz]'                             $
        ,XRANGE             = fftXrange                                     $
        ,/XSTYLE                                                            $
        ,YTITLE             = TEXTOIDL('s(f) [(dB)]')                       $
        ,XCHARSIZE          = 0.5                                           $
        ,YCHARSIZE          = 0.5                                           $
        ,GEOMETRY           = [3,3]

    ; Positive Frequency Magnitude and Band Limits ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    pf      = WHERE(freqVec GT 0)
    xAxis   = freqVec[pf] * 1000.
    yAxis   = ABS(spectArr[pf,*,*])^2

    fftYrange = [0,MAX(yAxis[*,plotBeamInx,plotGateInx],/NaN)]

    IF ~KEYWORD_SET(fftXmax) THEN BEGIN
        fftXrange = [0,CEIL(MAX(xAxis))]
    ENDIF ELSE fftXrange = [0,fftXMax]

    CLEAR_PAGE,/NEXT
    PLOT_TITLE,'Temporal Spectrum',STRUPCASE(radar) + ' ' + FORMAT_DATE(scanDate,/HUMAN)
    IF KEYWORD_SET(bandLim) THEN plotBandLim = bandLim*1000.
    MULTIPLOT,xAxis,yAxis                                                   $
        ,PLOTGATE           = plotGate                                      $
        ,PLOTBEAM           = plotBeam                                      $
        ,BEAMARR            = selBeamArr                                    $
        ,GATEARR            = selGateArr                                    $
        ,/YSTYLE                                                            $
        ,XTITLE             = 'Frequency [mHz]'                             $
        ,XRANGE             = fftXRange                                     $
        ,BANDLIM            = plotBandLim                                   $
        ,/XSTYLE                                                            $
        ,YTITLE             = TEXTOIDL('S(f) [(dB)^2]')                     $
    ;    ,YRANGE             = fftYrange                                     $
        ,XCHARSIZE          = 0.5                                           $
        ,YCHARSIZE          = 0.5                                           $
        ,GEOMETRY           = [3,3]

    PS_CLOSE
ENDIF   ; mpGL


IF KEYWORD_SET(fir_filter) AND gl GE mpGL THEN BEGIN
;  fir_scale = [-10,10]
  PICKLE_MY_DATA,radar,filtJulVec,filtArr,sel_ctrArr_grid,sel_bndArr_grid,run_id,PATH='output/kmaps/pickle/',PREFIX='FIR_'
  title = 'Raw and FIR Filtered ('+NUMSTR(bandLim[0]*1000.,1)+'-'+NUMSTR(bandLim[1]*1000.,1)+' mHz) Data Comparison'
  COMP_RAW_FIR,filtJulVec,filtArr,sel_bndArr_grid       $
    ,FILENAME   = DIR('output/kmaps/raw_fir_compare_rti.ps')  $
    ,TITLE      = title                             $
    ,BEAMVEC    = selBeamVec                        $
    ,GATEVEC    = selGateVec                        $
    ,SCAN_IDS   = scan_ids
;    ,/AUTOSCALE

  IF N_ELEMENTS(fir_scale) NE 2 THEN fir_scale = [0,0]
  title = 'FIR Filtered ('+NUMSTR(bandLim[0]*1000.,1)+'-'+NUMSTR(bandLim[1]*1000.,1)+' mHz) Data'
  PLOT_MOVIE,filtJulVec,filtArr,sel_bndArr_grid,'fir_filtered'       $
    ,TITLE      = title                             $
    ,BEAMVEC    = selBeamVec                        $
    ,GATEVEC    = selGateVec                        $
    ,SCAN_IDS   = scan_ids                          $
    ,SCALE      = fir_scale
ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Calculate Spectral Density Matrix
;See Samson et al. [1990] - Goose Bay Radar Observations of Earth Reflected Gravity Waves in the High-Latitude Ionosphere
nCells  = N_ELEMENTS(selBeamArr)
Dlm     = COMPLEXARR(nCells,nCells)

pf      = WHERE(freqVec GT 0)
posFreqVec      = freqVec[pf]
posSpectArr     = spectArr[pf,*,*]

IF gl GE 1 THEN BEGIN
    SAVE,FILENAME='spect.sav'
    IF gl GE 2 THEN png=1 ELSE png=0
    PLOT_FULL_SPECTRUM,PNG=png
ENDIF

IF N_ELEMENTS(bandLim) NE 2 THEN bandLim = [0,0]
IF bandLim[0] NE bandLim[1] AND ~KEYWORD_SET(fir_filter) THEN BEGIN
    ;blInx   = WHERE(ABS(freqVec) GE bandLim[0] AND ABS(freqVec) LE bandLim[1],cnt)
    blInx   = WHERE(posFreqVec GE bandLim[0] AND posFreqVec LE bandLim[1],cnt)
    IF cnt NE 0 THEN BEGIN
        spectOfInt      = posSpectArr[blInx,*,*]
        freqVecOfInt    = posFreqVec[blInx]
    ENDIF ELSE BEGIN
        PRINT,'WARNING: Spectrum of interest not available.'
        STOP
    ENDELSE
ENDIF ELSE BEGIN
    spectOfInt          = posSpectArr
    freqVecOfInt        = posFreqVec
ENDELSE
    

;Find the dominant frequency within the passband.
nPf     = N_ELEMENTS(spectOfInt[*,0,0])
avg_psd = FLTARR(nPf)
FOR ff=0,nPf-1 DO avg_psd[ff]=MEAN(ABS(spectOfInt[ff,*,*]),/NAN)
fMaxVal = MAX(avg_psd,fMaxInx)
fMax    = freqVecOfInt[fMaxInx]

llInxTable   = FLTARR(5,nCells)
FOR ll=0,nCells-1 DO BEGIN
    llAI             = ARRAY_INDICES(selBeamArr,ll)
    ew_dist          = lr[0,llAI[0],llAI[1]]
    ns_dist          = lr[1,llAI[0],llAI[1]]
    llInxTable[*,ll] = [ll, selBeamArr[ll], selGateArr[ll],ns_dist,ew_dist]
    spectL           = spectOfInt[*,llAI[0],llAI[1]]
    FOR mm=0,nCells-1 DO BEGIN
        mmAI         = ARRAY_INDICES(selBeamArr,mm)
        spectM       = spectOfInt[*,mmAI[0],mmAI[1]]
        Dlm[ll,mm]   = TOTAL(spectL * CONJ(spectM))
    ENDFOR      ;mm
ENDFOR  ;ll

IF gl GE 3 THEN BEGIN
    file    = DIR('output/kmaps/kspect/dlm_abs.ps',/PS)
    CLEAR_PAGE,/NEXT
    data   = ABS(dlm)
    sd      = STDDEV(data,/NAN)
    mean    = MEAN(data,/NAN)
    scMax   = mean + 2.*sd
    dlmScale= scMax*[0,1.]
    image   = GET_COLOR_INDEX(data,PARAM='power',SCALE=dlmScale,/NAN)
    image   = REFORM(image,[nCells,nCells])

    dlmCharSize     = 0.60
    posit   = DEFINE_PANEL(1,1,0,0,/BAR)
    IF KEYWORD_SET(bandLim) THEN bl$ = 'Band Limit: ' + NUMSTR(bandLim[0]*1000.,2) + ' - ' + NUMSTR(bandLim[1]*1000.,2) + ' mHz' ELSE bl$ = 'Band Limit: Entire FFT Spectrum'
    subtitle= STRUPCASE(radar) + ' ' + FORMAT_DATE(scanDate,/HUMAN) + ' ' + bl$
    PLOT_TITLE,TEXTOIDL('ABS(Cross Spectral Density Matrix D_{lm})'),subTitle
    DRAW_IMAGE,image                                                        $
        ,XTITLE     = 'l'                                                   $
        ,YTITLE     = 'm'                                                   $
        ,XSTYLE     = 9                                                     $
        ,YSTYLE     = 9                                                     $
        ,CHARSIZE   = dlmCharSize                                           $
        ,POSITION   = posit                                                 $
        ,/NO_SCALE

    AXIS,/XAXIS,XRANGE=gateRange,/XSTYLE,CHARSIZE=dlmCharSize,XTITLE='Range Gate'
    AXIS,/YAXIS,YRANGE=gateRange,/YSTYLE,CHARSIZE=dlmCharSize,YTITLE='Range Gate'

    IF scMax LT 0.1 THEN BEGIN
        level_format = '(E12.1)' 
    ENDIF ELSE IF scMax LT 8 THEN BEGIN
        level_format = '(F12.2)' 
    ENDIF ELSE IF N_ELEMENTS(level_format) NE 0 THEN s = TEMPORARY(level_format)

    PLOT_COLORBAR,1,1,0,0,SCALE=dlmScale,/KEEP_FIRST_LAST_LABEL,LEGEND='ABS(Spectral Density)',PARAM='power',LEVEL_FORMAT=level_format,CHARSIZE=0.75

    max$ = NUMSTR(MAX(data,/NAN),5)
    min$ = NUMSTR(MIN(data,/NAN),5)
    mean$ =NUMSTR(MEAN(data,/NAN),5)
    sd$  = NUMSTR(sd,5)
    var$ = NUMSTR(sd^2,5)
    txt$ = 'Max: ' + max$ + ' Min: ' + min$ + ' Mean: ' + mean$ + TEXTOIDL(' \sigma: ') + sd$ $
         + TEXTOIDL(' \sigma^2: ') + var$
    XYOUTS,0.1,0.03,txt$,CHARSIZE=0.75,/NORMAL

    PS_CLOSE
    PS2PNG,file,ROTATE=270
ENDIF


;Real Part
IF gl GE 3 THEN BEGIN
    file    = DIR('output/kmaps/kspect/dlm_re.ps',/PS)
    CLEAR_PAGE,/NEXT
    data    = REAL_PART(dlm)
    sd      = STDDEV(data,/NAN)
    mean    = MEAN(data,/NAN)
    scMax   = mean + 2.*sd
    scMin   = mean - 2.*sd
    IF ABS(scMin) GT ABS(scMax) THEN scMax = ABS(scMin)
    dlmScale= scMax*[-1,1.]

    image   = GET_COLOR_INDEX(data,PARAM='velocity',SCALE=dlmScale,/NAN)
    image   = REFORM(image,[nCells,nCells])

    dlmCharSize     = 0.60
    posit   = DEFINE_PANEL(1,1,0,0,/BAR)
    IF KEYWORD_SET(bandLim) THEN bl$ = 'Band Limit: ' + NUMSTR(bandLim[0]*1000.,2) + ' - ' + NUMSTR(bandLim[1]*1000.,2) + ' mHz' ELSE bl$ = 'Band Limit: Entire FFT Spectrum'
    subtitle= STRUPCASE(radar) + ' ' + FORMAT_DATE(scanDate,/HUMAN) + ' ' + bl$
    PLOT_TITLE,TEXTOIDL('Re(Cross Spectral Density Matrix D_{lm})'),subTitle
    DRAW_IMAGE,image                                                        $
        ,XTITLE     = 'l'                                                   $
        ,YTITLE     = 'm'                                                   $
        ,XSTYLE     = 9                                                     $
        ,YSTYLE     = 9                                                     $
        ,CHARSIZE   = dlmCharSize                                           $
        ,POSITION   = posit                                                 $
        ,/NO_SCALE 

    AXIS,/XAXIS,XRANGE=gateRange,/XSTYLE,CHARSIZE=dlmCharSize,XTITLE='Range Gate'
    AXIS,/YAXIS,YRANGE=gateRange,/YSTYLE,CHARSIZE=dlmCharSize,YTITLE='Range Gate'

    IF scMax LT 0.1 THEN BEGIN
        level_format = '(E12.1)' 
    ENDIF ELSE IF scMax LT 8 THEN BEGIN
        level_format = '(F12.2)' 
    ENDIF ELSE IF N_ELEMENTS(level_format) NE 0 THEN s = TEMPORARY(level_format)

    PLOT_COLORBAR,1,1,0,0,SCALE=dlmScale,/KEEP_FIRST_LAST_LABEL,LEGEND='Re(Spectral Density)',PARAM='velocity',LEVEL_FORMAT=level_format,CHARSIZE=0.75

    max$ = NUMSTR(MAX(data,/NAN),5)
    min$ = NUMSTR(MIN(data,/NAN),5)
    mean$ =NUMSTR(MEAN(data,/NAN),5)
    sd$  = NUMSTR(sd,5)
    var$ = NUMSTR(sd^2,5)
    txt$ = 'Max: ' + max$ + ' Min: ' + min$ + ' Mean: ' + mean$ + TEXTOIDL(' \sigma: ') + sd$ $
         + TEXTOIDL(' \sigma^2: ') + var$
    XYOUTS,0.1,0.03,txt$,CHARSIZE=0.75,/NORMAL

    PS_CLOSE
    PS2PNG,file,ROTATE=270
ENDIF

;Imaginary Part
IF gl GE 3 THEN BEGIN
    file    = DIR('output/kmaps/kspect/dlm_im.ps',/PS)
    CLEAR_PAGE,/NEXT

    data   = IMAGINARY(dlm)
    sd      = STDDEV(data,/NAN)
    mean    = MEAN(data,/NAN)
    scMax   = mean + 2.*sd
    scMin   = mean - 2.*sd
    IF ABS(scMin) GT ABS(scMax) THEN scMax = ABS(scMin)
    dlmScale= scMax*[-1,1.]
    image   = GET_COLOR_INDEX(data,PARAM='velocity',SCALE=dlmScale,/NAN)
    image   = REFORM(image,[nCells,nCells])

    dlmCharSize     = 0.60
    posit   = DEFINE_PANEL(1,1,0,0,/BAR)
    IF KEYWORD_SET(bandLim) THEN bl$ = 'Band Limit: ' + NUMSTR(bandLim[0]*1000.,2) + ' - ' + NUMSTR(bandLim[1]*1000.,2) + ' mHz' ELSE bl$ = 'Band Limit: Entire FFT Spectrum'
    subtitle= STRUPCASE(radar) + ' ' + FORMAT_DATE(scanDate,/HUMAN) + ' ' + bl$
    PLOT_TITLE,TEXTOIDL('Im(Cross Spectral Density Matrix D_{lm})'),subTitle
    DRAW_IMAGE,image                                                        $
        ,XTITLE     = 'l'                                                   $
        ,YTITLE     = 'm'                                                   $
        ,XSTYLE     = 9                                                     $
        ,YSTYLE     = 9                                                     $
        ,CHARSIZE   = dlmCharSize                                           $
        ,POSITION   = posit                                                 $
        ,/NO_SCALE 

    AXIS,/XAXIS,XRANGE=gateRange,/XSTYLE,CHARSIZE=dlmCharSize,XTITLE='Range Gate'
    AXIS,/YAXIS,YRANGE=gateRange,/YSTYLE,CHARSIZE=dlmCharSize,YTITLE='Range Gate'

    IF scMax LT 0.1 THEN BEGIN
        level_format = '(E12.1)' 
    ENDIF ELSE IF scMax LT 8 THEN BEGIN
        level_format = '(F12.2)' 
    ENDIF ELSE s = TEMPORARY(level_format)

    PLOT_COLORBAR,1,1,0,0,SCALE=dlmScale,/KEEP_FIRST_LAST_LABEL,LEGEND='Im(Spectral Density)',PARAM='velocity',LEVEL_FORMAT=level_format,CHARSIZE=0.75

    max$ = NUMSTR(MAX(data,/NAN),5)
    min$ = NUMSTR(MIN(data,/NAN),5)
    mean$ =NUMSTR(MEAN(data,/NAN),5)
    sd$  = NUMSTR(sd,5)
    var$ = NUMSTR(sd^2,5)
    txt$ = 'Max: ' + max$ + ' Min: ' + min$ + ' Mean: ' + mean$ + TEXTOIDL(' \sigma: ') + sd$ $
         + TEXTOIDL(' \sigma^2: ') + var$
    XYOUTS,0.1,0.03,txt$,CHARSIZE=0.75,/NORMAL

    PS_CLOSE
    PS2PNG,file,ROTATE=270
ENDIF


PRINFO,'LA_ELMHES'
;The LA_ELMHES function reduces a real nonsymmetric or complex non-Hermitian array to upper Hessenberg form H. If the array is real then the decomposition is A = Q H QT, where Q is orthogonal. If the array is complex Hermitian then the decomposition is A = Q H QH, where Q is unitary. The superscript T represents the transpose while superscript H represents the Hermitian, or transpose complex conjugate.
H = LA_ELMHES(dlm,q,PERMUTE_RESULT = permute, SCALE_RESULT = scale_result,/double)
PRINFO,'LA_HQR'
evals = LA_HQR(h, q, PERMUTE_RESULT = permute,status=status,/double)
IF COND(dlm) EQ -1 THEN BEGIN
    PRINFO,'Badly conditioned matrix.'
    STOP
ENDIF ELSE IF status NE 0 THEN BEGIN
    PRINFO,'Bad status: '+NUMSTR(status)
    STOP
ENDIF

PRINFO,'Calculating Eigenvectors with LA_EIGENVEC'
evecs = LA_EIGENVEC(H,Q,EIGENINDEX=eigenindex,PERMUTE_RESULT=permute,SCALE_RESULT=scale_result,/double)

;SAVE,filename='eigen.sav'
;RESTORE,'eigen.sav'

dx      = ABS(MAX(lr[0,1:nselbeams-1,*]-lr[0,0:nselBeams-2,*]))
dy      = ABS(MAX(lr[1,*,1:nselgates-1]-lr[1,*,0:nselgates-2]))

IF ~KEYWORD_SET(kx_max) THEN BEGIN
    kx_max  = !PI / dx
ENDIF ELSE IF (kx_max GT !PI / dx) THEN BEGIN
    kx_max  = !PI / dx
ENDIF
    
IF ~KEYWORD_SET(ky_max) THEN BEGIN
    ky_max  = !PI / dy
ENDIF ELSE IF (ky_max GT !PI / dy) THEN BEGIN
    ky_max  = !PI / dy
ENDIF

;IF ~KEYWORD_SET(ky_max) THEN ky_max  = !PI / dy

nkx     = CEIL(2*kx_max/dkx)
IF nkx MOD 2 EQ 0 THEN ++nkx
kx_vec  = kx_max * (2*FINDGEN(nkx)/(nkx-1) - 1)

nky     = CEIL(2*ky_max/dky)
IF nky MOD 2 EQ 0 THEN ++nky
ky_vec  = ky_max * (2*FINDGEN(nky)/(nky-1) - 1)

xm      = REFORM(llInxTable[4,*])       ;x is in the E-W direction.
ym      = REFORM(llInxTable[3,*])       ;y is in the N-S direction.

omega   = 0.
t       = 0.

sigThresh       = 0.15
maxEval = MAX(ABS(eVals))
minEvalsInx     = WHERE(eVals LE sigThresh*maxEval,cnt,NCOMPLEMENT=nSigs)

IF cnt LT 3 THEN BEGIN
    PRINFO,'Not enough small eigenvalues!'
    STOP
ENDIF

i       = COMPLEX(0,1)
kArr    = COMPLEXARR(nkx,nky)


PRINFO,'K-Array: ' + NUMSTR(nkx) + ' x ' + NUMSTR(nky)
PRINT,'Kx Max: ' + NUMSTR(kx_max,4)
PRINT,'Kx Res: ' + NUMSTR(dkx,4)
PRINT,'Ky Max: ' + NUMSTR(ky_max,4)
PRINT,'Ky Res: ' + NUMSTR(dky,4)
PRINT,''
PRINT,'Signal Threshold:      ' + NUMSTR(sigThresh,2)
PRINT,'Number of Det Signals: ' + NUMSTR(nSigs)
PRINT,'Number of Noise Evals: ' + NUMSTR(cnt)

;PRINFO,'Press .c to calculate k-array.'
;STOP
t0      = SYSTIME(1)
FOR kk_kx=0,nkx-1 DO BEGIN
    kx  = kx_vec[kk_kx]
    FOR kk_ky=0,nky-1 DO BEGIN
        ky  = ky_vec[kk_ky]
        resTot  = 0
        FOR ee=0,cnt-1 DO BEGIN
            ec  = minEvalsInx[ee]
            v   = TRANSPOSE(eVecs[*,ec])
            um  = TRANSPOSE(REFORM(EXP(i*(kx*xm + ky*ym - omega*t))))

            res = TRANSPOSE(CONJ(um))##v ## TRANSPOSE(CONJ(v))##um
            resTot +=res
        ENDFOR  ;ee
        kArr[kk_kx,kk_ky] = 1. / resTot
    ENDFOR  ;kk_ky
ENDFOR      ;kk_kx
t1      = SYSTIME(1) - t0

PRINFO,'K-array calculation time: ' + NUMSTR(t1,1) + ' sec'
SAVE,FILENAME='karr.sav'

IF gl GE 1 THEN BEGIN
  IF gl GE 2 THEN png=1 ELSE png=0
    PLOT_KARR,PNG=png
ENDIF

IF KEYWORD_SET(statistics) THEN BEGIN
  SPAWN,'mkdir -p '+savPath
  SAVE,FILENAME=savPath+'/'+savName+'.sav'
  klogFile = savPath+'/'+'karr.txt'
  IF ~FILE_TEST(klogFile) THEN BEGIN
    SPAWN,'tail -n '+ NUMSTR(nmax+4) +' output/kmaps/kspect/karr.txt | head -n 2 >> ' + klogFile
  ENDIF
  SPAWN,'tail -n '+ NUMSTR(nmax+2) +' output/kmaps/kspect/karr.txt | head -n ' + NUMSTR(nmax) +' >> ' + klogFile
ENDIF

END
