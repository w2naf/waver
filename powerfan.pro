PRO POWERFAN
COMMON rad_data_blk

thick   = 4
!P.CHARTHICK    = thick
!P.THICK        = thick
!X.THICK        = thick
!Y.THICK        = thick


date    = 20101119
time    = 1500
radar   = 'gbr'
param   = 'power'
coords  = 'magn'
xRange  = [-15, 25]
yRange  = [-35,  5]
scale   = [0, 30]
filter  = 0

mark_lineColor  = 0
mark_lineThick  = 4
mark_lineStyle  = 2


SET_FORMAT,/LANDSCAPE,/SARDINES
fileName$       = DIR('output/powerfan.ps',/PS)

RAD_FIT_READ,date,radar,FILTER=filter

RAD_FIT_PLOT_SCAN_PANEL,1,1,0,0                 $
    ,DATE       = date                          $
    ,TIME       = time                          $
    ,PARAM      = param                         $
    ,COORDS     = coords                        $
    ,XRANGE     = xRange                        $
    ,YRANGE     = yRange                        $
    ,SCALE      = scale                         $
    ,/ISOTROPIC                                 $
    ,/NO_FILL                                   $
    ,/NO_FOV

region          = [6, 7, 0, 70]
OVERLAY_FOV                                     $
    ,COORDS     = coords                        $
    ,DATE       = date                          $
    ,TIME       = time                          $
    ,NAMES      = radar                         $
    ,/NO_MARK_FILL                              $
    ,/NO_FILL, /NO_FOV                          $
    ,MARK_REGION        = region                $
    ,MARK_LINECOLOR     = mark_linecolor        $
    ,MARK_LINETHICK     = mark_lineThick        $
    ,MARK_LINESTYLE     = mark_linestyle        $
    ,/ANNOTATE

    

PS_CLOSE

time            = [1200, 2400]
fileName$       = DIR('output/powerrti.ps',/PS)
RAD_FIT_PLOT_RTI                                $
    ,DATE       = date                          $
    ,TIME       = time                          $
    ,PARAM      = param
PS_CLOSE

STOP
END
