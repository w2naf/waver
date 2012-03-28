;GBR Event - Gravity Wave Event
radar           = 'gbr'
radarVec        = radar

startDate       = [20101119]    ;Used for ss processing.
nDays           = 1             ;Used for ss processing.

date            = [20101119]    ;Used for visualization.
time            = [1400, 1800]
timeStep        = 2.          ;timeStep between scans in Minutes.
beam            = 7

param           = 'power'
filter          = 0
ajground        = 0
scatterCat      = 0

winLen          = 4. * 60. * 60.
stepLen         = 30 * 60.
bandLim         = [0.0003,0.0005] ;in Hz

max_offTime     = 15. * 60.     ; in sec
min_onTime      = 15. * 60.
interp          = 30.
detrend         = -1
noHanning       = 0
exclude         = [0, 500.]
scale           = [0,30.]
scatterFlag     = 1

pctPwrThresh    = 0.04
fndPwrThresh    = 0.60

;Used in gateplot visualization.
windowDate      = date
windowTime      = 1500

;Used in gateplot_day visualization
;yrange          = [-5,30]

;Used in power rti visualization
rtiCoords       = 'gw_rang'
;rtiCoords       = 'geog'
;rtiYRange       = [70., 80.]
dbScale         = 1 

;Used in rti visualization.
pwrScale        = [0, 30.]
;velScale        = [-150.,150.]

dRange          = [500,1000]

