PRO WAVE_BLK,return0
COMMON WAVE_BLK                                                         $
    ,WAVE_dataproc_info                                                 $
    ,WAVE_offTimes                                                      $
    ,WAVE_onTimes                                                       $
    ,WAVE_int_pwr_rti                                                   $
    ,wave_dynfft                                                        $
    ,WAVE_rawtsr_data                                                   $
    ,wave_dynfft_data                                                   $
    ,WAVE_intpsd_data

;wave_dynfft stores the Dynamic FFT data for a single beam.
;wave_dynfft_data stores the Dynamic FFT data for a all of the beams in a radar.  This is what gets saved to the psdsav file.

;WAVE_preFFTRTI --> Holds the Pre-FFT RTI plot.  Everything except the final
;Hanning windowing has been performed on this data.  This includes:
;    1. NaNing of bad values.
;    2. Determination of on and off times.
;    2.5 Interpolation of Data
;    3. NaNing of off times.
;    4. Average subtraction of good periods.
;    5. Hanning windowing of good periods.

;WAVE_preFFTRTI_julVec --> Julian times for interpolated WAVE_preFFTRTI values.


wave_dataproc_info      = {                                     $
     DATE               : LONARR(2)                             $   
    ,TIME               : INTARR(2)                             $   
    ,LONG               : 0B                                    $   
    ,JULS               : FLTARR(2)                             $   
    ,RADAR              : ''                                    $   
    ,NAME               : ''                                    $   
    ,ID                 : 0                                     $
    ,NBEAMS             : 0                                     $
    ,NGATES             : 0                                     $
    ,GLAT               : 0D                                    $
    ,GLON               : 0D                                    $
    ,MLAT               : 0D                                    $
    ,MLON               : 0D                                    $
    ,PARAM              : ''                                    $   
    ,FILTERED           : 0B                                    $   
    ,AJGROUND           : 0B                                    $   
    ,SCATTERCAT         : -1                                    $
    ,SCATTERFLAG        : 0                                     $   
    ,WINLEN             : 0.                                    $   
    ,STEPLEN            : 0.                                    $   
    ,BANDLIM            : FLTARR(2)                             $   
    ,max_offTime        : 0.                                    $   
    ,MEDIAN             : 0                                     $   
    ,INTERP             : 0.                                    $   
    ,DETREND            : 0                                     $   
    ,NO_HANNING         : 0B                                    $   
    ,MIN_ONTIME         : 0.                                    $   
    ,BADVAL             : 0.                                    $   
    ,EXCLUDE            : FLTARR(2)                             $
    ,SCALE              : FLTARR(2)                             $
    ,DBSCALE            : 0B                                    $   
    ,PCTPWRTHRESH       : 0.                                    $   
    ,FNDPWRTHRESH       : 0.                                    $   
    ,VERBOSE            : 0B                                    $
    ,FITEX              : 0B                                    $
    ,FITACF             : 0B                                    $
    ,FIT                : 0B                                    $
    }

return0 = wave_dataproc_info

END
