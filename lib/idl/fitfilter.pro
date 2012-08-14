PRO FITFILTER

outputPath       = '/data/myfits/'
filter          = 1
ajGround        = 1
ndays           = 2

radarVec        = ['bks', 'cve', 'cvw', 'fhe', 'fhw'            $   
                  ,'gbr', 'han', 'hok', 'inv', 'kap'            $   
                  ,'ksr', 'kod', 'pyk', 'pgr', 'rkn'            $   
                  ,'sas', 'sto', 'wal']
winLen          = 3. * 60. * 60.
startDate       = 20100101
SFJUL,[startDate],[0000,2400],sjul,fjul
julDates        = DINDGEN(nDays) + sjul[0]
 
FOR jk=0,N_ELEMENTS(julDates)-1 DO BEGIN
    SFJUL,_date,_time,julDates[jk],/JUL_TO_DATE
    date            = _date

    FOR rk = 0,N_ELEMENTS(radarVec)-1 DO BEGIN
        radar   = radarVec[rk]

        ;Add in WinLen/2 to each side of the analysis period.
        winLenDay       = winLen / 86400.
        sjulLoad        = sjul - winLenDay /2. 
        fjulLoad        = fjul + winLenDay /2. 
        SFJUL, dateLoad, timeLoad, sjulLoad, fjulLoad,/JUL_TO_DATE

        RAD_FIT_READ,dateLoad,radar                             $
            ,TIME               = timeLoad                      $
            ,FILTER             = filter                        $
            ,AJGROUND           = ajGround                      $
            ,OUTPUTPATH         = outPutPath                    $
            ,/SAVECATFILE
    ENDFOR
ENDFOR

END
