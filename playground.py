import pydarn
import datetime
import numpy as np

dateStr  = '20101119'
rad      = 'gbr'
times    = [1400,1600]
beam     = 6
fileType = 'fitex'
#data = pydarn.radDataRead(dateStr,rad,times,fileType=fileType,beam=beam)

vtrad = pydarn.vtrad(dateStr,rad,times,fileType=fileType)

availDt = np.array(vtrad.active.data.getTimes())
time = availDt[0]

i = 0
allBeams = []
allBeams.append(vtrad.active.data[availDt[0]])

dt = availDt
data = vtrad.active.data

#pydarn.radDataPlotFan([vtrad.active.data],colors='aj',model='GS',param='power')
#pydarn.plotRti(dateStr,rad,beam=beam,time=times,fileType=fileType,coords='rng',model='GS',yrng=[500,1000])
pydarn.radDataPlotRti(vtrad.active.data,beam=beam,coords='rng',model='GS',yrng=[500,1000],fileType=fileType)
