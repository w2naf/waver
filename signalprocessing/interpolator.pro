;+ 
; NAME: 
; INTERPOLATOR
; 
; PURPOSE: 
; This function takes in a set of time series data of arbitrary time resolution and regularity and returns a set of regularly spaced data at specified time resolution.
;
; CATEGORY: 
; Signalprocessing
; 
; CALLING SEQUENCE: 
; result = INTERPOLATOR(dataStruct [, delta] [, EPOCHTIME=epochTime])
;
; INPUTS:
; dataStruct:  A data structure containing a time vector and a data vector.  The structure
; should have the form of:
;       dataStruct = {time:timeVector, data:dataVector} 
; dataStruct.time is assumed to be in units of days (for Julian Days) unless the EPOCHTIME
; keyword is set.
;
; OUTPUTS:
; This function returns a data structure of the following form:
;       result = {time:timeVector, data:dataVector} 
;       result = {time:time, data:data, delta:dt}
;       
;       result.time:  Time vector in same units as the input, but now evenly spaced with time
;               resolution delta.
;       result.data:  Data vector interpolated to time resolution delta.
;
; OPTIONAL INPUTS:
; DELTA_IN: Desired time resolution in seconds.  If delta is not set, or if is set delta=0, the input
; is return unchanged.
;
; KEYWORD PARAMETERS:
; EPOCHTIME: Set this keyword to indicate that the input time vector is in units of seconds,
; not days.
;
; EXAMPLE: 
; 
; COPYRIGHT:
; MODIFICATION HISTORY: 
; Written by: Nathaniel Frissell, 2011
;-
FUNCTION INTERPOLATOR,dataStruct_in,delta_in,EPOCHTIME=epochTime,TIMEGRID=timeGrid;,GAPS=gaps,STOP=stop

timeVec = dataStruct_in.time
dataVec = dataStruct_in.data

;If a time grid is already provied, do interpolation direcltly and return answer.
IF N_ELEMENTS(timeGrid) NE 0 THEN BEGIN
    timeGrid0   = timeGrid

    ;Set both ends of the datavector equal to 0 if not finite.
    IF ~FINITE(dataVec[0]) THEN dataVec[0]  = 0

    eInx        = N_ELEMENTS(dataVec)-1
    IF ~FINITE(dataVec[eInx]) THEN dataVec[eInx] = 0

    ;Remove non-finite points like NaNs.
    good        = WHERE(FINITE(dataVec))
    dataVec     = dataVec[good]
    timeVec     = timeVec[good]

    dataGrid    = INTERPOL(dataVec,timeVec,timeGrid0)
    RETURN,{time:timeGrid0,data:dataGrid}
ENDIF

;If only a delta is provided, then calculate a time grid and do interpolation.
IF delta_in GT 0 THEN BEGIN
    delta       = delta_in
    startTime   = timeVec[0]
    timeVec0    = timeVec - startTime
    ;If dataArr_in is given in units of days (i.e. Julian Days), then convert timeVec to seconds.
    ;Ok, so maybe Julian seconds was a bad idea...
    IF ~KEYWORD_SET(epochTime) THEN timeVec0 = timeVec0 * 86400.D

    ;Create time vector in seconds for the duration of the timespan.
    ;Use a resolution equal to interp seconds.
    timeGrid0    = FINDGEN(CEIL(MAX(timeVec0)/delta))*delta
    
    ;Set both ends of the datavector equal to 0 if not finite.
    IF ~FINITE(dataVec[0]) THEN dataVec[0]  = 0

    eInx        = N_ELEMENTS(dataVec)-1
    IF ~FINITE(dataVec[eInx]) THEN dataVec[eInx] = 0

    ;Remove non-finite points like NaNs.
    good        = WHERE(FINITE(dataVec))
    dataVec     = dataVec[good]
    timeVec     = timeVec[good]
    timeVec0    = timeVec0[good]

    ;Interpolate the data.
    dataGrid            = INTERPOL(dataVec,timeVec0,timeGrid0)

    ;Update dataArr with the new data.
    IF ~KEYWORD_SET(epochTime) THEN BEGIN
        timeGrid0        = timeGrid0 / 86400.D
    ENDIF

    timeGrid0    = timeGrid0 + startTime
ENDIF ELSE BEGIN
    PRINFO,'Time resolution not set; no interpolation performed.'
    timeGrid0            = timeVec
    dataGrid            = dataVec 
ENDELSE
    IF KEYWORD_SET(stop) THEN STOP
RETURN,{time:timeGrid0,data:dataGrid}
END

