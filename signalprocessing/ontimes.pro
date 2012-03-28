FUNCTION ontimes,DATE=date,TIME=time,BEAM=beam,GATE=gate,PARAM=param,max_offTime=max_offTime,INDEX=index,SJUL=sjul,FJUL=fjul,DIAGNOSE=diagnose,STOP=stop
COMMON rad_data_blk

IF ~KEYWORD_SET(max_offTime) THEN max_offTime = 120.
IF ~KEYWORD_SET(index) THEN index = RAD_FIT_GET_DATA_INDEX()
IF  KEYWORD_SET(date) AND  KEYWORD_SET(time) THEN SFJUL, date, time, sjul, fjul
IF ~KEYWORD_SET(sjul) AND ~KEYWORD_SET(fjul) THEN BEGIN
    sjul = (*RAD_FIT_INFO[index]).sjul
    fjul = (*RAD_FIT_INFO[index]).fjul
ENDIF

IF ~KEYWORD_SET(param) THEN param=GET_PARAMETER()
IF ~KEYWORD_SET(gate) THEN gate = RAD_GET_GATE()

timeInx = WHERE((*RAD_FIT_DATA[index]).juls GE sjul AND (*RAD_FIT_DATA[index]).juls LE fjul)
juls    = (*RAD_FIT_DATA[index]).juls[timeInx]
beams   = (*RAD_FIT_DATA[index]).beam[timeInx]
dd      = EXECUTE('data = (*RAD_FIT_DATA[index]).'+param)
data    = data[timeInx,gate]

beamInx = WHERE(beams EQ beam)

juls    = juls[beamInx]
data    = data[beamInx]

goodDataInx  = WHERE(data LT 10000, cnt)

IF cnt GT 0 THEN BEGIN
    juls        = juls[goodDataInx]
    data        = data[goodDataInx]
ENDIF

max_offTimeDays = max_offTime / 86400D

nJuls   = N_ELEMENTS(juls)
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
ENDIF ELSE offTimes = -1

IF KEYWORD_SET(diagnose) THEN BEGIN
    @scrap

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
IF KEYWORD_SET(stop) THEN STOP

RETURN,offTimes
END
