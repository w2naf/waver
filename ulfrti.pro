PRO ULFRTI

COMMON RAD_DATA_BLK
COMMON WAVE_BLK

@event
RAD_WAVE_READ,date,radar                                                                $   
    ,PARAM                      = param                                                 $   
    ,BANDLIM                    = bandLim  

RAD_SET_SCATTERFLAG,scatterFlag
SET_COORDINATES,rtiCoords

date            = wave_dataproc_info.date
time            = wave_dataproc_info.time
scale           = wave_dataproc_info.scale
param           = wave_dataproc_info.param
exclude         = wave_dataproc_info.exclude
radar           = wave_dataproc_info.radar
filter          = wave_dataproc_info.filtered

;roiJulGateArr   = PSD_ID(intPwrRTIStruct                                        $
;                    ,PCTPWRTHRESH               = pctPwrThresh                  $
;                    ,FNDPWRTHRESH               = fndPwrThresh)

fileName$       = DIR('output/gateplot.ps')
PS_OPEN,fileName$
GATEPLOT,WINDOWDATE=windowDate,WINDOWTIME=windowTime,BEAM=beam
PS_CLOSE

;fileName$       = DIR('output/daygate.ps')
;PS_OPEN,fileName$
;GATEPLOT_DAY,BEAM=beam,YRANGE=yrange
;PS_CLOSE
;
;fileName$       = DIR('output/intpwr.ps')
;PS_OPEN,fileName$
;RAD_WAVE_PLOT_INTPSD_RTI,BEAM=beam,DBSCALE=dbScale,YRANGE=rtiYRange
;PS_CLOSE
;PS2PNG,fileName$
;
;fileName$       = DIR('output/preFFTrti.ps')
;PS_OPEN,fileName$
;RAD_WAVE_PLOT_PREFFT_RTI,BEAM=beam,YRANGE=rtiYRange
;PS_CLOSE
;PS2PNG,fileName$
;
;;RAD_SET_SCATTERFLAG,3
;IF KEYWORD_SET(pwrScale) AND KEYWORD_SET(velScale) THEN rtiScale = [pwrScale, velScale]
;RAD_FIT_READ,date,radar,TIME=time,AJGROUND=ajGround
;fileName$       = DIR('output/rtiplot.ps')
;PS_OPEN,fileName$
;RAD_FIT_PLOT_RTI                                        $
;    ,DATE       = date                                  $
;    ,TIME       = time                                  $
;    ,PARAM      = ['power','velocity']                  $
;    ,EXCLUDE    = exclude                               $
;    ,SCALE      = rtiScale                              $
;    ,BEAMS      = beam
;PS_CLOSE
;PS2PNG,fileName$

;PS2PNG,fileName$
;@dbinsert
STOP
END
