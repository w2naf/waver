import erw
import datetime
import numpy as np
from matplotlib import pyplot as mp

date = datetime.datetime(2010,11,19,14,0)
#x    = np.linspace(50., 100., 10000)
x    = np.linspace(0., 5000., 50)

z    = np.linspace(0., 500., 50)
t    = np.linspace(0., 3600., 60) #Time in seconds
t    = np.array([1., 2., 3., 4., 5.]) * 3600.

z_0  = 150 #Lower atmosphere/thermosphere boundary altitude [km]
c1   = 310 #Lower atmosphere sound speed [m/s]
c2   = 900 #Thermospheric sound speed [m/s]

z_s  =  120 #km
I    = -1e5 #Strength of auroral current [A]
dz   = 20.  #Half of the width of the source region [km]

glat =  64.2
glon = -76.6
mlat =  73.8
mlon =   1.8

gw=erw.gw(x,z,t,z_0,c1,c2,z_s,I,dz,glat,glon,date)
toi = 5
xoi = 600
zoi = 200

xoi = 50
zoi = 200
toi = 1

lengthUnits = 'kilometers'
timeUnits   = 'hours'

mp.ion()
gw.atm.plot()
mp.get_current_fig_manager().window.wm_geometry("+0+0")
gw.atm.plotViscosity()
mp.get_current_fig_manager().window.wm_geometry("+0+0")
#gw.ml.plotLayer(xoi,toi,lengthUnits=lengthUnits,timeUnits=timeUnits)
#mp.get_current_fig_manager().window.wm_geometry("+0+0")

#gw.plotSoundProfile()
#gw.plotRangeV_Prime(zoi,[1,2,3,4,5],timeUnits=timeUnits)
#mp.get_current_fig_manager().window.wm_geometry("+500+0")
#
#gw.plotSinVarsRange(xoi,toi,timeUnits=timeUnits,markRange=600)
#mp.get_current_fig_manager().window.wm_geometry("+0+0")
#gw.plotPPrimePartsRange(xoi,toi,timeUnits=timeUnits)
#mp.get_current_fig_manager().window.wm_geometry("+0+0")
#gw.plotSinVarsTime(zoi,xoi,timeUnits=timeUnits,markTime=1)
#mp.get_current_fig_manager().window.wm_geometry("+0+0")

import ipdb; ipdb.set_trace()
