PRO OPLOT_REC,roi_in,_EXTRA=_extra
nRoi    = N_ELEMENTS(roi_in) / 4
roi     = REFORM(roi_in,[nRoi,4])
IF nROI GT 0 THEN BEGIN
    FOR kk=0,nROI-1 DO BEGIN
        x0      = roi[kk,0]
        y0      = roi[kk,1]
        x1      = roi[kk,2]
        y1      = roi[kk,3]+1

        PLOTS,[x0,x0],[y0,y1],_EXTRA=_extra
        PLOTS,[x0,x1],[y1,y1],_EXTRA=_extra
        PLOTS,[x1,x1],[y1,y0],_EXTRA=_extra
        PLOTS,[x1,x0],[y0,y0],_EXTRA=_extra
    ENDFOR
ENDIF
END
