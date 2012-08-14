;GBR Event
radarVec        = ['rkn']
radar           = radarVec

;Used in power rti visualization
rtiCoords       = 'rang'
;rtiYRange       = [65., 75.]
;rtiYRange       = [0000,1500]
dbScale         = 1

;;;;;;;;;;;;;;;;;;;;;;;;
psdDir          = '/data/waver/psdsav/'
date            = [20080714,20080714]
startDate       = [20080714]
;date            = [20101011,20101011]
;startDate       = [20101011]
ndays           = 1
time            = [1900, 2400]
beam            = 7

param           = 'velocity'
filter          = 0
ajground        = 0
scatterCat      = 0

winLen          = 3. * 60. * 60.
stepLen         = 10. * 60.
bandLim         = [0.002,0.007] ;in Hz

max_offTime     =  7. * 60.
min_onTime      = 30. * 60.
interp          = 30.
detrend         = -1
noHanning       = 0
exclude         = [-500.,500.]
scatterFlag     = 2

pctPwrThresh    = 0.04
fndPwrThresh    = 0.60

;Used in gateplot visualization.
windowDate      = date
windowTime      = 2100

;Used in gateplot_day visualization
yrange          = [-5,30]


;Used in rti visualization.
pwrScale        = [0, 30.]
velScale        = [-150.,150.]
