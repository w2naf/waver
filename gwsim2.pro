FUNCTION GWSIM,LR=lr,BNDLR=bndLr,JULS=juls,KEEP_LR=keep_lr
;Typical TID Parameters:
;       Frequency:      0.0003 mHz
;       Period:         55.5 min
;       H. Wavelength:  314 km
;       k:              0.02 /km
@event
i       = COMPLEX(0,1)

IF KEYWORD_SET(lr) THEN BEGIN
    dims    = SIZE(lr,/DIM)
    nx      = dims[1]
    ny      = dims[2]

    xrange  = MAX(lr[0,*,*]) - MIN(lr[0,*,*])
    yrange  = MAX(lr[1,*,*]) - MIN(lr[1,*,*])
ENDIF ELSE BEGIN
    nx      = 16
    xrange  = 800.

    ny      = 25
    yrange  = 600.
ENDELSE

dx      = xrange / nx
dy      = yrange / ny

xvec    = xrange*(FINDGEN(nx)/(nx-1)-0.5)
yvec    = yrange*(FINDGEN(ny)/(ny-1)-0.5)

xaxis   = [xvec, xvec[nx-1]+dx]
yaxis   = [yvec, yvec[ny-1]+dy]

xgrid   = FLTARR(nx,ny)
ygrid   = FLTARR(nx,ny)

FOR kk=0,nx-1 DO ygrid[kk,*] = yvec
FOR kk=0,ny-1 DO xgrid[*,kk] = xvec

IF KEYWORD_SET(keep_lr) THEN BEGIN
    xgrid       = REFORM(lr[0,*,*])
    ygrid       = REFORM(lr[1,*,*])
ENDIF

;sigs           = [amp,  kx,  ky,  f, phi]
nSigs           = 3
sigs            = FLTARR(nSigs,5)
sigs[0,*]       = [1, 0,  -0.02, 0.0004, 0]
sigs[1,*]       = [2, -0.02,  0, 0.0006, 0]
sigs[2,*]       = [4, -0.04,  0.04, 0.0006, 0]
;sigs[0,*]       = [2, -0.02, 0, 0.0005, 0]
;sigs[0,*]       = [30, -0.0141,  -0.0141, 0.0003, 0]


IF ~KEYWORD_SET(juls) THEN TIMESTEP,date,time,date_out,time_out,STEP=timeStep,JULS=juls,/ODD

secVec  = (juls - juls[0]) * 86400.
nSteps  = N_ELEMENTS(secVec)
dt      = MAX(secVec) / nSteps

julAxis = [juls, juls[nSteps-1] + dt/86400]

dataArr         = FLTARR(nSteps,nx,ny) 

FOR step=0,nSteps-1 DO BEGIN
        t       = secVec[step]
    FOR kk=0,nSigs-1 DO BEGIN
        amp     = sigs[kk,0]
        kx      = sigs[kk,1]
        ky      = sigs[kk,2]
        f       = sigs[kk,3]
        phi     = sigs[kk,4]
        
        IF 1./dt LE 2.*f THEN BEGIN
            PRINT,'WARNING: Nyquist Violation in f.'
            PRINT,'Signal #: ' + NUMSTR(kk)
        ENDIF

        IF 1./dx LE 2.*kx/(2*!PI) THEN BEGIN
            PRINT,'WARNING: Nyquist Violation in kx.'
            PRINT,'Signal #: ' + NUMSTR(kk)
        ENDIF

        IF 1./dy LE 2.*ky/(2*!PI) THEN BEGIN
            PRINT,'WARNING: Nyquist Violation in ky.'
            PRINT,'Signal #: ' + NUMSTR(kk)
        ENDIF

        temp    = amp * COS(kx*xgrid + ky*ygrid - 2*!PI*f*t + phi)
        dataArr[step,*,*] += temp
    ENDFOR
ENDFOR

;Signal RMS
sig_rms = FLTARR(nx,ny)
FOR xx=0,nx-1 DO BEGIN
    FOR yy=0,ny-1 DO BEGIN
    sig_rms[xx,yy] = SQRT(MEAN((dataArr[*,xx,yy])^2))
    ENDFOR
ENDFOR

noise_on=1
noise_rms = FLTARR(nx,ny)
IF KEYWORD_SET(noise_on) THEN BEGIN
    seed    = 0
    ;Temporal White Noise
    FOR xx=0,nx-1 DO BEGIN
        FOR yy=0,ny-1 DO BEGIN
        s           = TEMPORARY(seed)
        noise       = RANDOMN(seed,nSteps)
        noise_rms[xx,yy] = SQRT(MEAN(noise^2))
        dataArr[*,xx,yy]    += noise
        ENDFOR
    ENDFOR
ENDIF

snr     = (sig_rms/noise_rms)^2
snr_db  = 10*ALOG10(snr)


OPENW,unit,'simstats.txt',/GET_LUN,WIDTH=300
stats$  = ' Mean: '   + NUMSTR(MEAN(sig_rms),3)         $
        + ' STDDEV: ' + NUMSTR(STDDEV(sig_rms),3)       $
        + ' Var: '    + NUMSTR(STDDEV(sig_rms)^2,3)
PRINTF,unit,'SIG_RMS'
PRINTF,unit,stats$
PRINTF,unit,sig_rms

PRINTF,unit,''
PRINTF,unit,'NOISE_RMS'
stats$  = ' Mean: '   + NUMSTR(MEAN(noise_rms),3)         $
        + ' STDDEV: ' + NUMSTR(STDDEV(noise_rms),3)       $
        + ' Var: '    + NUMSTR(STDDEV(noise_rms)^2,3)
