PRO DOYPSD,PNG=png

COMMON RAD_DATA_BLK
COMMON WAVE_BLK

@event

thick           = 4
!P.THICK        = thick
!X.THICK        = thick
!Y.THICK        = thick
!P.CHARTHICK    = thick

;radarVec        = ['gbr']
;startDate       = 20101101

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
    juls        = [julDates[jk], julDates[jk]+1]
    date        = _date

    FOR rk = 0,N_ELEMENTS(radarVec)-1 DO BEGIN
        radar   = radarVec[rk]

        ;OMN_READ,date[0],TIME=time
        ;KPI_READ,date[0],TIME=time
        RAD_WAVE_READ,date,radar                                $
            ,/INTPSD_ONLY                                       $
            ,DIR                        = psdDir                $
            ,PARAM                      = param                 $
            ,FTEST                      = fTest                 $
            ,BANDLIM                    = bandLim  

        psd     = wave_intpsd_data.intpwrrtiarr
        psd     = TOTAL(psd,2)
        psd     = TOTAL(psd,2)

        IF KEYWORD_SET(fTest) THEN BEGIN
            doyPsd      = TOTAL(psd)
        ENDIF ELSE BEGIN
            doyPsd      = !VALUES.F_NAN
        ENDELSE

        IF N_ELEMENTS(doyJulVec) EQ 0 THEN BEGIN
            doyJulVec   = julDates[jk]
            fTestVec    = fTest
            doyPsdVec   = doyPsd
        ENDIF ELSE BEGIN
            doyJulVec   = [doyJulVec, julDates[jk]]
            fTestVec    = [fTestVec, fTest]
            doyPsdVec   = [doyPsdVec, doyPsd]
        ENDELSE
        
        IF KEYWORD_SET(ftest) THEN BEGIN
            IF N_ELEMENTS(julVec) EQ 0 THEN BEGIN
                julVec      = wave_intpsd_data.intpwrrtijulvec
                psdVec      = psd
            ENDIF ELSE BEGIN
                julVec      = [julVec, wave_intpsd_data.intpwrrtijulvec]
                psdVec      = [psdVec, psd]
            ENDELSE
        ENDIF
    ENDFOR
ENDFOR

dir     = 'doypsd/'
fileName= NUMSTR(date[0])+'-'+radar+'.sav'
path    = dir + fileName
SAVE,FILENAME=path,wave_dataproc_info,julVec,psdVec,doyJulVec,doyPsdVec,ftestVec

