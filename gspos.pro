PRO GSPOS,GL=gl,RELOAD=reload
COMMON RAD_DATA_BLK

sim             = 1

IF KEYWORD_SET(reload) THEN BEGIN
@event
thick           = 4 
!P.THICK        = thick
!X.THICK        = thick
!Y.THICK        = thick
!P.CHARTHICK    = thick

;
;coord           = 'magn'
;mapXRange       = [-20, 25]
;mapYRange       = [-30, 15]

;beamRange       = [ 0,15]
;gateRange       = [20,60]

;beamRange       = [ 3, 9]
;gateRange       = [33,39]
;s               = TEMPORARY(dRange)

kx_min          = 0.05
ky_min          = 0.05

coord           = 'geog'
mapXRange       = [-15, 15]
mapYRange       = [-40,-10]

lrdMapXRange       = [-2, 8]
lrdMapYRange       = [-35,-25]
lrdRotate          = 65.
rotate             = lrdRotate

SET_COORDINATES,coord
SET_PARAMETER,param

IF  N_ELEMENTS(date) EQ 1 THEN date = date[0] * [1,1]
RAD_FIT_READ,date,radar,TIME=time;,/FILTER
inx             = RAD_FIT_GET_DATA_INDEX()

TIMESTEP,date,time,dateVec,timeVec,STEP=timeStep,JULS=julVec,/ODD
nSteps  = N_ELEMENTS(julVec)
nSteps$ = NUMSTR(nSteps)

scanStepVec = INTARR(nSteps)
FOR step=0,nSteps-1 DO BEGIN
    scanStepVec[step] = RAD_FIT_FIND_SCAN(julVec[step])
ENDFOR
scanStepVec = scanStepVec[UNIQ(scanStepVec)]
nScanSteps  = N_ELEMENTS(scanStepVec)

