FUNCTION PARAM_REGRID,oldJulVec,oldDataArr,newJulVec
;PARAM_REGRID
;There are often parameters/metadata that accompany time series data which is recorded as
;a function of time along with the time series data of interest.  An example of these parameters
;includes ground scatter flags, lagfr, and smsep.
;
;For numerous reasons, radar data is often not on a regular time grid. In order to perform certain time-series analysis, we interpolate the data to a regular grid.  However, it does not make sense to interpolate the associated parameters/meta-data in the same way.
;
;This function handles the problem by finding at  what times the parameters change,
;and then creating a new parameter vector which matches the new time vector and having the
;changes occur in the parameters at the same times as in the orginal parameters.

dataType        = SIZE(oldDataArr,/TYPE)
dims            = SIZE(oldDataArr,/DIMENSIONS)

nNewData        = N_ELEMENTS(newJulVec)

IF N_ELEMENTS(dims) EQ 2 THEN BEGIN
    nNewData    = [nNewData, dims[1]]
    nDim2       = dims[1]
ENDIF ELSE BEGIN
    nDim2       = 1
ENDELSE

;Make sure new data vector is of the same type as the original vector.
;If the orginal data vector is undefined or of a type not supported by this
;routine, return -1.
CASE dataType OF
    1:  newDataArr = BYTARR(nNewData)
    2:  newDataArr = INTARR(nNewData)
    3:  newDataArr = LONARR(nNewData)
    4:  newDataArr = FLTARR(nNewData)
    5:  newDataArr = DBLARR(nNewData)
    6:  newDataArr = COMPLEXARR(nNewData)
    9:  newDataArr = DCOMPLEXARR(nNewData)
    12: newDataArr = UINTARR(nNewData)
    13: newDataArr = ULONARR(nNewData)
    14: newDataArr = LON64ARR(nNewData)
    15: newDataArr = ULON64ARR(nNewData)
    ELSE: RETURN,-1
ENDCASE

newDataVec      = newDataArr[*,0]
FOR kk = 0,nDim2-1 DO BEGIN
    oldDataVec          = oldDataArr[*,kk]
    nOldData            = N_ELEMENTS(oldDataVec)
    dData               = oldDataVec - SHIFT(oldDataVec,-1)

    inx                 = WHERE(dData NE 0,nInx)

    ;If everything in the vector is exactly the same, then just return
    ;a newly gridded data vector with identical values.
    IF nInx EQ 0 THEN BEGIN
        newDataVec     = 0 * newDataVec + oldDataVec[0]
    ENDIF ELSE BEGIN
        ;Ignore the very last data index, because we did a shift on our data set.
        inx                 = inx[0:nInx-2]
        nInx                = nInx - 1

        ;The index of the change points need to be increased by 1 to
        ;correspond with the correct value in the oldJulVec.
        inx                 = inx+1

        ;Up until the first change point, everything should be equal to the first
        ;point in the oldDataVec.
        cngInx              = WHERE(newJulVec LT oldJulVec[inx[0]],cnt)
        IF cnt NE 0 THEN newDataVec[cngInx]      = oldDataVec[0]

        IF nInx GT 1 THEN BEGIN
            FOR ik=0UL,nInx-2 DO BEGIN
                cngInx  = WHERE(newJulVec GE oldJulVec[inx[ik]] AND newJulVec LT oldJulVec[inx[ik+1]],cnt)
                IF cnt NE 0 THEN newDataVec[cngInx] = oldDataVec[inx[ik]]
            ENDFOR
        ENDIF

        cngInx  = WHERE(newJulVec GE oldJulVec[inx[nInx-1]],cnt)
        IF cnt NE 0 THEN newDataVec[cngInx]      = oldDataVec[nInx-1]
    ENDELSE
    newDataArr[*,kk]    = newDataVec
ENDFOR

RETURN,newDataArr
END
