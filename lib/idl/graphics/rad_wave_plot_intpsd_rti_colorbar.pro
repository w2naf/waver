PRO RAD_WAVE_PLOT_INTPSD_RTI_COLORBAR,xmaps,ymaps,xmap,ymap     $
    ,BEAM               = beam                                  $   
    ,SCALE              = scale                                 $   
    ,DBSCALE            = dbScale                               $
    ,LINE2              = line2

COMMON WAVE_BLK

IF ~KEYWORD_SET(beam)           THEN BEAM               = 0 
IF ~KEYWORD_SET(param)          THEN PARAM              = wave_dataproc_info.param
IF  N_ELEMENTS(dbScale) EQ 0    THEN DBSCALE            = wave_dataproc_info.dbScale


waveRTI         = TRANSPOSE(REFORM(wave_intpsd_data.intPwrRtiArr[*,beam,*]))

IF KEYWORD_SET(dbScale) THEN BEGIN
    waveRTI         =   10 * ALOG10(waveRTI)
    IF ~KEYWORD_SET(scale) THEN scale = [-35.,0.]
ENDIF ELSE BEGIN
    IF ~KEYWORD_SET(scale) THEN scale = [MIN(waveRTI,/NAN),MAX(waveRTI,/NAN)]
ENDELSE

IF param EQ 'velocity' || param EQ 'width' THEN BEGIN
    unit$   = TEXTOIDL(' [(m s^{-1})^2]')
    intUnit$= TEXTOIDL(' [(m s^{-1})^2 Hz]')
ENDIF   
IF param EQ 'power' THEN BEGIN
    unit$   = TEXTOIDL(' [(dB)^2]')
    intUnit$= TEXTOIDL(' [(dB)^2 Hz]')
ENDIF

IF ~KEYWORD_SET(dbScale) THEN BEGIN
    cbLegend            = '!C'+TEXTOIDL('10^6 \cdot') + intUnit$
    cbScale             = scale * 1E6
ENDIF ELSE BEGIN
    cbLegend            = '!C'+TEXTOIDL('10 log_{10}') + intUnit$ 
    cbScale             = scale
ENDELSE

bandLim = wave_dataproc_info.bandLim
bl$     = NUMSTR(bandLim*1000.,1)
IF KEYWORD_SET(line2) THEN cbLegend += '!C!CInt. BP Power (' + bl$[0] + ' - ' + bl$[1] + ' mHz)'

PLOT_COLORBAR,xmaps,ymaps,xmap,ymap                                     $
        ,LEGEND         = cbLegend                                      $
        ,SCALE          = cbScale                                       $
        ,/KEEP_FIRST_LAST_LABEL                                         $
        ,/CONTINUOUS                                                    $
        ,/NO_ROTATE
END
