;This function overplots Regions of Interest in this format:
;[sjul, fjul, startGate, endGate]
PRO OPLOT_ROI,roi_in,_EXTRA=_extra
nRoi    = N_ELEMENTS(roi_in) / 4
roi     = REFORM(roi_in,[4,nROI])
IF nROI GT 0 THEN BEGIN
    FOR kk=0,nROI-1 DO BEGIN
        x0      = roi[0,kk]
        y0      = roi[2,kk]
        x1      = roi[1,kk]
        y1      = roi[3,kk]+1

        PLOTS,[x0,x0],[y0,y1],_EXTRA=_extra
        PLOTS,[x0,x1],[y1,y1],_EXTRA=_extra
        PLOTS,[x1,x1],[y1,y0],_EXTRA=_extra
        PLOTS,[x1,x0],[y0,y0],_EXTRA=_extra
    ENDFOR
ENDIF
END
