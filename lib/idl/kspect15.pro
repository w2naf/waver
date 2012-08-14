PRO KSPECT15
COMMON RAD_DATA_BLK
RESTORE
GEOPAK

;lonCArr
;latCArr

radLat  = (*RAD_FIT_INFO[inx]).mlat
radLon  = (*RAD_FIT_INFO[inx]).mlon
gradLat  = (*RAD_FIT_INFO[inx]).glat
gradLon  = (*RAD_FIT_INFO[inx]).glon

radLat  = 61.1
radLon  = 22.9

SUB_SPHAZM1,radLon,radLat,300.,lonCArr,latCArr,azm,range

file    = DIR('cart.ps',/ps)
stop
END
