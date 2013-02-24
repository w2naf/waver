PRO TEST
RESTORE,'pos_waver.sav',/VERBOSE
RESTORE,'pos_rdb.sav',/VERBOSE

pos_rdb = transpose(REFORM(gs_fov_loc_center[0,0,*]))
;pos_waver = transpose(REFORM(ctrFOV_Waver[3,0,*]))

pos_rdb = TRANSPOSE(REFORM(gs_fov_loc_full[0,0,0,*]))
pos_waver = TRANSPOSE(REFORM(bndArr_grid[3,0,0,0,*]))

test = FLTARR(2,71)
test[0,0:N_ELEMENTS(pos_rdb)-1] = pos_rdb
test[1,0:N_ELEMENTS(pos_waver)-1] = pos_waver

STOP
END