FOR step=0,nScanSteps-1  DO BEGIN
    scan_number = scanStepVec[step]

    stId            =  (*RAD_FIT_INFO[inx]).id
    scanInx         =  WHERE( (*rad_fit_data[inx]).beam_scan EQ scan_number)

    juls            =  (*rad_fit_data[inx]).juls[scanInx]
    scan_id         = ((*rad_fit_data[inx]).scan_id[scanInx])[0]

    scan_startJul   = MIN(juls)
    SFJUL,scanDate,scanTime,scan_startJul,/JUL_TO_DATE
    scanDate    = scanDate[0]
    scanTime    = scanTime[0]

    juls$           = JUL2STRING(juls)

    local_inx           = RAD_FIT_INX_SIMPLESCAN(scan_number,GLOBAL_INX=global_inx)

    beamVec             = (*rad_fit_data[inx]).beam[global_inx]
    dataArr             = (*rad_fit_data[inx]).power[global_inx,*]
    badInx              = WHERE(dataArr EQ 10000, cnt)
    IF cnt NE 0 THEN dataArr[badInx] = !VALUES.F_NAN

    nBeams              = (SIZE(dataArr,/DIM))[0]
    nGates              = (SIZE(dataArr,/DIM))[1]

    PRINFO,'Time step ' + NUMSTR(step) + ' of ' + nSteps$
    PRINT,'Starting position calculations.'
    t0                  = SYSTIME(1)
    ctrArr              = RAD_FIT_RBPOS_SCAN(scan_number,/CENTER)
    bndArr              = RAD_FIT_RBPOS_SCAN(scan_number)

    ctrArr              = ctrArr[*,local_inx,*]
    bndArr              = bndArr[*,*,*,local_inx,*] 
    t1                  = SYSTIME(1) - t0
    PRINT,'Position Calculation Time: ' + NUMSTR(t1,1) + ' sec'

    IF ~KEYWORD_SET(loopComplete) THEN BEGIN
        PRINFO,'NOTICE: Assuming same scan mode across time period of interest.'
        ctrArr_no_gs        = RAD_FIT_RBPOS_SCAN(scan_number,/NO_GS,/CENTER)
        bndArr_no_gs        = RAD_FIT_RBPOS_SCAN(scan_number,/NO_GS)

        ctrArr_no_gs        = ctrArr_no_gs[*,local_inx,*]
        bndArr_no_gs        = bndArr_no_gs[*,*,*,local_inx,*] 

        ctrArr_grid         = RAD_FIT_RBPOS_SCAN(scan_number,/ALWAYS_GS,/CENTER)
        bndArr_grid         = RAD_FIT_RBPOS_SCAN(scan_number,/ALWAYS_GS)

        ctrArr_grid         = ctrArr_grid[*,local_inx,*]
        bndArr_grid         = bndArr_grid[*,*,*,local_inx,*] 

        IF KEYWORD_SET(dRange) AND ~KEYWORD_SET(gateRange) THEN BEGIN
            gateRange       = INTARR(2)

            srch            = WHERE(REFORM(ctrArr_grid[3,*,*]) GE dRange[0])
            ai              = ARRAY_INDICES(dataArr,srch)
            gateRange[0]    = MIN(ai[1,*])

            srch            = WHERE(REFORM(ctrArr_grid[3,*,*]) LE dRange[1])
            ai              = ARRAY_INDICES(dataArr,srch)
            gateRange[1]    = MAX(ai[1,*])
        ENDIF

        IF ~KEYWORD_SET(dRange) AND KEYWORD_SET(gateRange) THEN BEGIN
            min             = FLOOR(MIN(bndArr[3,*,*,*,gateRange[0]]))
            max             = CEIL(MAX(bndArr[3,*,*,*,gateRange[1]]))
            dRange          = [min, max]
        ENDIF

        IF ~KEYWORD_SET(beamRange) THEN beamRange = [MIN(beamVec), MAX(beamVec)]

        beamInxArr = INTARR(nbeams,ngates)
        gateInxArr = INTARR(nbeams,ngates)

        FOR zz=0,nGates-1 DO beamInxArr[*,zz] = INDGEN(nbeams)
        FOR zz=0,nBeams-1 DO gateInxArr[zz,*] = INDGEN(nGates)


        ;Determine sampling rate for ranges and gates to meet minimum specified k.
        dx_max          = !PI / kx_min 
        dy_max          = !PI / ky_min 

        sel_ctrArr_grid = CTRARR_GRID[*,beamRange[0]:beamRange[1],gateRange[0]:gateRange[1]]
        lr              = LRD(sel_ctrArr_grid)
        xspread         = MAX(lr[0,*,*],/NAN) - MIN(lr[0,*,*],/NAN)
        yspread         = MAX(lr[1,*,*],/NAN) - MIN(lr[1,*,*],/NAN)

        nAvailBeams     = (beamRange[1]-beamRange[0] + 1)
        nAvailGates     = (gateRange[1]-gateRange[0] + 1)

        dx_data         = xspread / nAvailBeams
        dy_data         = yspread / nAvailGates

        kx_data         = !PI / dx_data         ;Best case kx data selection can support
        ky_data         = !PI / dy_data         ;Best case ky data selection can support

        IF kx_data LE kx_min THEN BEGIN
            PRINFO,'Warning!!!! Kx Nyquist Violation!'
            PRINT,'Requested Minumum Kx: ' + NUMSTR(kx_min,4)
            PRINT,'Best available Kx:    ' + NUMSTR(kx_data,4)
            modBeam     = 1
        ENDIF ELSE BEGIN
            nBeam_min   = CEIL(xspread / dx_max)
            modBeam     = nAvailBeams / nBeam_min
        ENDELSE

        IF ky_data LE ky_min THEN BEGIN
            PRINFO,'Warning!!!! Ky Nyquist Violation!'
            PRINT,'Requested Minumum Ky: ' + NUMSTR(ky_min,4)
            PRINT,'Best available Ky:    ' + NUMSTR(ky_data,4)
            modGate     = 1
        ENDIF ELSE BEGIN
            nGate_min   = CEIL(yspread / dy_max)
            modGate     = nAvailGates / nGate_min
        ENDELSE

        ;Select only certain cells to reduce number of computations.
        beamInx     = WHERE(beamVec GE beamRange[0] AND beamVec LE beamRange[1])
        bInx        = INDGEN(N_ELEMENTS(beamInx))
        bInx        = WHERE((bInx MOD modBeam) EQ 0)
        beamInx     = beamInx[bInx]
        nSelBeams   = N_ELEMENTS(beamInx)

        gateVec     = INDGEN(nGates)
        gateInx     = WHERE(gateVec GE gateRange[0] AND gateVec LE gateRange[1])
        gInx        = INDGEN(N_ELEMENTS(gateInx))
        gInx        = WHERE((gInx MOD modGate) EQ 0)
        gateInx     = gateInx[gInx]
        nSelGates   = N_ELEMENTS(gateInx)
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  

        selBeamInxArr   = INTARR(nSelBeams, nSelGates)
        selGateInxArr   = INTARR(nSelBeams, nSelGates)
        
        FOR zz=0,nSelGates-1 DO selBeamInxArr[*,zz] = beamInx
        FOR zz=0,nSelBeams-1 DO selGateInxArr[zz,*] = gateInx

        selBeamArr = beamInxArr[selBeamInxArr,selGateInxArr]
        selGateArr = gateInxArr[selBeamInxArr,selGateInxArr]

        selBeamVec = REFORM(selBeamArr[*,0])
        selGateVec = REFORM(selGateArr[0,*])

        sel_ctrArr_grid = CTRARR_GRID[*,beamInx,gateInx]
        sel_bndArr_grid = bndARR_GRID[*,*,*,beamInx,gateInx]

        lr              = LRD(sel_ctrArr_grid,XCTR=xCtr,YCTR=yCtr,CTRLAT=ctrLat,CTRLON=ctrLon)
        lrBnd           = LRD_BND(sel_bndArr_grid,CTRLAT=ctrLat,CTRLON=ctrLon)

        ctrBm   = selBeamVec[xCtr]
        ctrRg   = selGateVec[yCtr]
        xspread = MAX(lr[0,*,*],/NAN) - MIN(lr[0,*,*],/NAN)
        yspread = MAX(lr[1,*,*],/NAN) - MIN(lr[1,*,*],/NAN)
        latspread       = MAX(sel_ctrArr_grid[0,*,*],/NAN) - MIN(sel_ctrArr_grid[0,*,*],/NAN)
        lonspread       = MAX(sel_ctrArr_grid[1,*,*],/NAN) - MIN(sel_ctrArr_grid[1,*,*],/NAN)

        selRawData      = FLTARR(nScanSteps,nSelBeams,nSelGates)
        interpData      = FLTARR(nScanSteps,nSelBeams,nSelGates)
        scan_sJulVec    = DBLARR(nScanSteps)
    ENDIF

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Beam-Linear Interpolation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    interpArr       = dataArr*0.
    dataZArr        = dataArr

    zero        = WHERE(REFORM(ctrArr[3,*,*]) LT drange[0],zcnt)
    IF zcnt NE 0 THEN BEGIN
        ai      = ARRAY_INDICES(REFORM(ctrArr[3,*,*]), zero)
        zbm     = REFORM(ai[0,*])
        zrg     = REFORM(ai[1,*])
        dataZarr[zbm,zrg] = 0
    ENDIF

    zero        = WHERE(REFORM(ctrArr[3,*,*]) GT drange[1],zcnt)
    IF zcnt NE 0 THEN BEGIN
        ai      = ARRAY_INDICES(REFORM(ctrArr[3,*,*]), zero)
        zbm     = REFORM(ai[0,*])
        zrg     = REFORM(ai[1,*])
        dataZarr[zbm,zrg] = 0
    ENDIF

    FOR bk=0,nbeams-1 DO BEGIN
        goodInx         = WHERE(FINITE(dataZArr[bk,*]), cnt)
        IF cnt LE 2 THEN CONTINUE

        input_x         = REFORM(ctrArr[3,bk,goodInx])
        input_y         = REFORM(dataZArr[bk,goodInx]) 
        output_x        = REFORM(ctrArr_grid[3,bk,*])

        sort_inx        = SORT(input_x)
        input_x         = input_x[sort_inx]
        input_y         = input_y[sort_inx]

        result          = INTERPOL(input_y,input_x,output_x)

        ;Force result to be positive.
        interpArr[bk,*] = result > 0
    ENDFOR

