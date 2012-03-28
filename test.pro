PRO TEST,RELOAD=reload
COMMON rad_data_blk
IF KEYWORD_SET(reload) THEN BEGIN
    @event
    RAD_FIT_READ,date[0],radar
    SAVE
ENDIF ELSE RESTORE

result  = RAD_FIT_RBPOS_SCAN(scan_number)
range1  = REFORM(result[3,0,0,*,*])
range2  = REFORM(result[3,1,0,*,*])
range3  = REFORM(result[3,0,1,*,*])
range4  = REFORM(result[3,1,1,*,*])

ctrResult  = RAD_FIT_RBPOS_SCAN(scan_number,/CENTER)
ctrRange   = REFORM(ctrResult[3,*,*])
;PRINT,ctrRange

local_inx = RAD_FIT_INX_SIMPLESCAN(scan_number,GLOBAL_INX=global_inx)

STOP
END
