PRO KSPECT
COMMON RAD_DATA_BLK

@event

coord           = 'magn'
mapXRange       = [-20, 25]
mapYRange       = [-30, 15]

beamRange       = [ 1,15]
gateRange       = [20,60]

;coord           = 'geog'
;mapXRange       = [-35, 15]
;mapYRange       = [-30, 20]

SET_COORDINATES,coord

;sMin    = FLOOR(time[0]/100)*60. + (time[0] MOD 100)
;eMin    = FLOOR(time[1]/100)*60. + (time[1] MOD 100)
;steps   = CEIL((eMin - sMin) / timeStep)
;minVec  = sMin + FINDGEN(steps) * timeStep
;scanTimeVec = FLOOR(minVec / 60)*100 + (minVec MOD 60)

IF N_ELEMENTS(date) EQ 1 THEN date = [date,date]
SFJUL,date,time,sjul,fjul
totalMin        = (fjul-sjul) * 24. * 60.
nSteps          = CEIL(totalMin / timeStep)
julStepVec      = FINDGEN(nSteps)*timeStep / (24.*60.) + sJul

SET_FORMAT,/LANDSCAPE,/SARDINES
file            = DIR('output/kspect.ps',/PS)
FOR winKK=0,nSteps-1 DO BEGIN
    SFJUL,scanDate,scanTime,sjul,julStepVec[winKK],/JUL_TO_DATE
    IF N_ELEMENTS(scanDate) EQ 1 THEN scanDate = [scanDate,scanDate]
    scanDate = scanDate[1]
    scanTime = scanTime[1]

    IF N_ELEMENTS(date) EQ 1 THEN date = date[0]

    RAD_FIT_READ,date,radar
    SET_PARAMETER,param

    thick           = 4 
    !P.THICK        = thick
    !X.THICK        = thick
    !Y.THICK        = thick
    !P.CHARTHICK    = thick

    CLEAR_PAGE,/NEXT

    title           = 'TID Horizontal Wavenumber Maps'
    subtitle        = STRUPCASE(radar) + ' ' + FORMAT_DATE(scanDate,/HUMAN)
    PLOT_TITLE,title,subTitle

    ;Make position span 2 rows.
        xmaps           = 2
        ymaps           = 3
        xmap            = 0
        ymap            = 0
        posit0          = DEFINE_PANEL(xmaps,ymaps,xmap,ymap,/BAR)
        ymap            = 1
        posit1          = DEFINE_PANEL(xmaps,ymaps,xmap,ymap,/BAR)
        posit           = posit1
        posit[3]        = posit0[3]

    IF N_ELEMENTS(scan_id) GT 0 THEN temp = TEMPORARY(scan_id)
    IF N_ELEMENTS(scan_startJul) GT 0 THEN temp = TEMPORARY(scan_startJul)
    IF N_ELEMENTS(scan_number) GT 0 THEN temp = TEMPORARY(scan_number)
    RAD_FIT_PLOT_SCAN_PANEL                             $
        ,DATE               = scanDate                  $
        ,TIME               = scanTime                  $
        ,XRANGE             = mapXRange                 $
        ,YRANGE             = mapYRange                 $
        ,SCAN_ID            = scan_id                   $
        ,SCAN_STARTJUL      = scan_startJul             $
        ,SCAN_NUMBER        = scan_number               $
        ,/NO_FILL                                       $
        ,POSITION           = posit

    inx             = RAD_FIT_GET_DATA_INDEX()
    stId            = (*RAD_FIT_INFO[inx]).id
    scanInx         = WHERE( (*rad_fit_data[inx]).beam_scan EQ scan_number)
    scanData        = (*rad_fit_data[inx]).power[scanInx,*]
    juls            = (*rad_fit_data[inx]).juls[scanInx]
    juls$           = JUL2STRING(juls)
    scanMark        = (*rad_fit_data[inx]).scan_mark[scanInx]
    beamNm          = (*rad_fit_data[inx]).beam[scanInx]
    lagfrVec        = (*rad_fit_data[inx]).lagfr[scanInx]
    smsepVec        = (*rad_fit_data[inx]).smsep[scanInx]

    xmaps           = 2
    ymaps           = 3
    xmap            = 0
    ymap            = 0
    RAD_FIT_PLOT_SCAN_TITLE,xmaps,ymaps,xmap,ymap           $
        ,SCAN_ID            = scan_id                       $
        ,SCAN_STARTJUL      = scan_startJul                 $
        ,/BAR

    OVERLAY_FOV                                                         $
        ,DATE                   = scanDate                              $
        ,TIME                   = scanTime                              $
        ,LAGFR0                 = lagFrVec[0]                           $
        ,SMSEP0                 = smSepVec[0]                           $
        ,MARK_REGION            = [beamRange+[0,1],gateRange+[0,1]]     $
        ,/NO_MARK_FILL                                                  $
        ,/ANNOTATE                                                      $
        ,/NO_FOV                                                        $
        ,/NO_FILL

    ;Compute year, yrsec for RBPOS
    SFJUL,scan_startDate,scan_startTime,scan_startJul,scan_startJul,/JUL_TO_DATE
    PARSE_DATE,scan_startDate[0],scan_startYear,scan_startMonth,scan_startDay,scan_startDOY
    PARSE_TIME,scan_startTime[0],scan_startHour,scan_startMin
    scan_startYrSec = scan_startDOY  * 24. * 60. * 60.              $
                    + scan_startHour * 60. * 60.                    $
                    + scan_startMin  * 60.



    ;Account for things like THEMIS scan... integrate multiple beam soundings
    ;during a scan.
    bmSort          = beamNm[SORT(beamNm)]
    bmUniq          = bmSort[UNIQ(bmSort)]

    type            = SIZE(scanData,/TYPE)
    nBeams          = N_ELEMENTS(bmUniq)
    nGates          = SIZE(scanData,/DIMENSIONS)
    nGates          = nGates[1]

    CASE type OF
        2:  dataArr = INTARR(nBeams,nGates)
        4:  dataArr = FLTARR(nBeams,nGates)
    ENDCASE
    latCArr          = FLTARR(nBeams,nGates)
    lonCArr          = FLTARR(nBeams,nGates)

    latBound         = FLTARR(nBeams,nGates,4)
    lonBound         = FLTARR(nBeams,nGates,4)

    IF GET_COORDINATES() EQ 'geog' THEN geo = 1 ELSE geo = 0
    FOR kk=0,N_ELEMENTS(bmUniq)-1 DO BEGIN
        kkBeam      = bmUniq[kk]
        kkBeamInx   = WHERE(beamNm Eq kkBeam,nSoundings)
        IF nSoundings EQ 0 THEN CONTINUE ELSE dataArr[kk,*] = scanData[kkBeamInx[0],*]
    ;    IF nSoundings EQ 1 THEN BEGIN
    ;        dataArr[kk,*] = scanData[kkBeamInx,*]
    ;    ENDIF ELSE BEGIN
    ;        ;dataArr[kk,*]    = TOTAL(scanData[kkBeamInx,*],1) / nSoundings
    ;        dataArr[kk,*]    = TOTAL(scanData[kkBeamInx,*],1) / nSoundings
    ;    ENDELSE

        lagfr       = lagfrVec[kkBeamInx[0]]
        smsep       = smsepVec[kkBeamInx[0]]
        FOR rr=0,nGates-1 DO BEGIN
            PRINT,kkBeam,rr+1
            ;Height defaults to 300 km in RBPOS.
            ;I need to check on RXRISE!!!!!
            center  = RBPOS(rr+1                                            $
                        ,HEIGHT     = height                                $
                        ,BEAM       = kkBeam                                $
                        ,LAGFR      = lagfr                                 $
                        ,SMSEP      = smsep                                 $
                        ,RXRISE     = rxrise                                $
                        ,STATION    = stID                                  $
                        ,CENTER     = 1                                     $
                        ,GEO        = geo                                   $
                        ,YEAR       = scan_startYear                        $
                        ,YRSEC      = scan_startYrSec)

            bound   = RBPOS(rr+1                                            $
                        ,HEIGHT     = height                                $
                        ,BEAM       = kkBeam                                $
                        ,LAGFR      = lagfr                                 $
                        ,SMSEP      = smsep                                 $
                        ,RXRISE     = rxrise                                $
                        ,STATION    = stID                                  $
                        ,CENTER     = 0                                     $
                        ,GEO        = geo                                   $
                        ,YEAR       = scan_startYear                        $
                        ,YRSEC      = scan_startYrSec)

            latCArr[kkBeam,rr]      = center[0]
            lonCArr[kkBeam,rr]      = center[1]
            
            latBound[kkBeam,rr,*]   = [bound[0,0,0], bound[0,1,0]           $
                                      ,bound[0,1,1], bound[0,0,1]]
            lonBound[kkBeam,rr,*]   = [bound[1,0,0], bound[1,1,0]           $
                                      ,bound[1,1,1], bound[1,0,1]]
        ENDFOR
    ENDFOR


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Beam-Linear Interpolation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;Beam interpolation
    interpArr       = dataArr*0.
    gateVec     = FINDGEN(nGates)
    FOR bk=0,nbeams-1 DO BEGIN
        goodInx         = WHERE(dataArr[bk,*] NE 10000, cnt)
        IF cnt LE 2 THEN CONTINUE
        result          = INTERPOL(dataArr[bk,goodInx],goodInx,gateVec)
        interpArr[bk,*] = result
    ENDFOR

    ;Restrict range of beams/gates.

    IF beamRange[0] NE 0 THEN $
        interpArr[0:beamRange[0],*]             = !VALUES.F_NAN

    IF beamRange[1] NE nBeams-1 THEN $
        interpArr[beamRange[1]:nBeams-1,*]      = !VALUES.F_NAN

    IF gateRange[0] NE 0 THEN $
        interpArr[*,0:gateRange[0]]             = !VALUES.F_NAN

    IF gateRange[1] NE nGates-1 THEN $
        interpArr[*,gateRange[1]:nGates-1]      = !VALUES.F_NAN
    beamInxArr = INTARR(nbeams,ngates)
    gateInxArr = INTARR(nbeams,ngates)

    FOR zz=0,nGates-1 DO beamInxArr[*,zz] = INDGEN(nbeams)
    FOR zz=0,nBeams-1 DO gateInxArr[zz,*] = INDGEN(nGates)



    ;Make position span 2 rows.
        xmaps           = 2
        ymaps           = 3
        xmap            = 1
        ymap            = 0
        posit0          = DEFINE_PANEL(xmaps,ymaps,xmap,ymap,/BAR)
        ymap            = 1
        posit1          = DEFINE_PANEL(xmaps,ymaps,xmap,ymap,/BAR)
        posit           = posit1
        posit[3]        = posit0[3]

    MAP_PLOT_PANEL                                          $
        ,DATE               = scanDate                      $
        ,TIME               = scanTime                    $
        ,XRANGE             = mapXRange                     $
        ,YRANGE             = mapYRange                     $
        ,/NO_FILL                                           $
        ,POSITION           = posit

    clrArr          = REFORM(GET_COLOR_INDEX(interpArr),[nBeams,nGates])
    FOR dd=0,N_ELEMENTS(clrArr)-1 DO BEGIN
        bmGate      = ARRAY_INDICES(clrArr,dd)
        bm          = bmGate[0]
        rg          = bmGate[1]

        lat         = latBound[bm,rg,*]
        lon         = lonBound[bm,rg,*]

        p0          = CALC_STEREO_COORDS(lat[0],lon[0])
        p1          = CALC_STEREO_COORDS(lat[1],lon[1])
        p2          = CALC_STEREO_COORDS(lat[2],lon[2])
        p3          = CALC_STEREO_COORDS(lat[3],lon[3])

        xx          = [p0[0], p1[0], p2[0], p3[0]]
        yy          = [p0[1], p1[1], p2[1], p3[1]]

        POLYFILL,xx,yy,COLOR=clrArr[dd],NOCLIP=0

    ENDFOR

    OVERLAY_FOV                                                         $
        ,DATE                   = scanDate                              $
        ,TIME                   = scanTime                              $
        ,LAGFR0                 = lagFrVec[0]                           $
        ,SMSEP0                 = smSepVec[0]                           $
        ,MARK_REGION            = [beamRange+[0,1],gateRange+[0,1]]     $
        ,/NO_MARK_FILL                                                  $
        ,/ANNOTATE                                                      $
        ,/NO_FOV                                                        $
        ,/NO_FILL

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    xmaps           = 2
    ymaps           = 3
    xmap            = 0
    ymap            = 2
    posit           = DEFINE_PANEL(xmaps,ymaps,xmap,ymap,/BAR,/WITH_INFO)

    xSize           = 0.6
    ySize           = xSize

    badInx          = WHERE(dataArr EQ 10000, cnt)
    IF cnt NE 0 THEN dataArr[badInx] = !VALUES.F_NAN
    clrArr          = REFORM(GET_COLOR_INDEX(dataArr,/NAN),[nBeams,nGates])
    DRAW_IMAGE,clrArr                                                       $
        ,POSITION           = posit                                         $
        ,XTITLE     = 'Beam'                                                $
        ,YTITLE     = 'Range Gate'                                          $
        ,XCHARSIZE  = xSize                                                 $
        ,YCHARSIZE  = ySize                                                 $
        ,XTICKINTERVAL = 1, XTICKLEN = 1                                    $
        ,/NO_SCALE

    xmaps           = 2
    ymaps           = 3
    xmap            = 1
    ymap            = 2
    posit           = DEFINE_PANEL(xmaps,ymaps,xmap,ymap,/BAR,/WITH_INFO)


    clrArr          = REFORM(GET_COLOR_INDEX(interpArr),[nBeams,nGates])
    DRAW_IMAGE,clrArr                                                       $
        ,POSITION           = posit                                         $
        ,XTITLE     = 'Beam'                                                $
        ,YTITLE     = 'Range Gate'                                          $
        ,XCHARSIZE  = xSize                                                 $
        ,YCHARSIZE  = ySize                                                 $
        ,XTICKINTERVAL = 1, XTICKLEN = 1                                    $
        ,/NO_SCALE

    xs  = [beamRange[0],beamRange[0],beamRange[1],beamRange[1],beamRange[0]] + [0,0,1,1,0]
    ys  = [gateRange[0],gateRange[1],gateRange[1],gateRange[0],gateRange[0]] + [0,1,1,0,0]
    PLOTS,xs,ys,THICK=9,COLOR=GET_WHITE()
    PLOTS,xs,ys,THICK=3

    xmaps           = 2
    ymaps           = 1
    xmap            = 1
    ymap            = 0
    PLOT_COLORBAR,xmaps,ymaps,xmap,ymap,CHARSIZE=0.75

    selectArr  = interpArr[beamRange[0]:beamRange[1],gateRange[0]:gateRange[1]]
    selBeamArr = beamInxArr[beamRange[0]:beamRange[1],gateRange[0]:gateRange[1]]
    selGateArr = gateInxArr[beamRange[0]:beamRange[1],gateRange[0]:gateRange[1]]

    IF winKk EQ 0 THEN BEGIN
        interpData      = selectArr 
        scan_sJulVec    = scan_startJul
    ENDIF ELSE BEGIN
        interpData      = [[[interpData]], [[selectArr]]]
        scan_sJulVec    = [scan_sJulVec, scan_startJul]
    ENDELSE
