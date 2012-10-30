FUNCTION RAD_FIT_INX_SIMPLESCAN,scan_number,GLOBAL_INX=global_inx
;This routine selects for the earliest THEMIS camping beam.
COMMON rad_data_blk

IF KEYWORD_SET(global_inx) THEN s = TEMPORARY(global_inx)

inx     = RAD_FIT_GET_DATA_INDEX()
scanInx = WHERE( (*rad_fit_data[inx]).beam_scan EQ scan_number)

beamVec  = (*rad_fit_data[inx]).beam[scanInx]
bmSort   = beamVec[SORT(beamVec)]
bmUniq   = bmSort[UNIQ(bmSort)]

;Find Global Index
FOR kk=0,N_ELEMENTS(bmUniq)-1 DO BEGIN
    beam        = bmUniq[kk]
    campInx     = WHERE( (*rad_fit_data[inx]).beam_scan EQ scan_number  $
                    AND  (*rad_fit_data[inx]).beam EQ beam, cnt)
    IF cnt EQ 0 THEN CONTINUE
    IF cnt EQ 1 THEN BEGIN
        goodInx = campInx
    ENDIF ELSE BEGIN
        juls    = (*rad_fit_data[inx]).juls[campInx]
        minJul  = MIN(juls)
        goodInx = WHERE( (*rad_fit_data[inx]).beam_scan EQ scan_number  $
                    AND  (*rad_fit_data[inx]).beam EQ beam              $
                    AND  (*rad_fit_data[inx]).juls EQ minJul)
    ENDELSE
    IF N_ELEMENTS(global_inx) EQ 0 THEN global_inx = goodInx ELSE global_inx = [global_inx, goodInx]
ENDFOR

;Find Local Index
juls            = (*rad_fit_data[inx]).juls[global_inx]
localJuls       = (*rad_fit_data[inx]).juls[scanInx]
FOR kk=0,N_ELEMENTS(juls)-1 DO BEGIN
    goodInx     = WHERE(localJuls EQ juls[kk])
    IF N_ELEMENTS(local_inx) EQ 0 THEN local_inx = goodInx ELSE local_inx = [local_inx, goodInx]
ENDFOR

RETURN,local_inx
END
