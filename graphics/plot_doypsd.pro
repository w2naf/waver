PRO PLOT_DOYPSD

thick           = 4
!P.CHARTHICK    = thick
!P.THICK        = thick
!X.THICK        = thick
!Y.THICK        = thick
!P.CHARSIZE     = 0.6

date    = [20101101,20111101]
time    = [0000,0000]
SFJUL,date,time,sjul,fjul
xRange  = [sjul,fjul]

dir$    = 'output/statistics/'
fName   = 'doypsd.ps'
path    = dir$ + fName

SPAWN,'mkdir -p ' + dir$
SET_FORMAT,/LANDSCAPE,/SARDINES

res     = DIR(path,/PS)
title   = 'MSTID Statistics'
sTitle  = 'For Nov 2010 - Nov 2011, Using INTPSD Method'
PLOT_TITLE,title,sTitle

savDir  = 'doypsd/'
fileVec = ['20111101-gbr.sav']

nf      = N_ELEMENTS(fileVec)
s       = LABEL_DATE(DATE_FORMAT='%M%Z')
posit   = DEFINE_PANEL(4,2,0,0)
FOR kk=0,7 DO BEGIN
    IF (kk+1) GT nf THEN ff = nf-1 ELSE ff = kk
    RESTORE,savDir+fileVec[ff]
    
    GET_RECENT_PANEL,xmaps,ymaps,xmap,ymap

;    xTitle      = ''
;    xTickName   = REPLICATE(' ',10)
;    IF kk GE 6 THEN BEGIN
;        xTitle      = 'Time [UT]'
;        s           = TEMPORARY(xTickName)
    s = LABEL_DATE(DATE_FORMAT='%M')
        xTickFormat = 'LABEL_DATE'
;    ENDIF
    IF xmap EQ 0 THEN yTitle = 'IntPSD' ELSE yTitle =''
    IF ymap EQ 1 THEN posit = DEFINE_PANEL(xmaps,ymaps,xmap,ymap,/WITH_INFO)

    xVals       = doyJulVec
    yVals       = doyPsdVec

   yryrsec  = JUL2YRYRSEC(xVals)
   newJul = CALC_JUL(20100101,0000) + yrYrsec[1,*]/86400.
   srt    = SORT(newJul)
   xVals  = newJul[srt]
   yVals  = yVals[srt]
   ftestVec = ftestVec[srt]
  
    PLOT,xVals,yVals                                    $
        ,XTITLE         = xTitle                        $
;        ,XRANGE         = xRange                        $
        ,XTICKS         = 6                             $
        ,YTITLE         = yTitle                        $
        ,/XSTYLE                                        $
        ,/YSTYLE                                        $
        ,XTICKNAME      = xTickName                     $
        ,XTICKFORMAT    = xTickFormat                   $
        ,POSITION       = posit


    nP          = N_ELEMENTS(fTestVec)
    clrArr      = INTARR(nP)
    green       = WHERE(fTestVec,nGreen,COMPLEMENT=red,NCOMPLEMENT=nRed)
    IF nGreen GT 0 THEN clrArr[green] = GET_GREEN()
    IF nRed   GT 0 THEN clrArr[red]   = GET_RED()

    yVec        = FLTARR(np) + !Y.CRANGE[0]
    PLOTS,xVals,yVec,COLOR=clrArr,/DATA

    str$ = STRUPCASE(wave_dataproc_info.radar) + ' All Cells'           $
         + '!C(' + NUMSTR(wave_dataproc_info.bandlim[0]*1000,1)   $
         + ' - '       + NUMSTR(wave_dataproc_info.bandlim[1]*1000,1)   $
         + ' mHz)'

    xnrm        = 0.05
    ynrm        = 0.9

    xpos        = xnrm*(!X.CRANGE[1] - !X.CRANGE[0]) + !X.CRANGE[0]
    ypos        = ynrm*(!Y.CRANGE[1] - !Y.CRANGE[0]) + !Y.CRANGE[0]
    XYOUTS,xpos,ypos,str$
    posit   = DEFINE_PANEL(/NEXT)
ENDFOR

PS_CLOSE
STOP
END
