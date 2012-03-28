PRO RTIALL                                              $
    ,FILTER             = _filter                        $
    ,DATE               = _date                          $
    ,TIME               = _time                          $
    ,RADARVEC           = _radarVec                      $
    ,BEAMOFINT          = _beamOfInt                     $
    ,GSCATTER           = _gscatter                      $
    ,RTIPWRSCALE        = _rtiPwrScale                   $
    ,RTIVELSCALE        = _rtiVelScale

COMMON rad_data_blk

filter          = _filter
date            = _date
time            = _time
radarVec        = _radarVec
beamOfInt       = _beamOfInt
gscatter        = _gscatter
rtiPwrScale     = _rtiPwrScale
rtiVelScale     = _rtiVelScale

SET_FORMAT,/LANDSCAPE,/SARDINES
fileName$       = DIR('output/rti.ps',/PS)

FOR rk=0,N_ELEMENTS(radarVec) - 1 DO BEGIN
    radar       = radarVec[rk]
    RAD_FIT_READ,date,radar,FILTER=filter
    IF (*rad_fit_info[RAD_FIT_GET_DATA_INDEX()]).nrecs EQ 0L THEN CONTINUE
    RAD_SET_SCATTERFLAG,gscatter
    RAD_FIT_PLOT_RTI                                                            $
        ,PARAM                  = ['power', 'velocity']                         $
        ,COORDS                 = coords                                        $
        ,BEAMS                  = beamOfInt[rk]                                 $
        ,DATE                   = date                                          $
        ,TIME                   = time                                          $
        ,NAME                   = radar                                         $
        ,SCALE                  = [rtiPwrScale, rtiVelScale]                    $
        ,CHARTHICK              = 2
ENDFOR
END
