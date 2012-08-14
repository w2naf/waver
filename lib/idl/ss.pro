PRO SS
;SigdetStart (ss).pro

COMMON WAVE_BLK

;PRINFO,'WAIT!!! Do you really want to run this routine???'
;STOP

;Load in event file.
@event.pro

catFile = 1
catPath = 'fitdata/'

startTime       = SYSTIME(/SECONDS)

IF KEYWORD_SET(radar) AND ~KEYWORD_SET(radarVec) THEN radarVec = radar

IF ~KEYWORD_SET(radarVec)       THEN                            $
    radarVec    = ['bks', 'cve', 'cvw', 'fhe', 'fhw'            $
                  ,'gbr', 'han', 'hok', 'inv', 'kap'            $
                  ,'ksr', 'kod', 'pyk', 'pgr', 'rkn'            $
                  ,'sas', 'sto', 'wal']

IF ~KEYWORD_SET(startDate)      THEN startDate = date
IF ~KEYWORD_SET(nDays)          THEN nDays = 1
SFJUL,[startDate],[0000,2400],sjul,fjul
julDates        = DINDGEN(nDays) + sjul[0]

FOR jk=0,N_ELEMENTS(julDates)-1 DO BEGIN
    SFJUL,_date,_time,julDates[jk],/JUL_TO_DATE
    date            = _date

    FOR rk = 0,N_ELEMENTS(radarVec)-1 DO BEGIN
        radar   = radarVec[rk]
        WAVE_PROC                                                           $
            ,DATE                   = date                                  $   
            ,TIME                   = time                                  $   
            ,RADAR                  = radar                                 $   
            ,PARAM                  = param                                 $   
            ,FILTER                 = filter                                $
            ,AJGROUND               = ajground                              $
            ,WINLEN                 = winLen                                $   
            ,STEPLEN                = stepLen                               $   
            ,BANDLIM                = bandLim                               $   
            ,max_offTime            = max_offTime                           $   
            ,INTERP                 = interp                                $   
            ,DETREND                = detrend                               $   
            ,NO_HANNING             = no_hanning                            $   
            ,MIN_ONTIME             = min_onTime                            $   
            ,EXCLUDE                = exclude                               $
            ,SCALE                  = scale                                 $
            ,PCTPWRTHRESH           = pctPwrThresh                          $
            ,FNDPWRTHRESH           = fndPwrThresh                          $
            ,SCATTERFLAG            = scatterFlag                           $
            ,CATFILE                = catFile                               $
            ,CATPATH                = catPath                               $
            ,/VERBOSE
    
    ENDFOR
ENDFOR

stopTime        = SYSTIME(/SECONDS)
duration        = stopTime - startTime
PRINT,'Total search time: ' + SECSTR(duration)
nRadars         = 25.
nBeams          = 16.
PRINT,'Total network search time for 1 day: '+SECSTR(duration*nRadars*nBeams)
STOP
END
