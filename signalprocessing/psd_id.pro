;This function accepts an integrated waveRTI plot and identifies regions of interest based on high power spectral densities.
;pctPwrThresh is the maximum allowed percentage of power difference between a found region of interest and a test ROI that is 1 pixel wider than the found region.  This number should be inversely proportionaly to the size of the detected ROI's.
;fndPwrThresh is the percentage of wave power to detect within the given waveRTI array.  For example, if fndPwrThresh is set to 0.60, then this routine will continue to search for ROI's until 60% of the total power in the waveRTI array has been found.
FUNCTION PSD_ID,dataStruct_in                                           $
            ,PCTPWRTHRESH       = pctPwrThresh                          $
            ,FNDPWRTHRESH       = fndPwrThresh                          $
            ,VERBOSE            = verbose

julVec          = dataStruct_in.julVec
array           = dataStruct_in.data

IF ~KEYWORD_SET(pctPwrThresh)   THEN pctPwrThresh = 0.04
IF ~KEYWORD_SET(fndPwrThresh)   THEN fndPwrThresh = 0.60

totPwr          = TOTAL(array)
fndPwr          = 0D                    ; Used to keep track of the amount of power already found
pctPwrFnd       = 0D                    ; Used to keep track of percentage of power already found

WHILE pctPwrFnd LT fndPwrThresh DO BEGIN
    ;Find the index with the most power that has not yet been identified.
    inx     = WHERE(array EQ MAX(array,/NAN))
    roi0Inx = REVERSE(ARRAY_INDICES(array,inx))
    roi0    = [roi0Inx, roi0Inx]

    roi0Pwr = array[inx]

    found   = 0
    iter    = 0
    WHILE found EQ 0 DO BEGIN
        ;Expand the test ROI out by one pixel in each of the 4 cardinal directions.
        roi1Inx_xm  = ROI_INX(roi0,array,ROI_OUT=roi1_xm,/XMINUS,ROI_SUM=roi1Pwr_xm)
        roi1Inx_xp  = ROI_INX(roi0,array,ROI_OUT=roi1_xp, /XPLUS,ROI_SUM=roi1Pwr_xp)
        roi1Inx_ym  = ROI_INX(roi0,array,ROI_OUT=roi1_ym,/YMINUS,ROI_SUM=roi1Pwr_ym)
        roi1Inx_yp  = ROI_INX(roi0,array,ROI_OUT=roi1_yp, /YPLUS,ROI_SUM=roi1Pwr_yp)

        ;Test to see which expansion gives the most contribution to the test ROI. Once found,
        ;expand in that direction only.
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

        ;Compare the amount of power contained by an ROI that is 1 pixel wider in every
        ;dimemsion than the found ROI to the power contained within the found ROI.  If this
        ;test power is LE pctPwrThresh, then declare the ROI found and move on to finding
        ;the next ROI.
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
        IF KEYWORD_SET(verbose) THEN BEGIN
            PRINT,'Iteration: ',iter
            PRINT,roi1
            PRINT,pwrPct
        ENDIF   ; (verbose)
        iter++
    ENDWHILE
        roiJulGate      =                       $
                        [julVec[roi1[0]]        $
                        ,julVec[roi1[2]]        $
                        ,roi1[1]                $
                        ,roi1[3]]
    IF ~KEYWORD_SET(roiJulGateArr) THEN roiJulGateArr = roiJulGate      $
        ELSE roiJulGateArr = [[roiJulGateArr], [roiJulGate]]
ENDWHILE
RETURN,roiJulGateArr
END
