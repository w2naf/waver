;Hyomin's Events

;Event 1
radarVec        = ['sas','kap','gbr','sto','pyk','han']
;radarVec        = ['sye','sys','san','hal']
date            = [19980515,19980515]
startDate       = [19980515]
time            = [1430, 1530]

;;Event 2
;radarVec        = ['kod','pgr','sas','kap','gbr','sto','pyk','han']
;radarVec        = ['tig','ker','sye','sys','san','hal']
;date            = [20001126,20001126]
;startDate       = [20001126]
;time            = [1140, 1240]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
radar           = radarVec[0]

;Used in power rti visualization
rtiCoords       = 'rang'
;rtiYRange       = [65., 75.]
;rtiYRange       = [0000,1500]
dbScale         = 1

;;;;;;;;;;;;;;;;;;;;;;;;
ndays           = 1
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
;scatterflag: 0: all 1: ground 2: ionos 3: mark ground
scatterFlag     = 0

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
