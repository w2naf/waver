PRO RAD_WAVE_PLOT_PREFFT_RTI_COLORBAR,xmaps,ymaps,xmap,ymap     $
    ,BEAM               = beam                                  $   
    ,JULS               = juls                                  $
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


IF ~KEYWORD_SET(scale) THEN BEGIN
    IF N_ELEMENTS(juls) EQ 2 THEN BEGIN
        good        = WHERE(wave_intpsd_data.preFFTRTIJULVEC GE juls[0] AND wave_intpsd_data.preFFTRTIJULVEC LE juls[1],cnt)
        IF cnt NE 0 THEN preFFTRTI       = TRANSPOSE(REFORM(wave_intpsd_data.preFFTRTIArr[good,beam,*]))
    ENDIF 

    IF N_ELEMENTS(preFFTRTI) EQ 0 THEN preFFTRTI       = TRANSPOSE(REFORM(wave_intpsd_data.preFFTRTIArr[*,beam,*]))

    absMin  = ABS(MIN(preFFTRTI,/NAN))
    absMax  = ABS(MAX(preFFTRTI,/NAN))

    IF absMin GE absMax THEN zr = absMin ELSE zr = absMax
    scale = 0.80 * [-zr,zr]
ENDIF

legend  = GET_DEFAULT_TITLE(param)

PLOT_COLORBAR,xmaps,ymaps,xmap,ymap                     $
        ,SCALE          = scale                         $
        ,PARAMETER      = 'velocity'                    $
        ,LEGEND         = legend
;        ,/KEEP_FIRST_LAST_LABEL
END
