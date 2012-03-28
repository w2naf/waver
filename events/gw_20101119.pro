;GBR Event
radarVec        = ['bks', 'cve', 'cvw', 'fhe', 'fhw'            $
                  ,'gbr', 'han', 'hok', 'inv', 'kap'            $
                  ,'ksr', 'kod', 'pyk', 'pgr', 'rkn'            $
                  ,'sas', 'sto', 'wal']

date            = [20101119]
time            = [1200, 2400]
beam            = 6

param           = 'power'
filter          = 1
ajground        = 1

winLen          = 3. * 60. * 60.
stepLen         = 10. * 60.
bandLim         = [0.0003,0.0010] ;in Hz

max_offTime     = 15. * 60.
min_onTime      = 15. * 60.
interp          = 30.
detrend         = -1
noHanning       = 0
exclude         = [0,500]
scale           = [0,30]
scatterFlag     = 1

pctPwrThresh    = 0.04
fndPwrThresh    = 0.60
