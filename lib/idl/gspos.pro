FUNCTION EXPAND_GRID,input_grid,beam_vec
;This function expands the positions of a radar scan into an array that can be directly indexed
;by beam number.  This is useful when a scan starts at something other than 
;beam 0, or skips beams.
  dims  = SIZE(input_grid,/DIM)
  IF N_ELEMENTS(beam_vec) NE MAX(beam_vec)+1 THEN BEGIN ;Only do the conversion if it's actually needed.
    CASE N_ELEMENTS(dims) OF
      2: BEGIN
          dims[0] = MAX(beam_vec)+1
          output_grid = FLTARR(dims) + !VALUES.F_NAN
          FOR ii=0,N_ELEMENTS(beam_vec)-1 DO BEGIN
            bm = beam_vec[ii]
            output_grid[bm,*] = input_grid[ii,*]
          ENDFOR
        END
      3: BEGIN
          dims[1] = MAX(beam_vec)+1
          output_grid = FLTARR(dims) + !VALUES.F_NAN
          FOR ii=0,N_ELEMENTS(beam_vec)-1 DO BEGIN
            bm = beam_vec[ii]
            output_grid[*,bm,*] = input_grid[*,ii,*]
          ENDFOR
        END
      5: BEGIN
          dims[3] = MAX(beam_vec)+1
          output_grid = FLTARR(dims) + !VALUES.F_NAN
          FOR ii=0,N_ELEMENTS(beam_vec)-1 DO BEGIN
            bm = beam_vec[ii]
            output_grid[*,*,*,bm,*] = input_grid[*,*,*,ii,*]
          ENDFOR
        END
      ENDCASE
    RETURN,output_grid
  ENDIF
  RETURN,input_grid
END

PRO GSPOS
COMMON RAD_DATA_BLK
COMMON MUSIC_PARAMS

SPAWN,'mkdir -p output/kmaps'

thick           = 4 
!P.THICK        = thick
!X.THICK        = thick
!Y.THICK        = thick
!P.CHARTHICK    = thick

scanStart       = 0 

rotate          = lrdRotate

SET_COORDINATES,coord
SET_PARAMETER,param
RAD_SET_SCATTERFLAG,scatterFlag
IF ~KEYWORD_SET(scale) THEN scale = GET_SCALE()

IF  N_ELEMENTS(date) EQ 1 THEN date = date[0] * [1,1]
RAD_FIT_READ,date,STRLOWCASE(radar),TIME=time,FILTER=filter,AJGROUND=ajground
inx             = RAD_FIT_GET_DATA_INDEX()

TIMESTEP,date,time,dateVec,timeVec,STEP=timeStep,JULS=julVec,/ODD
nSteps  = N_ELEMENTS(julVec)
nSteps$ = NUMSTR(nSteps)

sJul    = julVec[0]
fJul    = julVec[nSteps-1]

scanStepVec = INTARR(nSteps)
FOR step=0,nSteps-1 DO BEGIN
    scanStepVec[step] = RAD_FIT_FIND_SCAN(julVec[step])
ENDFOR
scanStepVec = scanStepVec[UNIQ(scanStepVec)]
nScanSteps  = N_ELEMENTS(scanStepVec)
scan_ids = LONARR(nScanSteps)

FOR step=scanStart,nScanSteps-1  DO BEGIN
    PRINFO,'We are working on radar: '+strupcase(radar)
    PRINFO,'Time range: '+JUL2STRING(sJul)+' to '+JUL2STRING(fJul)
    PRINFO,'Time step ' + NUMSTR(step) + ' of ' + nSteps$
    PRINT,'Starting position calculations.'
    t0                  = SYSTIME(1)

    scan_number = scanStepVec[step]

    stId            =  (*RAD_FIT_INFO[inx]).id
    scanInx         =  WHERE( (*rad_fit_data[inx]).beam_scan EQ scan_number)

    juls            =  (*rad_fit_data[inx]).juls[scanInx]
    scan_id         = ((*rad_fit_data[inx]).scan_id[scanInx])[0]
    scan_ids[step]  = scan_id

    scan_startJul   = MIN(juls)
    SFJUL,scanDate,scanTime,scan_startJul,/JUL_TO_DATE
    scanDate    = scanDate[0]
    scanTime    = scanTime[0]

    juls$           = JUL2STRING(juls)

    local_inx           = RAD_FIT_INX_SIMPLESCAN(scan_number,GLOBAL_INX=global_inx)

    beamVec             = (*rad_fit_data[inx]).beam[global_inx]
