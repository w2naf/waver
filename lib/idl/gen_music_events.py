#!/usr/bin/env python
import datetime as dt
import numpy as np

head = '''
# This is the MUSIC event analysis list.
# Lines beginning with # are ignored.
# Lines beginning with > are executed by IDL.
# The line beginning with $ contains the names of the variables being set.
# All TID frequencies should be specified in mHz.
# This file is parsed by run_music.pro.
#
# Graphics levels:
#       2: lrd.ps
#       3: beam_interp
#       3: gs_range
#       3: raw_interp
#       2: movie
#       2: compsim
#       3: multi.ps
#       1: fullspectrum
#       3: dlm_abs.ps
#       3: dlm_rs.ps
#       3: dlm_im.ps
#       1: karr.ps

> timeStep        = 2.          ;timeStep between scans in Minutes.
> param           = 'power'
#> scale           = [-25, 25]
> filter          = 0
> ajground        = 0 
> scatterflag     = 1
> sim             = 0 
> keep_lr         = 0 
> kx_min          = 0.05
> ky_min          = 0.05
> coord           = 'geog'
> dkx             = 0.001
> dky             = 0.001
> gl              = 3
> test            = 0 
> nmax            = 5
> fir_filter      = 1
> zero_padding    = 1
> use_all_cells   = 0
> statistics      = 1
> savPath         = '/data2/music/'
#> height          = 300.
#> fix_height      = 1
\n'''

fileName = 'music_events_stats.txt'

_date0  = '{:<11}'.format('date0')
_date1  = '{:<11}'.format('date1')
_time0  = '{:<7}'.format('time0')
_time1  = '{:<7}'.format('time1')

_radar  = '{:<7}'.format('radar')
radar   = '{:<7}'.format('gbr')

_beam  = '{:<6}'.format('beam')
beam    = '{:<6}'.format('6')

_drange0  = '{:<9}'.format('drange0')
drange0 = '{:<9}'.format('400')

_drange1  = '{:<9}'.format('drange1')
drange1 = '{:<9}'.format('1500')

_mapX0  = '{:<7}'.format('mapX0')
mapX0   = '{:<7}'.format('-15')

_mapX1  = '{:<7}'.format('mapX1')
mapX1   = '{:<7}'.format('15')

_mapY0  = '{:<7}'.format('mapY0')
mapY0   = '{:<7}'.format('-40')

_mapY1  = '{:<7}'.format('mapY1')
mapY1   = '{:<7}'.format('-10')

_moovX0  = '{:<8}'.format('moovX0')
moovX0  = '{:<8}'.format('-2')

_moovX1  = '{:<8}'.format('moovX1')
moovX1  = '{:<8}'.format('7')

_moovY0  = '{:<8}'.format('moovY0')
moovY0  = '{:<8}'.format('-35')

_moovY1  = '{:<8}'.format('moovY1')
moovY1  = '{:<8}'.format('-27')

_moovRot  = '{:<9}'.format('moovRot')
moovRot = '{:<9}'.format('65')

_band0  = '{:<7}'.format('band0')
band0   = '{:<7}'.format('0.3')

_band1  = '{:<7}'.format('band1')
band1   = '{:<7}'.format('1.2')

_fft0  = '{:<10}'.format('fft0')
fft0    = '{:<10}'.format('0.0')

_fft1  = '{:<10}'.format('fft1')
fft1    = '{:<10}'.format('1.5')

_kmax  = '{:<10}'.format('kmax')
kmax    = '{:<10}'.format('0.05')

_foi  = '{:<10}'.format('foi')
foi     = '{:<10}'.format('0')

_fir_date0  = '{:<11}'.format('fir_date0')
_fir_date1  = '{:<11}'.format('fir_date1')
_fir_time0  = '{:<11}'.format('fir_time0')
_fir_time1  = '{:<11}'.format('fir_time1')

_fir_scale0  = '{:<12}'.format('fir_scale0')
fir_scale0  = '{:<12}'.format('-2')
_fir_scale1  = '{:<12}'.format('fir_scale1')
fir_scale1  = '{:<12}'.format(' 2')

startDate = dt.datetime(2010,11,01)
endDate   = dt.datetime(2011,11,01)

window    = dt.timedelta(hours=2)
step      = dt.timedelta(hours=0.5)
fir_pad   = dt.timedelta(hours=3)

fir_dt0   = startDate
fir_dt1   = fir_dt0 + window

dt0       = fir_dt0 - fir_pad
dt1       = fir_dt1 + fir_pad

myFile = file( fileName, "w")
myFile.write(head)
myFile.write('$ ' +
  _date0    +
  _date1    +
  _time0    +
  _time1    +
  _radar    +
  _beam     +
  _drange0  +
  _drange1  +
  _mapX0    +
  _mapX1    +
  _mapY0    +
  _mapY1    +
  _moovX0   +
  _moovX1   +
  _moovY0   +
  _moovY1   +
  _moovRot  +
  _band0    +
  _band1    +
  _fft0     +
  _fft1     +
  _kmax     +
  _foi      +
  _fir_date0 +
  _fir_date1 +
  _fir_time0 +
  _fir_time1 +
  _fir_scale0 +
  _fir_scale1 + '\n')
while fir_dt0 < endDate:
#for xx in range(10):
  date0 = '{:<11}'.format(dt0.strftime('%Y%m%d'))
  date1 = '{:<11}'.format(dt1.strftime('%Y%m%d'))
  time0 = '{:<7}'.format(dt0.strftime('%H%M'))
  time1 = '{:<7}'.format(dt1.strftime('%H%M'))

  fir_date0 = '{:<11}'.format(fir_dt0.strftime('%Y%m%d'))
  fir_date1 = '{:<11}'.format(fir_dt1.strftime('%Y%m%d'))
  fir_time0 = '{:<11}'.format(fir_dt0.strftime('%H%M'))
  fir_time1 = '{:<11}'.format(fir_dt1.strftime('%H%M'))

  myFile.write('  '+
    date0 +
    date1 +
    time0 +
    time1 +
    radar    +
    beam     +
    drange0  +
    drange1  +
    mapX0    +
    mapX1    +
    mapY0    +
    mapY1    +
    moovX0   +
    moovX1   +
    moovY0   +
    moovY1   +
    moovRot  +
    band0    +
    band1    +
    fft0     +
    fft1     +
    kmax     +
    foi      +
    fir_date0 +
    fir_date1 +
    fir_time0 +
    fir_time1 +
    fir_scale0 +
    fir_scale1 + '\n')

  fir_dt0   = step + fir_dt0
  fir_dt1   = step + fir_dt1
                            
  dt0       = step + dt0    
  dt1       = step + dt1    

myFile.close