;    test_x1 = REFORM(ctrarr[3,7,*])
;    test_y1 = REFORM(datazarr[7,*])
;    test_x2 = REFORM(ctrarr_grid[3,7,*])
;    test_y2 = REFORM(interparr[7,*])
;
;    sort_inx= SORT(test_x1)
;    test_x1 = test_x1[sort_inx]
;    test_y1 = test_y1[sort_inx]
;
;    test    = TRANSPOSE([[test_x1], [test_y1], [test_x2], [test_y2]])

    dataArr     = dataZarr
    
    ;han = HANNING(nAvailGates)
    ;interpArr[*,gateRange[0]:gateRange[1]] = interpArr[*,gateRange[0]:gateRange[1]] * han
    
    selRawData[step,*,*]    = dataArr[selBeamInxArr,selGateInxArr]
    interpData[step,*,*]    = interpArr[selBeamInxArr,selGateInxArr]
    scan_sJulVec[step]      = scan_startJul

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Plot stuff! ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    IF KEYWORD_SET(gl) THEN BEGIN
        IF ~KEYWORD_SET(loopComplete) THEN BEGIN
            file    = DIR('output/kmaps/lrd.ps',/PS)
            @plot_lrd.pro
            PS_CLOSE
        ENDIF

;        OPEN_LOOP_PLOT,'output/kmaps/','gs_range',step
;        @comp_gs_rang.pro
;        PS_CLOSE
;
;        OPEN_LOOP_PLOT,'output/kmaps/','raw_interp',step
;        @comp_raw_interp.pro
;        PS_CLOSE

        OPEN_LOOP_PLOT,'output/kmaps/','movie',step
        @plot_interp_movie_frame.pro
        PS_CLOSE
    ENDIF       ;Graphics Level

    loopComplete        = 1
ENDFOR  ;Timestep Loop - step

SAVE
ENDIF ELSE RESTORE

sim     = 0
keep_lr = 0
IF KEYWORD_SET(sim) THEN BEGIN
    rgNormalArr  = gwsim(LR=lr,BNDLR=lrBnd,JULS=julVec,KEEP_LR=keep_lr)
    @comp_sim_tid.pro
ENDIF ELSE BEGIN
    rgNormalArr  = NORMALIZE_RANGE(interpData)
    @plot_range_dep_remove.pro
ENDELSE

STOP
END