;GBR Event
radarVec        = ['bks','gbr']
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

winLen          = 3. * 60. * 60.
stepLen         = 10. * 60.
bandLim         = [0.002,0.007] ;in Hz

max_offTime     =  7. * 60.
min_onTime      = 30. * 60.
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