;    dataArr             = (*rad_fit_data[inx]).power[global_inx,*]
    cmd$ = 'dataArr = (*rad_fit_data[inx]).'+param+'[global_inx,*]'
    s = EXECUTE(cmd$)
    dataArr             = EXPAND_GRID(dataArr,beamVec)
    badInx              = WHERE(dataArr EQ 10000, cnt)
    IF cnt NE 0 THEN dataArr[badInx] = !VALUES.F_NAN

    gscat               = (*rad_fit_data[inx]).gscatter[global_inx,*]
    gscat               = EXPAND_GRID(gscat,beamVec)
    CASE scatterFlag OF
        1: BEGIN
            scatInx = WHERE(gscat EQ 0, cnt)
            IF cnt NE 0 THEN dataArr[scatInx] = !VALUES.F_NAN
           END
        2: BEGIN
            scatInx = WHERE(gscat EQ 1, cnt)
            IF cnt NE 0 THEN dataArr[scatInx] = !VALUES.F_NAN
           END
     ELSE: BEGIN
           END
    ENDCASE

    rawArr              = dataArr

    nBeams              = (SIZE(dataArr,/DIM))[0]
    nGates              = (SIZE(dataArr,/DIM))[1]

;    ;Calculate positions... this could probably be optimized better.
;    ctrArr              = RAD_FIT_RBPOS_SCAN(scan_number,HEIGHT=height,FIX_HEIGHT=fix_height,/CENTER)
;    bndArr              = RAD_FIT_RBPOS_SCAN(scan_number,HEIGHT=height,FIX_HEIGHT=fix_height)
;
;    ctrArr              = ctrArr[*,local_inx,*]
;    bndArr              = bndArr[*,*,*,local_inx,*] 
;
;    ctrArr              = EXPAND_GRID(ctrArr,beamVec)
;    bndArr              = EXPAND_GRID(bndArr,beamVec)

    IF ~KEYWORD_SET(loopComplete) THEN BEGIN
        PRINFO,'NOTICE: Assuming same scan mode across time period of interest.'
        ctrArr_no_gs        = RAD_FIT_RBPOS_SCAN(scan_number,HEIGHT=height,FIX_HEIGHT=fix_height,/NO_GS,/CENTER)
        bndArr_no_gs        = RAD_FIT_RBPOS_SCAN(scan_number,HEIGHT=height,FIX_HEIGHT=fix_height,/NO_GS)

        ctrArr_no_gs        = ctrArr_no_gs[*,local_inx,*]
        bndArr_no_gs        = bndArr_no_gs[*,*,*,local_inx,*] 
        ctrArr_no_gs        = EXPAND_GRID(ctrArr_no_gs,beamVec)
        bndArr_no_gs        = EXPAND_GRID(bndArr_no_gs,beamVec)

        ctrArr_grid         = RAD_FIT_RBPOS_SCAN(scan_number,HEIGHT=height,FIX_HEIGHT=fix_height,/ALWAYS_GS,/CENTER)
        bndArr_grid         = RAD_FIT_RBPOS_SCAN(scan_number,HEIGHT=height,FIX_HEIGHT=fix_height,/ALWAYS_GS)

        ctrArr_grid         = ctrArr_grid[*,local_inx,*]
        bndArr_grid         = bndArr_grid[*,*,*,local_inx,*]
        ctrArr_grid         = EXPAND_GRID(ctrArr_grid,beamVec)
        bndArr_grid         = EXPAND_GRID(bndArr_grid,beamVec)

        ctrArr              = ctrArr_grid
        bndArr              = bndArr_grid

        IF KEYWORD_SET(dRange) AND ~KEYWORD_SET(gateRange) THEN BEGIN
            gateRange       = INTARR(2)

            srch            = WHERE(REFORM(bndArr_grid[3,0,0,*,*]) GE dRange[0])
            ai              = ARRAY_INDICES(dataArr,srch)
            gateRange[0]    = MIN(ai[1,*])

            srch            = WHERE(REFORM(bndArr_grid[3,1,1,*,*]) LE dRange[1])
            ai              = ARRAY_INDICES(dataArr,srch)
            gateRange[1]    = MAX(ai[1,*])
        ENDIF
        
        ;Check for bad GS range mappings.
        bad     = WHERE(bndArr_grid[3,0,0,*,*] EQ -1, cnt)
        IF cnt NE 0 THEN BEGIN
           ai           = ARRAY_INDICES(REFORM(bndArr_grid[3,0,0,*,*]),bad)
           minGate      = MAX(ai[1,*]) + 1
           IF minGate GT gateRange[0] THEN gateRange[0] = minGate
        ENDIF

        IF ~KEYWORD_SET(dRange) AND KEYWORD_SET(gateRange) THEN BEGIN
            min             = FLOOR(MIN(bndArr[3,*,*,*,gateRange[0]]))
            max             = CEIL(MAX(bndArr[3,*,*,*,gateRange[1]]))
            dRange          = [min, max]
        ENDIF

        IF ~KEYWORD_SET(beamRange) THEN beamRange = [MIN(beamVec), MAX(beamVec)]
        IF beamRange[0] LT MIN(beamVec) THEN beamRange[0] = MIN(beamVec)
        ;Expand the beam vector.
        beamVec    = INDGEN(MAX(beamVec)+1)

        beamInxArr = INTARR(nbeams,ngates)
        gateInxArr = INTARR(nbeams,ngates)

        FOR zz=0,nGates-1 DO beamInxArr[*,zz] = INDGEN(nbeams)
        FOR zz=0,nBeams-1 DO gateInxArr[zz,*] = INDGEN(nGates)


        ;Determine sampling rate for ranges and gates to meet minimum specified k.
        dx_max          = !PI / kx_min 
        dy_max          = !PI / ky_min 

        sel_ctrArr_grid = ctrArr_grid[*,beamRange[0]:beamRange[1],gateRange[0]:gateRange[1]]
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

        IF KEYWORD_SET(use_all_cells) THEN BEGIN
          modBeam = 1
          modGate = 1
        ENDIF
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

        ;AACGM Computations
        IF N_ELEMENTS(height) EQ 0 THEN height  = 300
        aacgm   = CNVCOORD(ctrLat,ctrLon,height)
        ctrJul  = (sjul + fjul) / 2.
        yrYrsec = JUL2YRYRSEC(ctrJul)
        ctrMLat = aacgm[0]
        ctrMlon = aacgm[1]
        ctrMLT  = MLT(yrYrsec[0],yrYrsec[1],ctrMlon)

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
;        goodInx         = WHERE(FINITE(dataZArr[bk,*]) AND ctrArr[3,bk,*] NE -1, cnt)
        IF cnt LE 2 THEN CONTINUE

        input_x         = [drange, REFORM(ctrArr[3,bk,goodInx])]
        input_y         = [0,0,REFORM(dataZArr[bk,goodInx])]
        output_x        = REFORM(ctrArr_grid[3,bk,*])

        sort_inx        = SORT(input_x)
        input_x         = input_x[sort_inx]
        input_y         = input_y[sort_inx]
        
        out_inx = WHERE(output_x NE -1, cnt)
        IF cnt EQ 0 THEN CONTINUE
        result = FLTARR(N_ELEMENTS(output_x))
        result[out_inx] = INTERPOL(input_y,input_x,output_x[out_inx])

        ;Force result to be positive if param is set to power.
        IF param EQ 'power' THEN BEGIN
          interpArr[bk,*] = result > 0
        ENDIF

        ;If you aren't working in power, you can't just set things to 0.
        valid_y = WHERE(input_y NE 0,cnt)
        IF cnt EQ 0 THEN CONTINUE
        valid_xranges = input_x(valid_y)
        minx = MIN(valid_xranges)
        IF minx LT drange[0] THEN minx = drange[0]
        maxx = MAX(valid_xranges)
        IF maxx GT drange[1] THEN maxx = drange[1]

        bad = WHERE(output_x LT minx,cnt)
        IF cnt NE 0 THEN result[bad] = 0

        bad = WHERE(output_x GT maxx,cnt)
        IF cnt NE 0 THEN result[bad] = 0

        interpArr[bk,*] = result
    ENDFOR

    dataArr     = dataZarr
    
    selRawData[step,*,*]    = dataArr[selBeamInxArr,selGateInxArr]
    interpData[step,*,*]    = interpArr[selBeamInxArr,selGateInxArr]
    scan_sJulVec[step]      = scan_startJul

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Plot stuff! ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    IF KEYWORD_SET(gl) THEN BEGIN
        IF ~KEYWORD_SET(loopComplete) AND gl GE 2 THEN BEGIN
            PRINT,'This is here so the routine runs properly.'
            file    = DIR('output/kmaps/lrd.ps',/PS)
            @plot_lrd.pro
            PS_CLOSE
            PS2PNG,file,ROTATE=270
        ENDIF
        IF gl GE 3 THEN BEGIN
            OPEN_LOOP_PLOT,'output/kmaps/','beam_interp',step,FILENAME=fileName
            @plot_beam_interp.pro
            PS_CLOSE
            IF ~KEYWORD_SET(loopComplete) THEN PS2PNG,fileName,ROTATE=270
        ENDIF
        IF gl GE 3 THEN BEGIN
            OPEN_LOOP_PLOT,'output/kmaps/','gs_range',step,FILENAME=fileName
            @comp_gs_rang.pro
            PS_CLOSE
            IF ~KEYWORD_SET(loopComplete) THEN PS2PNG,fileName,ROTATE=270
        ENDIF
        IF gl GE 3 THEN BEGIN
            OPEN_LOOP_PLOT,'output/kmaps/','raw_interp',step,FILENAME=fileName
            @comp_raw_interp.pro
            PS_CLOSE
            IF ~KEYWORD_SET(loopComplete) THEN PS2PNG,fileName,ROTATE=270
        ENDIF
        IF gl GE 2 THEN BEGIN
            OPEN_LOOP_PLOT,'output/kmaps/','movie',step,FILENAME=fileName
            @plot_interp_movie_frame.pro
            PS_CLOSE
            IF ~KEYWORD_SET(loopComplete) THEN PS2PNG,fileName
        ENDIF
    ENDIF       ;Graphics Level

    IF KEYWORD_SET(test) THEN STOP
    loopComplete        = 1

    t1                  = SYSTIME(1) - t0
    PRINT,'Timestep Loop Calculation Time: ' + NUMSTR(t1,1) + ' sec'
    PRINT,''
    PRINT,''
ENDFOR  ;Timestep Loop - step
;sel_ctrArr_grid
;sel_bndArr_grid
;selRawData
;interpData
;scan_sJulVec

PICKLE_MY_DATA,radar,scan_sJulVec,selRawData,sel_ctrArr_grid,sel_bndArr_grid,run_id,PATH='output/kmaps/pickle/',PREFIX='RAW_'
PICKLE_MY_DATA,radar,scan_sJulVec,interpData,sel_ctrArr_grid,sel_bndArr_grid,run_id,PATH='output/kmaps/pickle/',PREFIX='INT_'

SAVE
;PRINFO,'Press .c to run kspect2.pro.'
KSPECT2
END
