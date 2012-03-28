PRO STRUCT
nbeams  = 24


struct          = {rawtsr:      PTR_NEW()               $
                  ,rawtsr_juls: PTR_NEW()               $
                  ,badflag:     PTR_NEW()}

stArr = REPLICATE(struct, nBeams)

starr.rawtsr          = PTRARR(nBeams,/ALLOCATE_HEAP)
starr.rawTSR_juls     = PTRARR(nBeams,/ALLOCATE_HEAP)
starr.badFlag         = PTRARR(nBeams,/ALLOCATE_HEAP)

FOR kk=0,nBeams-1 DO BEGIN
    *stArr[kk].rawTsr = FINDGEN(kk+10)
ENDFOR


STOP
END
