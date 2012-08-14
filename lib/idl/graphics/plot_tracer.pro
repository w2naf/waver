; Plot stuff! ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SET_FORMAT,/PORTRAIT,/SARDINES
CLEAR_PAGE,/NEXT

thick           = 4 
!P.THICK        = thick
!X.THICK        = thick
!Y.THICK        = thick
!P.CHARTHICK    = thick

BEAM_AZM,beam,MAGNAZM=magnAzm,GEOGAZM=geogAzm
gAzm$   = NUMSTR(geogAzm) + TEXTOIDL('^{\circ}')
mAzm$   = NUMSTR(magnAzm) + TEXTOIDL('^{\circ}')

title   = STRUPCASE(radar) + ' ' + NUMSTR(date[0]) + ' Beam:' + NUMSTR(beam)
xtitle  = 'Time [UT] - Beam '+ NUMSTR(beam)                             $
        + ' (Geog. Azm: ' + gAzm$ + ', Magn. Azm: ' + mAzm$ + ')'

posit   = DEFINE_PANEL(1,2,0,0,/BAR)
RAD_FIT_PLOT_RTI_PANEL                                                  $
    ,COORDS             = 'gs_rang'                                     $
    ,yrange             = drange                                        $
    ,DATE               = date                                          $
    ,TIME               = time                                          $
    ,PARAM              = param                                         $
    ,XTITLE             = xtitle                                        $
    ,TITLE              = title                                         $
    ,CHARSIZE           = 0.75                                          $
    ,/LAST                                                              $
    ,POSITION           = posit

OP_LINES,date,time,UT0,rn0,UT1,rn1
PLOT_COLORBAR,CHARSIZE=0.75,PANEL_POSITION=posit


IF ~KEYWORD_SET(evalMode) THEN BEGIN
    posit   = DEFINE_PANEL(1,2,0,1,/BAR,/WITH_INFO)
    RAD_FIT_PLOT_RTI_PANEL                                                  $
        ,COORDS             = 'gs_rang'                                     $
        ,yrange             = zoom_range                                    $
        ,DATE               = zoom_date                                     $
        ,TIME               = zoom_time                                     $
        ,PARAM              = param                                         $
        ,XTITLE             = xtitle                                        $
        ,CHARSIZE           = 0.75                                          $
        ,/LAST                                                              $
        ,POSITION           = posit

    OP_LINES,date,time,UT0,rn0,UT1,rn1
    PLOT_COLORBAR,CHARSIZE=0.75,PANEL_POSITION=posit
ENDIF
