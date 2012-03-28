db$     = 'ulf'
usr$    = 'ulf'
psd$    = 'ulf'
OPENMYSQL,lun,db$,USER=usr$,PASSWORD=psd$
;query$  = "SELECT * FROM Events;"
pulseClass$     = 'Pc5'
instType$       = 'sd'



FOR mk=0,N_ELEMENTS(roiJulGateArr[0,*])-1 DO BEGIN
    rjg = roiJulGateArr[*,mk]
    query$  = "INSERT INTO Measurements (startDate, endDate, pulseClass, instType, statId, notes) VALUES (" $
            + "'" + JUL2STRING(rjg[0]) + "', "             $
            + "'" + JUL2STRING(rjg[1]) + "', "             $
            + "'" + pulseClass$        + "', "             $
            + "'" + instType$          + "', "             $
            + "'" + radar              + "', "             $
            + "'" + NUMSTR(rjg[2]) + ":" + NUMSTR(rjg[3]) + "');"
    PRINT,query$
    MYSQLCMD,lun,query$,answer,nlines
ENDFOR
        
FREE_LUN,lun
