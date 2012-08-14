PRO BRISTOMETER
COMMON WAVE_BLK

!X.CHARSIZE    = 2
!Y.CHARSIZE    = 2

@event
RAD_WAVE_READ,date,radar                                $   
    ,DIR                        = psdDir                $   
    ,PARAM                      = param                 $   
    ,BANDLIM                    = bandLim  

;Calculate radar-wide average of magnitude of spectrum
dims    = SIZE(wave_dynfft_data.fft,/DIMENSIONS)
nCells  = dims[2] * dims[3]

rngAvg  = TOTAL(wave_dynfft_data.fft,4)
fftAvg  = TOTAL(rngAvg,3) / nCells


;Plot average spectrum
CLEAR_PAGE
timeInx = 90
title   = 'Average Spectrum of '                        $
        + STRUPCASE(wave_dataproc_info.radar)           $
        + ' ' + wave_dataproc_info.param
subTitle= SECSTR(wave_dataproc_info.winlen)             $
        + ' Window Cenetered at '                       $
        + JUL2STRING(wave_dynfft_data.juls[timeInx])

posit   = DEFINE_PANEL(1,1,0,0)
PLOT_TITLE,title,subTitle
PLOT,wave_dynfft_data.freq*1000.,fftavg[timeInx,*]      $
    ,XTITLE     = 'Frequency [mHz]'                     $
    ,YTITLE     = 'ABS(FFT(Backscatter Power))'         $
    ,POSITION   = posit


STOP
END