PRINTF,unit,stats$
PRINTF,unit,noise_rms

PRINTF,unit,''
PRINTF,unit,'SNR_DB'
stats$  = ' Mean: '   + NUMSTR(MEAN(snr_db),3)         $
        + ' STDDEV: ' + NUMSTR(STDDEV(snr_db),3)       $
        + ' Var: '    + NUMSTR(STDDEV(snr_db)^2,3)
PRINTF,unit,stats$
PRINTF,unit,snr_db
CLOSE,unit

IF KEYWORD_SET(gl) AND ~KEYWORD_SET(keep_lr) THEN BEGIN
    IF ~KEYWORD_SET(simScale) THEN simScale = MAX(ABS(dataArr)) * [-1,1]

    file    = DIR('output/gwsim-scan.ps',/PS)
    SET_FORMAT,/LANDSCAPE,/SARDINES
    FOR step=0,nSteps-1 DO BEGIN
        CLEAR_PAGE,/NEXT
        title       = 'TID Simulator'
        subTitle    = STRUPCASE(radar) + ' ' + JUL2STRING(juls[step])
        PLOT_TITLE,title,subtitle
        
        clrArr      = REFORM(GET_COLOR_INDEX(dataArr[step,*,*],SCALE=simScale,PARAM=param,/CONTINUOUS),[nx,ny])
        posit       = DEFINE_PANEL(1,1,0,0,/BAR)
        DRAW_IMAGE,clrArr,xaxis,yaxis                       $
            ,XTITLE = 'EW [km]'                             $
            ,YTITLE = 'NS [km]'                             $
            ,POSITION       = posit

        PLOT_COLORBAR,1,1,0,0,SCALE=simScale,PARAMETER=param,LEGEND='Amplitude',/CONTINUOUS

    ENDFOR
    PS_CLOSE

    file    = DIR('output/gwsim-rti.ps',/PS)
    SET_FORMAT,/LANDSCAPE,/SARDINES
    FOR bm=0,nx-1 DO BEGIN
        CLEAR_PAGE,/NEXT
        title       = 'TID Simulator - RTI Plot'
        subTitle    = STRUPCASE(radar) + ' Beam ' + NUMSTR(bm)              $
                    + ' (' + JUL2STRING(juls[0])                            $
                    + '-' + JUL2STRING(juls[nSteps-1]) + ')'
        PLOT_TITLE,title,subtitle
        
        xticks  = GET_XTICKS(julAxis[0],julAxis[nSteps-1],XMINOR=xMinor)
        clrArr      = REFORM(GET_COLOR_INDEX(dataArr[*,bm,*],SCALE=simScale,PARAM=param,/CONTINUOUS),[nSteps,ny])
        posit       = DEFINE_PANEL(1,1,0,0,/BAR)
        DRAW_IMAGE,clrArr,julAxis,yAxis                     $
            ,XTITLE = 'UT Time'                             $
            ,YTITLE = 'Range'                               $
            ,XTICKS = xticks                                $
            ,XMINOR = xminor                                $
            ,XTICKFORMAT = 'LABEL_DATE'                     $
            ,POSITION       = posit

        PLOT_COLORBAR,1,1,0,0,SCALE=simScale,PARAMETER=param,LEGEND='Amplitude',/CONTINUOUS

    ENDFOR
    PS_CLOSE
ENDIF   ; GL - Graphics Level

IF KEYWORD_SET(lr) AND ~KEYWORD_SET(keep_lr) THEN BEGIN
    lr[0,*,*]   = xgrid
    lr[1,*,*]   = ygrid
    lr[2,*,*]   = SQRT(xgrid^2 + ygrid^2)
    lr[3,*,*]   = ATAN(xgrid,ygrid) * !RADEG

    bndLr       = FLTARR(4,2,2,nx,ny)
    FOR xx=0,nx-1 DO BEGIN
        FOR yy=0,ny-1 DO BEGIN
            xp  = xgrid[xx,yy]
            yp  = ygrid[xx,yy]

            bndLr[0,0,0,xx,yy]   = xp - dx/2.
            bndLr[0,0,1,xx,yy]   = xp - dx/2.
            bndLr[0,1,1,xx,yy]   = xp + dx/2.
            bndLr[0,1,0,xx,yy]   = xp + dx/2.

            bndLr[1,0,0,xx,yy]   = yp - dy/2.
            bndLr[1,0,1,xx,yy]   = yp + dy/2.
            bndLr[1,1,1,xx,yy]   = yp + dy/2.
            bndLr[1,1,0,xx,yy]   = yp - dy/2.

            bndLr[2,0,0,xx,yy]   = SQRT((xp-dx/2.)^2 + (yp-dy/2.)^2)
            bndLr[2,0,1,xx,yy]   = SQRT((xp-dx/2.)^2 + (yp+dy/2.)^2)
            bndLr[2,1,1,xx,yy]   = SQRT((xp+dx/2.)^2 + (yp+dy/2.)^2)
            bndLr[2,1,0,xx,yy]   = SQRT((xp+dx/2.)^2 + (yp-dy/2.)^2)

            bndLr[3,0,0,xx,yy]   = ATAN(xp-dx/2.,yp-dy/2.) * !RADEG
            bndLr[3,0,1,xx,yy]   = ATAN(xp-dx/2.,yp+dy/2.) * !RADEG
            bndLr[3,1,1,xx,yy]   = ATAN(xp+dx/2.,yp+dy/2.) * !RADEG
            bndLr[3,1,0,xx,yy]   = ATAN(xp+dx/2.,yp-dy/2.) * !RADEG
        ENDFOR
    ENDFOR
ENDIF

RETURN,dataArr
END