ENDFOR  ;Timestep Loop - winKk
PS_CLOSE

plotBeam = [  5, 10, 15,  5, 10, 15,  5, 10, 15]
plotGate = [ 50, 50, 50, 40, 40, 40, 30, 30, 30]

SET_FORMAT,/LANDSCAPE,/SARDINES
file            = DIR('output/multi.ps',/PS)
PLOT_TITLE,'Time Series of Selected Cells',STRUPCASE(radar) + ' ' + FORMAT_DATE(scanDate,/HUMAN)
MULTIPLOT,scan_sJulVec,interpData                                       $
    ,PLOTGATE           = plotGate                                      $
    ,PLOTBEAM           = plotBeam                                      $
    ,BEAMARR            = selBeamArr                                    $
    ,GATEARR            = selGateArr                                    $
    ,YRANGE             = pwrScale                                      $
    ,/YSTYLE                                                            $
    ,XTITLE             = 'UT'                                          $
    ,XTICKFORMAT        = 'LABEL_DATE'                                  $
    ,/XSTYLE                                                            $
    ,YTITLE             = 'Power [dB]'                                  $
    ,XCHARSIZE          = 0.5                                           $
    ,YCHARSIZE          = 0.5                                           $
    ,GEOMETRY           = [3,3]

PS_CLOSE

STOP
END
