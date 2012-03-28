PRO RAD_WAVE_PLOT_PREFFT_RTI_COLORBAR,xmaps,ymaps,xmap,ymap     $
    ,BEAM               = beam                                  $   
    ,SCALE              = scale

COMMON WAVE_BLK

IF N_PARAMS() NE 4 THEN BEGIN
    xmaps       = 1
    ymaps       = 1
    xmap        = 0
    ymap        =0
ENDIF

IF ~KEYWORD_SET(beam)           THEN BEAM               = 0 
IF ~KEYWORD_SET(param)          THEN PARAM              = wave_dataproc_info.param

preFFTRTI       = TRANSPOSE(REFORM(wave_intpsd_data.preFFTRTIArr[*,beam,*]))

absMin  = ABS(MIN(preFFTRTI,/NAN))
absMax  = ABS(MAX(preFFTRTI,/NAN))

IF absMin GE absMax THEN zr = absMin ELSE zr = absMax
zRange = 0.80 * [-zr,zr]

legend  = GET_DEFAULT_TITLE(param)

PLOT_COLORBAR,xmaps,ymaps,xmap,ymap                     $
        ,SCALE          = zRange                        $
        ,PARAMETER      = 'velocity'                    $
        ,LEGEND         = legend                        $
        ,/KEEP_FIRST_LAST_LABEL                         $
        ,/ROTATE
END
