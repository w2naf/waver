FUNCTION LINLOAD,datFile
; Read entire data file into a string array. ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
nLines  = FILE_LINES(datFile)
OPENR,unit,datFile,/GET_LUN
inArr   = STRARR(nLines)
READF,unit,inArr
FREE_LUN,unit

linesData       = WHERE(~STRCMP(inArr,'#',1),cnt)
IF cnt EQ 0 THEN BEGIN
    PRINT,'No data in file.  Sorry.'
    RETURN,-1
END
inArr           = inArr[linesData]

linArr  = FLTARR(5,cnt)
FOR kk=0,cnt-1 DO BEGIN
    linArr[*,kk] = STRSPLIT(inArr[kk],' ',/EXTRACT)
ENDFOR
RETURN,linArr
END

;###############################################################################
PRO LINSPLIT,linArr,beam,UT0,rn0,UT1,rn1
    IF N_ELEMENTS(UT0) NE 0 THEN s=TEMPORARY(UT0)
    IF N_ELEMENTS(rn0) NE 0 THEN s=TEMPORARY(rn0)
    IF N_ELEMENTS(UT1) NE 0 THEN s=TEMPORARY(UT1)
    IF N_ELEMENTS(rn1) NE 0 THEN s=TEMPORARY(rn1)
   
    inx = WHERE(linArr[0,*] EQ beam, cnt)
    IF cnt EQ 0 THEN RETURN

    UT0 = linArr[1,inx]
    rn0 = linArr[2,inx]
    UT1 = linArr[3,inx]
    rn1 = linArr[4,inx]
END

;###############################################################################
PRO OP_LINES,date,times,UT0,rn0,UT1,rn1
ddate   = date[0]
TIMESTEP,date,time,JULS=dataXVec
IF N_ELEMENTS(UT0) EQ 0 THEN RETURN

FOR kk=0,N_ELEMENTS(UT0)-1 DO BEGIN
    SFJUL,[ddate,ddate],[UT0[kk],UT1[kk]],x0,x1

    y0  = rn0[kk]
    y1  = rn1[kk]

    m   = (y0-y1)/(x0-x1)
    b   = -m*x1 + y1

    yy  = m*dataXVec + b 

    OPLOT,dataXVec,yy,THICK=10
ENDFOR
END

;###############################################################################
PRO TRACER
radar           = 'gbr'
param           = 'power'
nBeams          = 16
scatterFlag     = 1

evalMode        = 0

date            = [20101119, 20101119]
time            = [1400, 1600]
drange          = [500, 1000]

zoom_date       = [20101119, 20101119]
zoom_time       = [1200, 1600]
zoom_range      = [500, 3000]

;radar           = 'wal'
;param           = 'power'
;nBeams          = 16
;scatterFlag     = 1
;
;evalMode        = 1
;png             = 0
;
;date            = [20110509, 20110509]
;time            = [1200, 1400]
;drange          = [500, 1500]
;
;zoom_date       = [20110509, 20110509]
;zoom_time       = [1200, 1600]
;zoom_range      = [500, 3000]

linFile         = 'lines.txt'
outDir          = 'output/'
ptype           = 'tracer'

SET_PARAMETER,param
RAD_SET_SCATTERFLAG,scatterFlag

RAD_FIT_READ,date,radar,TIME=time

linArr  = LINLOAD(linFile)
FOR beam=0,nBeams-1 DO BEGIN
    LINSPLIT,linArr,beam,UT0,rn0,UT1,rn1

    RAD_SET_BEAM,beam
    OPEN_LOOP_PLOT,outDir,ptype,beam
    @plot_tracer.pro
    DEVICE,/CLOSE
ENDFOR

IF KEYWORD_SET(png) THEN BEGIN
    list    = file_search(outDir+ptype+'/*.ps')
    nFiles  = N_ELEMENTS(list)
    FOR kk=0,nFiles-1 DO BEGIN
        PS2PNG,list[kk]
    ENDFOR

    SPAWN,'mkdir -p ' + outDir+ptype + '/png/'
    SPAWN,'mv ' + outDir+ptype + '/*.png ' + outDir+ptype + '/png/'
ENDIF

STOP
END
