totPwr          = TOTAL(waveRTI)
fndPwr          = 0D
pctPwrFnd       = 0D
array           = waveRTI

pctPwrThresh    = 0.04
fndPwrThresh    = 0.60

;nFind   = 4
;FOR kf=0,nFind-1 DO BEGIN
WHILE pctPwrFnd LT fndPwrThresh DO BEGIN
    inx     = WHERE(array EQ MAX(array,/NAN))
    roi0Inx = REVERSE(ARRAY_INDICES(array,inx))
    roi0    = [roi0Inx, roi0Inx]

    roi0Pwr = array[inx]

    found   = 0
    iter    = 0
    WHILE found EQ 0 DO BEGIN
    ;    roi1Inx     = ROI_INX(roi0,array,ROI_OUT=roi1,/EXPANDALL,ROI_SUM=roi1Pwr)
        roi1Inx_xm  = ROI_INX(roi0,array,ROI_OUT=roi1_xm,/XMINUS,ROI_SUM=roi1Pwr_xm)
        roi1Inx_xp  = ROI_INX(roi0,array,ROI_OUT=roi1_xp, /XPLUS,ROI_SUM=roi1Pwr_xp)
        roi1Inx_ym  = ROI_INX(roi0,array,ROI_OUT=roi1_ym,/YMINUS,ROI_SUM=roi1Pwr_ym)
        roi1Inx_yp  = ROI_INX(roi0,array,ROI_OUT=roi1_yp, /YPLUS,ROI_SUM=roi1Pwr_yp)

        xyPwrVec    = [roi1Pwr_xm, roi1Pwr_xp, roi1Pwr_ym, roi1Pwr_yp]
        pwrMax      = MAX(xyPwrVec,pwrMaxInx,/NAN)
        CASE pwrMaxInx OF
            0: BEGIN
                roi1        = roi1_xm
                roi1Inx     = roi1Inx_xm
                roi1Pwr     = roi1Pwr_xm
               END
            1: BEGIN
                roi1        = roi1_xp
                roi1Inx     = roi1Inx_xp
                roi1Pwr     = roi1Pwr_xp
               END
            2: BEGIN
                roi1        = roi1_ym
                roi1Inx     = roi1Inx_ym
                roi1Pwr     = roi1Pwr_ym
               END
            3: BEGIN
                roi1        = roi1_yp
                roi1Inx     = roi1Inx_yp
                roi1Pwr     = roi1Pwr_yp
               END
        ENDCASE
        roiTest     = ROI_INX(roi1,array,ROI_OUT=roiTest,/EXPANDALL,ROI_SUM=roiTestPwr)

        pwrDiff = roiTestPwr - roi1Pwr
        pwrPct  = pwrDiff / roiTestPwr
        IF ~KEYWORD_SET(pctVec) THEN pctVec = pwrPct ELSE pctVec = [pctVec,pwrPct]
        IF pwrPct LE pctPwrThresh THEN BEGIN
            found          = 1 
            fndPwr         = fndPwr + roi1Pwr
            pctPwrFnd      = fndPwr / totPwr
            array[roi1Inx] = 0
        ENDIF ELSE BEGIN
            roi0    = roi1
        ENDELSE
        PRINT,'Iteration: ',iter
        PRINT,roi1
        PRINT,pwrPct
;       IF KEYWORD_SET(iter) THEN BEGIN
;               @redraw 
;       ENDIF
        iter++
    ENDWHILE
        roiJulGate      =                       $
                        [timeAxis[roi1[0]]      $
                        ,timeAxis[roi1[2]]      $
                        ,roi1[1]                $
                        ,roi1[3]]
    IF ~KEYWORD_SET(roiJulGateArr) THEN roiJulGateArr = roiJulGate      $
        ELSE roiJulGateArr = [[roiJulGateArr], [roiJulGate]]

    roiPlot     = [timeAxis[roi1[0]], roi1[1], timeAxis[roi1[2]], roi1[3]]
    OPLOT_REC,roiPlot,COLOR=255,THICK=6
;    PS_CLOSE
;    STOP
ENDWHILE


;ENDFOR
