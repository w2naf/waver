FUNCTION OFFTIMES2,dataStruct_in,DATE=date,TIME=time,max_offTime=max_offTime,MIN_ONTIME=min_onTime,SJUL=sjul,FJUL=fjul,DIAGNOSE=diagnose,STOP=stop,ONTIMES=ontimes
COMMON rad_data_blk
;DIAGNOSE=1

IF ~KEYWORD_SET(max_offTime) THEN max_offTime = 120.
IF  KEYWORD_SET(date) AND  KEYWORD_SET(time) THEN SFJUL, date, time, sjul, fjul
IF ~KEYWORD_SET(sjul) AND ~KEYWORD_SET(fjul) THEN BEGIN
    sjul = dataStruct_in.time[0]
    fjul = dataStruct_in.time[N_ELEMENTS(dataStruct_in.time)-1]
ENDIF

timeInx = WHERE(dataStruct_in.time GE sjul AND dataStruct_in.time LE fjul)
juls    = dataStruct_in.time[timeInx]
data    = dataStruct_in.data[timeInx]

;Make sure the time vector is monotonic... just because sometimes it is not...
;Scary, I know...
srt     = SORT(juls)
juls    = juls[srt]
data    = data[srt]

nJuls   = N_ELEMENTS(juls)

goodDataInx  = WHERE(data LT 10000, cnt)
CASE cnt OF
    0: BEGIN
        offTimes = [[sJul],[fJul]]
        onTimes  = -1
        RETURN,offTimes
    END
    nJuls: BEGIN
        offTimes = -1
        onTimes  = [[sJul],[fJul]]
        RETURN,offTimes
    END
    ELSE: BEGIN
        juls    = juls[goodDataInx]
        data    = data[goodDataInx]
        nJuls   = N_ELEMENTS(juls)
    END
ENDCASE

max_offTimeDays = max_offTime / 86400D
dt      = [juls,fjul] - [sjul, juls]
inx     = WHERE(dt GT max_offTimeDays,nInx)

IF nInx GT 0 THEN BEGIN
    offTimes = DBLARR(nInx,2)
    FOR kk = 0,nInx-1 DO BEGIN
        kkInx   = inx[kk]
        CASE kkInx OF
            0       : offTimes[kk,*] = [sjul,juls[kkInx]]
            njuls   : offTimes[kk,*] = [juls[kkInx-1],fjul]
            ELSE    : offTimes[kk,*] = [juls[kkInx-1],juls[kkInx]]
        ENDCASE
    ENDFOR
ENDIF ELSE BEGIN
    offTimes    = -1
    onTimes     = REFORM([sjul, fjul],1,2)
    RETURN,offTimes
ENDELSE

;Calculate periods for which the radar recieved good data.
IF offTimes[0] NE -1 THEN BEGIN
    nOff = N_ELEMENTS(offTimes[*,0])
    IF (offTimes[0,0] NE sjul) AND (offTimes[nOff-1,1] NE fjul) THEN BEGIN
        onTimes = DBLARR(nOff+1,2)
        onTimes[0,0] = sjul
        onTimes[0,1] = offTimes[0,0]
        IF nOff GT 1 THEN BEGIN
            FOR kk = 0,nOff-2 DO BEGIN
                onTimes[kk+1,0] = offTimes[kk,1]
                onTimes[kk+1,1] = offTimes[kk+1,0]
            ENDFOR
        ENDIF
        onTimes[nOff,0] = offTimes[nOff-1,1]
        onTimes[nOff,1] = fjul
    ENDIF
    IF (offTimes[0,0] EQ sjul) AND (offTimes[nOff-1,1] EQ fjul) THEN BEGIN
        IF nOff EQ 1 THEN BEGIN
            offTimes    = REFORM([sjul, fjul],1,2)
            onTimes     = -1
            RETURN,offTimes
        ENDIF ELSE BEGIN
            onTimes = DBLARR(nOff-1,2)
            FOR kk = 0,nOff-2 DO BEGIN
                onTimes[kk,0] = offTimes[kk,1]
                onTimes[kk,1] = offTimes[kk+1,0]
            ENDFOR
        ENDELSE
    ENDIF
    IF (offTimes[0,0] EQ sjul) AND (offTimes[nOff-1,1] NE fjul) THEN BEGIN
        onTimes = DBLARR(nOff,2)
        IF nOff GT 1 THEN BEGIN
            FOR kk = 0,nOff-2 DO BEGIN
                onTimes[kk,0] = offTimes[kk,1]
                onTimes[kk,1] = offTimes[kk+1,0]
            ENDFOR
        ENDIF
        onTimes[nOff-1,0] = offTimes[nOff-1,1]
        onTimes[nOff-1,1] = fjul
    ENDIF
    IF (offTimes[0,0] NE sjul) AND (offTimes[nOff-1,1] EQ fjul) THEN BEGIN
        onTimes = DBLARR(nOff,2)
        onTimes[0,0] = sjul
        onTimes[0,1] = offTimes[0,0]
        IF nOff GT 1 THEN BEGIN
            FOR kk = 0,nOff-2 DO BEGIN
                onTimes[kk+1,0] = offTimes[kk,1]
                onTimes[kk+1,1] = offTimes[kk+1,0]
            ENDFOR
        ENDIF
    ENDIF
