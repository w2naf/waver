PRO LOAD_MUSIC_EVENTS,datFile,N_EVENTS=n_events,INX=inx
COMMON MUSIC_PARAMS
COMMON LOAD_MUSIC_EVENTS_BLK

;Load all events into array.
IF N_ELEMENTS(eventArr) EQ 0 THEN BEGIN
    nLines  = FILE_LINES(datFile)
    OPENR,unit,datFile,/GET_LUN
    inArr   = STRARR(nLines)
    READF,unit,inArr
    FREE_LUN,unit

    linesData       = WHERE(~STRCMP(inArr,'#',1)                $
                        AND ~STRCMP(inArr,'$',1)                $
                        AND ~STRCMP(inArr,'>',1)                $
                        ,cnt)

    IF cnt EQ 0 THEN BEGIN
        PRINT,'No data in file.  Sorry.'
        STOP
    END

    ;Execute special commands (such as global parameters).
    cmdLines    = WHERE(STRCMP(inArr,'>',1),cmdCnt)
    FOR cc=0,cmdCnt-1 DO BEGIN
        cmdInx  = cmdLines[cc]
        cmd$    = inArr[cmdInx]
        cmd$    = STRTRIM(STRMID(cmd$,1),2)
        s       = EXECUTE(cmd$)
    ENDFOR

    ;Load in variable names.
    varDesc     = WHERE(STRCMP(inArr,'$',1),varCnt)
    varNames$   = STRTRIM(STRMID(inArr[varDesc[0]],1),2)
    varNames    = STRTRIM(STRSPLIT(varNames$,' ',/EXTRACT),2)
    nVars       = N_ELEMENTS(varNames)

    ;Put event parameters into array.
    inArr       = inArr[linesData]
    eventArr$   = STRARR(cnt)
    eventArr    = STRARR(nVars,cnt)
    FOR kk=0,cnt-1 DO BEGIN
        inVec$  = STRTRIM(inArr[kk],2)
        inVec   = STRSPLIT(inVec$,' ',/EXTRACT,COUNT=evNVars)
        IF evNVars EQ nVars THEN BEGIN
            eventArr$[kk]       = inVec$
            eventArr[*,kk]      = inVec 
            IF N_ELEMENTS(good) EQ 0 THEN good = kk ELSE good = [good, kk]
        ENDIF
    ENDFOR
    eventArr$   = eventArr$[good]
    eventArr    = eventArr[*,good]
    n_events    = N_ELEMENTS(good)
ENDIF   ;eventArr

IF N_ELEMENTS(inx) NE 0 THEN BEGIN
    event$      = eventArr$[inx]
    event       = "'" + eventArr[*,inx] + "'"

    ;Separate event parameters into variables.
    nVars       = N_ELEMENTS(varNames)
    FOR vv=0,nVars-1 DO BEGIN
        s   = EXECUTE(varNames[vv] + '=' + event[vv])
    ENDFOR

    radar           = radar
    date            = LONG([date0, date1])
    time            = FIX([time0,time1])
    bandLim         = FLOAT([band0, band1])/1000.         ; In Hz
    dRange          = FLOAT([drange0, drange1])     ; In km
    mapXRange       = FLOAT([mapx0, mapx1])
    mapYRange       = FLOAT([mapy0, mapy1])
    lrdMapXRange    = FLOAT([moovX0, moovX1])
    lrdMapYRange    = FLOAT([moovY0, moovY1])
    lrdRotate       = FLOAT(moovRot)
    movieXrange     = lrdMapXRange
    movieYrange     = lrdMapYRange
    movieRotate     = lrdRotate
    frange          = FLOAT([fft0, fft1])/1000.   ; In Hz - Controls Full Spect Display
    fftXMax         = frange[1] * 1000.     ; In mHz - for visualization only
    kx_max          = FLOAT(kmax)
    ky_max          = FLOAT(kmax)
    foi             = FLOAT(STRSPLIT(foi,',',/EXTRACT))/1000.
    fir_date        = LONG([fir_date0, fir_date1])
    fir_time        = FIX([fir_time0, fir_time1])
    fir_scale       = FLOAT([fir_scale0,fir_scale1])
    RAD_SET_BEAM,FIX(beam)
ENDIF
END

PRO APPEND_RUN_ID,file
COMMON MUSIC_PARAMS
OPENW,1,file,/APPEND
PRINTF,1,''
PRINTF,1,'# Run ID: ' + run_id
CLOSE,1
END

;###############################################################################
PRO RUN_MUSIC
COMMON MUSIC_PARAMS     ;Defined in io/music_blk.pro

datFile = 'music_events.txt'
LOAD_MUSIC_EVENTS,datFile,N_EVENTS=n_events

runJul  = SYSTIME(/JUL)
SFJUL,runDate,runTime,runJul,/JUL_TO_DATE
run_id  = STRING(runDate[0],FORMAT='(I08)') + '.' + STRING(runTime[0],FORMAT='(I04)')

SPAWN,'rm -Rf output/current_run'
SPAWN,'mkdir -p output/current_run'
OPENW,1,'output/current_run/.run_id'
PRINTF,1,run_id
CLOSE,1

FOR ee=0,n_events-1 DO BEGIN
    LOAD_MUSIC_EVENTS,datFile,INX=ee

    SPAWN,'rm -Rf output/kmaps'
    SPAWN,'mkdir -p output/kmaps'
    SPAWN,'cp '+datFile+' output/kmaps/'
    APPEND_RUN_ID,'output/kmaps/'+datfile

    GSPOS
;    KSPECT2
    IF KEYWORD_SET(fir_filter) and N_ELEMENTS(fir_date) EQ 2 THEN BEGIN
      dirName = NUMSTR(fir_date[0])                               $
              + '.' + STRING(fir_time[0],FORMAT='(I04)')          $
              + '-' + STRING(fir_time[1],FORMAT='(I04)')          $
              + 'UT'                                              $
              + '.FIR_' + STRING(bandLim[0]*10000,FORMAT='(I04)') $
              + '-' + STRING(bandLim[1]*10000,FORMAT='(I04)')     $
              + 'mHz'                                             $
              + '.' + radar
    ENDIF ELSE BEGIN
      dirName = NUMSTR(date[0])                               $
              + '.' + STRING(time[0],FORMAT='(I04)')          $
              + '-' + STRING(time[1],FORMAT='(I04)')          $
              + 'UT'                                          $
              + '.' + STRING(bandLim[0]*10000,FORMAT='(I04)') $
              + '-' + STRING(bandLim[1]*10000,FORMAT='(I04)') $
              + 'mHz'                                         $
              + '.' + radar
    ENDELSE

    SPAWN,'mv output/kmaps/kspect/fullspect.png output/kmaps/'
    SPAWN,'mv output/kmaps/kspect/karr.png output/kmaps/'
    SPAWN,'mv output/kmaps/kspect/karr.txt output/kmaps/'
;stop
    SPAWN,'mv output/kmaps output/current_run/'+dirName
ENDFOR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Clean up run.

SPAWN,'mv output/current_run ' + 'output/music_run-'+run_id
END
