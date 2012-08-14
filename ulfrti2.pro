PRO ULFRTI2,PNG=png

COMMON RAD_DATA_BLK
COMMON WAVE_BLK

@event

;radarVec        = ['gbr']
;startDate       = 20101101
;nDays           = 366

thick           = 4
!P.THICK        = thick
!X.THICK        = thick
!Y.THICK        = thick
!P.CHARTHICK    = thick

IF ~KEYWORD_SET(radarVec)       THEN                            $   
    radarVec    = ['bks', 'cve', 'cvw', 'fhe', 'fhw'            $   
                  ,'gbr', 'han', 'hok', 'inv', 'kap'            $   
                  ,'ksr', 'kod', 'pyk', 'pgr', 'rkn'            $   
                  ,'sas', 'sto', 'wal']

IF ~KEYWORD_SET(startDate)      THEN startDate = date
IF ~KEYWORD_SET(nDays)          THEN nDays = 1 

IF N_ELEMENTS(time) LT 2 THEN time = [0000,2400]
SFJUL,[startDate,startDate],time,sjul,fjul
julDates        = DINDGEN(nDays) + sjul[0]
julDates1       = DINDGEN(nDays) + fJul[0]

FOR jk=0,N_ELEMENTS(julDates)-1 DO BEGIN
    SFJUL,_date,_time,julDates[jk],/JUL_TO_DATE
    juls        = [julDates[jk], julDates1[jk]]
    date        = _date

SET_FORMAT,/PORTRAIT,/SARDINES
    FOR rk = 0,N_ELEMENTS(radarVec)-1 DO BEGIN
        radar   = radarVec[rk]

;        OMN_READ,date[0],TIME=time
;        KPI_READ,date[0],TIME=time
        RAD_WAVE_READ,date,radar                                $
            ,/INTPSD_ONLY                                       $
            ,DIR                        = psdDir                $
            ,PARAM                      = param                 $
            ,BANDLIM                    = bandLim  

        RAD_SET_SCATTERFLAG,scatterFlag
        SET_COORDINATES,rtiCoords

        bandLim            = wave_dataproc_info.bandLim
        max_offTime        = wave_dataproc_info.max_offTime
        min_onTime         = wave_dataproc_info.min_onTime
        exlude             = wave_dataproc_info.exclude
        interp             = wave_dataproc_info.interp
        winLen             = wave_dataproc_info.winLen
        stepLen            = wave_dataproc_info.stepLen


        fbl             = NUMSTR(bandLim*1E6)
        dir$            = 'output/ulfsw/'
        SPAWN,'mkdir -p ' + dir$
        fileName$       = DIR(dir$                              $
                        + NUMSTR(date)                          $
                        + '.' + radar                           $
                        + '.' + fbl[0]                          $
                        + '.' + fbl[1]                          $
                        + '.ps')
        PRINFO,'Opening ' + fileName$
        PS_OPEN,fileName$

        xmaps           = 1
        ymaps           = 3
        xmap            = 0
        ymap            = 0

        CLEAR_PAGE,/NEXT

        bl$       = NUMSTR(bandLim*1000.,1)
        title$    = 'Int. Bandpass Power (' + bl$[0] + ' - ' + bl$[1] + ' mHz)'
        title$    = RAD_WAVE_PARAM_INFO(BEAM=beam)
        subtitle$ = 'Int. Bandpass Power (' + bl$[0] + ' - ' + bl$[1] + ' mHz)'         $
                  + '!CMaxOff: '          + SECSTR(max_offTime)                         $   
                  + ', MinOn: '         + SECSTR(min_onTime)                            $   
                  + ', Exclude: ['+ NUMSTR(exclude[0])+', '+NUMSTR(exclude[1])+']'      $   
                  + '!CIntrp: '         + SECSTR(interp)                                $
                  + ', Win: '           + SECSTR(winLen)                                $   
                  + ', WinStep: '    + SECSTR(stepLen)

        yOffSet = 0.09
        PLOT_TITLE,title$,subtitle$,YOFFSET=yOffSet

        RAD_FIT_READ,date,radar,TIME=time,FILTER=filter

        posit           = DEFINE_PANEL(xmaps,ymaps,xmap,ymap,/BAR)
        rad_fit_plot_scan_id_info_panel, xmaps, ymaps, xmap, ymap $
          ,bar        = 1                       $
          ,date       = date                    $
          ,time       = time                    $
          ,beam       = beam                    $
          ,channel    = channel                 $
          ,PANEL_POSITION = posit               $
          ,/with_info                           $
          ,/legend

        charSize        = 0.8

        ydt     = GET_DEFAULT_TITLE(GET_COORDINATES())
        ytitle  = 'Original Data!C' + ydt

        RAD_WAVE_PLOT_PREFFT_RTI_COLORBAR,xmaps,ymaps,xmap,ymap                 $
            ,BEAM               = beam                                          $   
            ,JULS               = juls                                          $
            ,SCALE              = preFFTScale

        RAD_FIT_PLOT_RTI_PANEL,xmaps,ymaps,xmap,ymap                            $
            ,CHARSIZE           = charSize                                      $
            ,YTITLE             = yTitle                                        $
            ,YRANGE             = rtiYRange                                     $   
            ,TIME               = time                                          $
            ,BEAM               = beam                                          $   
            ,SCALE              = preFFTScale                                   $   
            ,/FIRST,/BAR

        ++ymap
        RAD_WAVE_PLOT_PREFFT_RTI_COLORBAR,xmaps,ymaps,xmap,ymap                 $
            ,BEAM               = beam                                          $   
            ,JULS               = juls                                          $
            ,SCALE              = preFFTScale

        ytitle  = 'PreFFT Data!C' + ydt
        RAD_WAVE_PLOT_PREFFT_RTI_PANEL,xmaps,ymaps,xmap,ymap                    $
            ,CHARSIZE           = charSize                                      $
            ,YRANGE             = rtiYRange                                     $   
            ,YTITLE             = yTitle                                        $
            ,JULS               = juls                                          $   
            ,BEAM               = beam                                          $   
            ,EXCLUDE            = exclude                                       $   
            ,SCALE              = preFFTScale                                   $   
            ,VERBOSE            = verbose                                       $   
            ,/FIRST,/BAR

        ++ymap
        RAD_WAVE_PLOT_INTPSD_RTI_COLORBAR,xmaps,ymaps,xmap,ymap                 $
            ,BEAM               = beam                                          $   
            ,SCALE              = intPwrscale                                   $   
            ,DBSCALE            = dbScale                                       $
            ,/LINE2

        ytitle  = 'Integrated PSD!C' + ydt
        RAD_WAVE_PLOT_INTPSD_RTI_PANEL,xmaps,ymaps,xmap,ymap                    $
            ,CHARSIZE           = charSize                                      $
            ,YRANGE             = rtiYrange                                     $   
            ,YTITLE             = yTitle                                        $
            ,JULS               = juls                                          $   
            ,BEAM               = beam                                          $   
            ,EXCLUDE            = exclude                                       $   
            ,SCALE              = intPwrScale                                   $   
            ,DBSCALE            = dbScale                                       $   
            ,VERBOSE            = verbose                                       $   
            ,/LAST                                                              $ 
            ,/BAR
        
    PS_CLOSE
    IF KEYWORD_SET(png) THEN PS2PNG,fileName$
    ENDFOR
ENDFOR

STOP
END
