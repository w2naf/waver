#%connect_info
import numpy as np
import scipy as sp
import matplotlib.pyplot as mp

import pydarn
import pydarn.proc.music as music
import utils

import pickle

msc = music.music()
msc.params
rld = False
if rld==True:
  myPtr = pydarn.sdio.radDataOpen(
      (msc.params['datetime'])[0],
      msc.params['radar'],
      eTime=(msc.params['datetime'])[1],
      channel=msc.params['channel'],
      bmnum=msc.params['bmnum'],
      filtered=msc.options['filtered'])

  scans = []
  cur_scan = True
  while cur_scan != None:
    cur_scan = pydarn.sdio.radDataReadScan(myPtr)
    if cur_scan != None: scans.append(cur_scan)

  pickle.dump( scans, open( "save.p", "wb" ) )
else:
  scans = pickle.load( open( "save.p", "rb" ) )

#Get date time vector:
dtv = []
for scan in scans:
  tlist = [x.time for x in scan]
  tlist.sort()
  dtv.append(tlist[0])

sa = music.signal_array(dtv,scans)

music.rawToArray(sa)



#beamList = []
#for sc in myScan:
#  beamList.append(sc.bmnum)
#
#beams = np.unique(beamList)

#beams.sort()
