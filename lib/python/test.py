# -*- coding: utf-8 -*-
#in this notebook, we will explore how to read radar data
#the necessary routines are in pydarn.sdio
import sys
sys.path.append('/davitpy')
import pydarn.sdio
import datetime as dt
import music

msc = music.music()
msc.params

myPtr = pydarn.sdio.radDataOpen(
    (msc.params['datetime'])[0],
    msc.params['radar'],
    eTime=(msc.params['datetime'])[1],
    channel=msc.params['channel'],
    bmnum=msc.params['bmnum'],
    filtered=msc.options['filtered'])


#Note that the output or radDataOpen is of type radDataPtr
#Let's explore its contents
for key,val in myPtr.__dict__.iteritems():
    print 'myPtr.'+key+' = '+str(val)

myBeam = pydarn.sdio.radDataReadRec(myPtr)
#The output is of type beamData
#a beamData object can store fit data as well as rawacf and iqdat data
#let's look at the contents of myBeam
for key,val in myBeam.__dict__.iteritems():
    print 'myBeam.'+key+' = '+str(val)

#See that the rawacf, fit, and prm attributes are objects
#the rawacf object is empty, since we read fitacf data
#lets look at the prm object
for key,val in myBeam.prm.__dict__.iteritems():
    print 'myBeam.prm.'+key+' = '+str(val)

#And lets look at whats in the fit object
for key,val in myBeam.fit.__dict__.iteritems():
    print 'myBeam.fit.'+key+' = '+str(val)

#we can read to the end of the specified time period, like so:
while(myBeam != None):
    print myBeam
    myBeam = pydarn.sdio.radDataReadRec(myPtr)

#pydarn.plot.fan()
pydarn.plot.fan.plotFan(msc.params['datetime'][0],[msc.params['radar']])
