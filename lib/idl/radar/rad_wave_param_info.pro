FUNCTION RAD_WAVE_PARAM_INFO,BEAM=beam

COMMON wave_blk

param = wave_dataproc_info.param
fitstr = 'N/A'

IF wave_dataproc_info.fitex     THEN fitstr     = 'fitEX'
IF wave_dataproc_info.fitacf    THEN fitstr     = 'fitACF'
IF wave_dataproc_info.fit       THEN fitstr     = 'fit'
IF wave_dataproc_info.filtered  THEN filterstr  = 'filt. ' ELSE filterstr = ''
IF N_ELEMENTS(beam) NE 0        THEN _beam = ' Bm ' + NUMSTR(beam) ELSE _beam = ''

info    = STRUPCASE(wave_dataproc_info.radar)           $
        + _beam                                         $
        +': '+param+' ('+filterstr+fitstr+')'

RETURN,info
END
