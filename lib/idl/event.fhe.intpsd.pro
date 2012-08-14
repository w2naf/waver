;GBR Event - Gravity Wave Event
radar           = ['fhe']
radarVec        = radar
beam            = 12

date            = [20101101,20111101]    ;Used for visualization.
time            = [0000, 2400]
SFJUL,date,time,sjul,fjul,NO_DAYS=nDays
;nDays           = 366
timeStep        = 2.          ;timeStep between scans in Minutes.

param           = 'power'
filter          = 1
ajground        = 0

; INTPSD Stuff ;;;;;;;;;;;;;;;;;;;;;;;;;
winLen          = 3.  * 60. * 60.
stepLen         = 1.5 * 60. * 60.

scatterCat      = 0
max_offTime     =  7. * 60. 
min_onTime      = 30. * 60. 
interp          = 30. 
detrend         = -1
noHanning       = 0 
exclude         = [0,500.]
scatterFlag     = 0

pctPwrThresh    = 0.04
fndPwrThresh    = 0.60

;Used in gateplot visualization.
windowDate      = date
windowTime      = 1500

;Used in gateplot_day visualization
yrange          = [-5,30]

;Used in power rti visualization
rtiCoords       = 'rang'
;rtiYRange       = [70., 80.]
dbScale         = 0

;Used in rti visualization.
pwrScale        = [0, 30.]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bandLim         = [0.0003,0.0012] ;in Hz

dRange          = [500,1000]

sim             = 0
keep_lr         = 0

kx_min          = 0.05
ky_min          = 0.05

coord           = 'geog'
mapXRange       = [-15, 15] 
mapYRange       = [-40,-10]

lrdMapXRange    = [-2, 8]
lrdMapYRange    = [-35,-25]
lrdRotate       = 65. 

movieXrange     = [-2, 7]
movieYrange     = [-35,-27]

fftXMax         = 1.5                   ;In mHz - for visualization only
frange          = [0.0003, 0.0015]      ; In Hz - Controls Full Spect Display

dkx             = 0.010
dky             = 0.010
