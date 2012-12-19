import pydarn
import datetime
import numpy as np
from matplotlib.backends.backend_pdf import PdfPages

dateList = ['20121023','20121024','20121025','20121026','20121027','20121028','20121029','20121030','20121031','20121101','20121102','20121103','20121104']

rad      = 'wal'
times    = [0,2359]
beam     = 0
fileType = 'fitex'

#dateStr  = '20101119'
#pdf = PdfPages('sandy.pdf')
for dateStr in dateList:
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

  plt = pydarn.radDataPlotRti(vtrad.active.data,beam=beam,coords='rng',model='GS',fileType=fileType,yrng=[0,2000])
#  pdf.savefig(plt.fig)
  plt.fig.savefig('sandy/'+dateStr+'b'+str(beam)+'.png')

#pdf.close()