STOP
;
;        RAD_SET_SCATTERFLAG,scatterFlag
;        SET_COORDINATES,rtiCoords
;
;        bandLim            = wave_dataproc_info.bandLim
;        max_offTime        = wave_dataproc_info.max_offTime
;        min_onTime         = wave_dataproc_info.min_onTime
;        exlude             = wave_dataproc_info.exclude
;        interp             = wave_dataproc_info.interp
;        winLen             = wave_dataproc_info.winLen
;        stepLen            = wave_dataproc_info.stepLen
;
;
;        fbl             = NUMSTR(bandLim*1E6)
;        fileName$       = DIR('output/'                         $
;                        + NUMSTR(date)                          $
;                        + '.' + radar                           $
;                        + '.' + fbl[0]                          $
;                        + '.' + fbl[1]                          $
;                        + '.ps')
;        PRINFO,'Opening ' + fileName$
;        PS_OPEN,fileName$
;
;        xmaps           = 1
;        ymaps           = 3
;        xmap            = 0
;        ymap            = 0
;
;        CLEAR_PAGE,/NEXT
;
;        bl$       = NUMSTR(bandLim*1000.,1)
;        title$    = 'Int. Bandpass Power (' + bl$[0] + ' - ' + bl$[1] + ' mHz)'
;        title$    = RAD_WAVE_PARAM_INFO(BEAM=beam)
;        subtitle$ = 'Int. Bandpass Power (' + bl$[0] + ' - ' + bl$[1] + ' mHz)'         $
;                  + '!CMaxOff: '          + SECSTR(max_offTime)                         $   
;                  + ', MinOn: '         + SECSTR(min_onTime)                            $   
;                  + ', Exclude: ['+ NUMSTR(exclude[0])+', '+NUMSTR(exclude[1])+']'      $   
;                  + '!CIntrp: '         + SECSTR(interp)                                $
;                  + ', Win: '           + SECSTR(winLen)                                $   
;                  + ', WinStep: '    + SECSTR(stepLen)
;
;        yOffSet = 0.09
;        PLOT_TITLE,title$,subtitle$,YOFFSET=yOffSet
;
;        posit           = DEFINE_PANEL(xmaps,ymaps,xmap,ymap,/BAR)
;        dy              = 0.01
;        hhght           = 0.06
;        posit           = [posit[0],posit[3]+dy,posit[2],posit[3]+dy+hhght]
;
;        KPI_PLOT_PANEL                                                          $
;            ,DATE       = date                                                  $
;            ,TIME       = time                                                  $
;            ,CHARSIZE   = 0.8                                                   $
;            ,POSITION   = posit
;
;        posit           = DEFINE_PANEL(xmaps,ymaps,xmap,ymap,/BAR)
;        hhght           = (posit[3] - posit[1]) / 1.9
;        posit[1]        = posit[1] + hhght
;        ;OMN_PLOT_PANEL_IMF,xmaps,ymaps,xmap,ymap                                $
;        OMN_PLOT_PANEL_IMF                                                      $
;            ,DATE               = date                                          $
;            ,TIME               = time                                          $
;            ,POSITION           = posit                                         $
;            ,YRANGE             = [-15.,15.]                                    $
;            ,/YSTYLE                                                            $
;            ,CHARSIZE           = 0.7                                           $
;            ,/BYGSM                                                             $
;            ,/BZGSM                                                             $
;            ,/XSTYLE
;
;        ;LINE_LEGEND,[1.05*posit[2],1.01*posit[1]]                               $
;        ;    ,['Bx GSM','By GSM','Bz GSM']                                       $
;        ;    ,COLOR      = [GET_RED(),GET_BLUE(),GET_BLACK()]                    $
;        ;    ,THICK      = [4,4,4]                                               $
;        ;    ,TITLE      = 'OMNI IMF'                                            $
;        ;    ,CHARSIZE   = 0.8
;
;        LINE_LEGEND,[1.05*posit[2],1.04*posit[1]]                               $
;            ,['By GSM','Bz GSM']                                                $
;            ,COLOR      = [96,GET_BLACK()]                                      $
;            ,TITLE      = 'OMNI IMF'                                            $
;            ,CHARSIZE   = 0.8
;
;        posit           = DEFINE_PANEL(xmaps,ymaps,xmap,ymap,/BAR)
;        hhght           = (posit[3] - posit[1]) / 1.9
;        posit[3]        = posit[3] - hhght
;        OMN_PLOT_PANEL                                                          $
;            ,DATE               = date                                          $
;            ,TIME               = time                                          $
;            ,PARAM              = 'pd'                                          $
;            ,POSITION           = posit                                         $
;            ,CHARSIZE           = 0.8                                           $
;            ,/XSTYLE
;
;        LINE_LEGEND,[1.065*posit[2],1.03*posit[1]]                               $
;            ,['ACE','WIND']                                                     $
;            ,COLOR              = [120, 20]                                     $
;            ,THICK              = 4                                             $
;            ,TITLE              = 'OMNI Source'                                 $
;            ,CHARSIZE           = 0.8
;
;        ++ymap
;        RAD_WAVE_PLOT_INTPSD_RTI_COLORBAR,xmaps,ymaps,xmap,ymap                 $
;            ,BEAM               = beam                                          $   
;            ,SCALE              = intPwrscale                                   $   
;            ,DBSCALE            = dbScale                                       $
;            ,/LINE2
;
;        RAD_WAVE_PLOT_INTPSD_RTI_PANEL,xmaps,ymaps,xmap,ymap                    $
;            ,YRANGE             = rtiYrange                                     $   
;            ,JULS               = juls                                          $   
;            ,BEAM               = beam                                          $   
;            ,EXCLUDE            = exclude                                       $   
;            ,SCALE              = intPwrScale                                   $   
;            ,DBSCALE            = dbScale                                       $   
;            ,VERBOSE            = verbose                                       $   
;;            ,COORDS             = rtiCoords                                     $
;            ,/BAR
;
;
;        ++ymap
;        RAD_WAVE_PLOT_PREFFT_RTI_COLORBAR,xmaps,ymaps,xmap,ymap                 $
;            ,BEAM               = beam                                          $   
;            ,SCALE              = preFFTScale
;
;        RAD_WAVE_PLOT_PREFFT_RTI_PANEL,xmaps,ymaps,xmap,ymap                    $
;            ,YRANGE             = rtiYRange                                     $   
;            ,JULS               = juls                                          $   
;            ,BEAM               = beam                                          $   
;            ,EXCLUDE            = exclude                                       $   
;            ,SCALE              = preFFTScale                                   $   
;;            ,COORDS             = rtiCoords                                     $
;            ,VERBOSE            = verbose                                       $   
;            ,/FIRST,/LAST,/BAR
;    PS_CLOSE
;    IF KEYWORD_SET(png) THEN PS2PNG,fileName$
;    ENDFOR
;ENDFOR

END
