;GBR Event - Gravity Wave Event
radar           = 'gbr'

date            = [20101119]    ;Used for visualization.
time            = [1400, 1800]
timeStep        = 2.          ;timeStep between scans in Minutes.

param           = 'power'
filter          = 0
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
