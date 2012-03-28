;GBR Event
radarVec        = ['gbr']
radar           = ['gbr']

date            = [20020302,20020302]
;date            = [20100101]
;ndays           = 365
time            = [0000, 2400]
beam            = 5

param           = 'velocity'
filter          = 1
ajground        = 0
scatterCat      = 0

winLen          = 20. * 60.
stepLen         = 1. * 60.
bandLim         = [0.001,0.003] ;in Hz

max_offTime     =  5. * 60.
min_onTime      = 20. * 60.
interp          = 30.
detrend         = -1
noHanning       = 0
exclude         = [-500.,500.]
scatterFlag     = 0

pctPwrThresh    = 0.04
fndPwrThresh    = 0.60

;Used in gateplot visualization.
windowDate      = date
windowTime      = 0900

;Used in gateplot_day visualization
yrange          = [-5,30]

;Used in power rti visualization
rtiCoords       = 'magn'
;rtiYRange       = [70., 80.]
dbScale         = 1

;Used in rti visualization.
pwrScale        = [0, 30.]
velScale        = [-150.,150.]
