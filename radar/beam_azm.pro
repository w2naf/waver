PRO BEAM_AZM,beam,GEOGAZM=geogAzm,MAGNAZM=magnAzm
GEOTOOLS
COMMON RAD_DATA_BLK

inx     = RAD_FIT_GET_DATA_INDEX()

id      = (*rad_fit_info[inx]).id
nbeams  = (*rad_fit_info[inx]).nbeams
ngates  = (*rad_fit_info[inx]).ngates
bmsep   = (*rad_fit_info[inx]).bmsep
sjul    = (*rad_fit_info[inx]).sjul 
yryrsec = JUL2YRYRSEC(sjul)
year    = yryrsec[0]
yrsec   = yryrsec[1]
normal  = 1

IF beam GE nBeams THEN BEGIN
    geogAzm     = -1
    magnAzm     = -1
    RETURN
ENDIF

coords  = 'geog'
RAD_DEFINE_BEAMS, id, nbeams, ngates, year, yrsec                       $ 
        ,COORDS         = coords                                        $   
;        ,HEIGHT         = height                                        $   
        ,BMSEP          = bmsep                                         $   
        ,NORMAL         = normal                                        $   
        ,SILENT         = silent                                        $   
        ,LAGFR0         = lagfr0                                        $   
        ,SMSEP0         = smsep0                                        $   
        ,FOV_LOC_FULL   = fov_loc_full                                  $   
        ,FOV_LOC_CENTER = fov_loc_center

lat0    = fov_loc_center[0,beam,0]
lon0    = fov_loc_center[1,beam,0]
lat1    = fov_loc_center[0,beam,nGates]
lon1    = fov_loc_center[1,beam,nGates]

GETAZM,lat0,lon0,lat1,lon1,geogAzm
geogAzm = geogAzm*!RADEG

coords  = 'magn'
RAD_DEFINE_BEAMS, id, nbeams, ngates, year, yrsec                       $ 
        ,COORDS         = coords                                        $   
;        ,HEIGHT         = height                                        $   
        ,BMSEP          = bmsep                                         $   
        ,NORMAL         = normal                                        $   
        ,SILENT         = silent                                        $   
        ,LAGFR0         = lagfr0                                        $   
        ,SMSEP0         = smsep0                                        $   
        ,FOV_LOC_FULL   = fov_loc_full                                  $   
        ,FOV_LOC_CENTER = fov_loc_center

lat0    = fov_loc_center[0,beam,0]
lon0    = fov_loc_center[1,beam,0]
lat1    = fov_loc_center[0,beam,nGates]
lon1    = fov_loc_center[1,beam,nGates]

GETAZM,lat0,lon0,lat1,lon1,magnAzm
magnAzm = magnAzm*!RADEG
END