ENDIF

IF N_ELEMENTS(onTimes) GT 1 THEN nOn = N_ELEMENTS(onTimes[*,0]) ELSE nOn = 0
IF KEYWORD_SET(stop) THEN STOP
;Code for checking the minimum onTime.
IF KEYWORD_SET(min_onTime) AND nOn NE 0 THEN BEGIN
    min_onJul   = min_onTime / 86400D
    IF onTimes[0] NE -1 THEN BEGIN
        on_duration = onTimes[*,1] - onTimes[*,0]
        badInx      = WHERE(on_duration LT min_onJul, COMPLEMENT=goodInx,cnt)
    ENDIF ELSE BEGIN
        cnt     = 0
        goodInx = -1
    ENDELSE
    IF cnt GT 0 THEN BEGIN
        FOR kk=0,cnt-1 DO BEGIN
            IF onTimes[badInx[kk],0] EQ sjul THEN BEGIN
                offTimes[0] = sjul
                CONTINUE
            ENDIF
            IF onTimes[badInx[kk],1] EQ fjul THEN BEGIN
                offTimes[N_ELEMENTS(offTimes[*])-1] = fjul
                CONTINUE
            ENDIF
            CASE badInx[kk] OF
                0:      BEGIN
                            offTimes[1,0] = sjul
                            offTimes = offTimes[1:*,*]
                        END
                nOn-1:  BEGIN
                            nOff     = N_ELEMENTS(offTimes[*])/2.
                            IF nOff NE 1 THEN BEGIN
                                offTimes[nOff-2,1] = fjul
                                offTimes = offTimes[0:nOff-2,*]
                            ENDIF
                        END
                ELSE:   BEGIN
                            nOff     = N_ELEMENTS(offTimes[*])/2.
                            IF nOff NE 1 THEN BEGIN
                                offInx = WHERE(offTimes[*,0] EQ onTimes[badInx[kk],1],COMPLEMENT=offInx_comp)
                                offTimes[offInx-1,1] = offTimes[offInx,1]
                                offTimes = offTimes[offInx_comp,*]
                            ENDIF
                        END
            ENDCASE
        ENDFOR
    ENDIF
    IF N_ELEMENTS(goodInx) EQ 0 THEN goodInx = -1
    IF goodInx[0] NE -1 THEN onTimes = onTimes[goodInx,*] ELSE onTimes = -1
ENDIF
IF KEYWORD_SET(diagnose) THEN BEGIN
    !X.STYLE = 1 
    beam = 5 
    IF KEYWORD_SET(sjul) AND KEYWORD_SET(fjul) THEN xRange = [sjul, fjul]

    PS_OPEN,DIR()+'time.ps'
    index   = RAD_FIT_GET_DATA_INDEX()
    ;charSize        = 4
    CLEAR_PAGE,/NEXT
    posit   = DEFINE_PANEL(1,1,0,0)
    beamInx = WHERE((*RAD_FIT_DATA[index]).beam EQ beam)
    ;juls    = (*RAD_FIT_DATA[index]).juls[beaminx]
    PLOT_TITLE,'Linear Time Vector',JUL2STRING(juls[0])
    PLOT,juls,juls-juls[0]                  $   
        ,XTICKFORMAT='label_date'           $   
        ,XRANGE     = xRange                $   
        ,POSITION = posit                   $   
        ,CHARSIZE   = charSize              $   
        ,PSYM = 2

    CLEAR_PAGE,/NEXT
    ;juls    = (*RAD_FIT_DATA[index]).juls[beaminx]
    PLOT_TITLE,'dt Vector',JUL2STRING(juls[0])
    ;PLOT,juls,SHIFT(juls,-1) - juls                         $
    PLOT,juls[0:N_ELEMENTS(juls)-2],dt*86400.               $   
        ,XTICKFORMAT='label_date'                           $   
        ,XRANGE     = xRange                                $   
        ;,XRANGE     = [juls[0], juls[N_ELEMENTS(juls)-2]]   $
        ,YTITLE     = 'dt [s]'                              $   
        ,POSITION = posit                                   $   
        ,CHARSIZE   = charSize                              $   
        ,PSYM = 2
    PS_CLOSE
    sj$ = JUL2STRING(sjul)
    fj$ = JUL2STRING(fjul)
    PRINT, 'Start: ' + sj$
    PRINT, 'End:   ' + fj$
    PRINT, 'Offtimes:'
    IF offTimes[0] NE -1 THEN BEGIN
        dtVec = (offtimes[*,1] - offTimes[*,0]) * 86400.
        dtVec$= 'dt = '+NUMSTR(dtVec,1)+' s'
        ot$   = JUL2STRING(offTimes)
        PRINT, TRANSPOSE([[ot$],[dtVec$]])
    ENDIF ELSE PRINT,'No gaps found in dataset.'
ENDIF

IF N_ELEMENTS(offTimes) EQ 2 THEN offTimes = REFORM(offTimes,1,2)
IF N_ELEMENTS(onTimes)  EQ 2 THEN onTimes  = REFORM(onTimes,1,2)
RETURN,offTimes
END
