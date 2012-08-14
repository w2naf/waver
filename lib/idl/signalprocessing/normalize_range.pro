FUNCTION NORMALIZE_RANGE,data_in
;Divides a Cell by the RMS value of the time series.
;From Bristow et al. [1994]

result  = data_in*0.

dims    = SIZE(data_in,/DIM)
nSteps  = dims[0]
nCells  = dims[1] * dims[2]

FOR kk=0,nCells-1 DO BEGIN
    ai  = ARRAY_INDICES([dims[1],dims[2]],kk,/DIM)
    bm  = ai[0]
    rg  = ai[1]


    ts  = REFORM(data_in[*,bm,rg])              ;time series
    good     = WHERE(FINITE(ts),cnt)
    IF cnt NE 0 THEN BEGIN
        rms = SQRT( 1./cnt * TOTAL(ts[good]^2))
        result[good,bm,rg]     = ts[good] / rms
    ENDIF
ENDFOR
RETURN,result
END
