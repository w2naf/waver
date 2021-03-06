pro music_test

len=16 

nf=128                  ;Number of frequencies
df=2*!pi/float(nf)      ;Change in Frequency

p=fltarr(nf)
;for j=1,20 do begin
   seed=systime(/seconds)
;   a  =cos(findgen(len)*75.*df)+cos(findgen(len)*23.*df+.3*!pi)/1.+randomn(seed,len)/10.
;   a1 =cos(findgen(len)*75.*df)+cos(findgen(len)*23.*df+.3*!pi)/1.
;   b  =sin(findgen(len)*75.*df)+sin(findgen(len)*23.*df+.3*!pi)/1.+randomn(seed,len)/10.

   a=10.*cos(findgen(len)*53.*df+.3*!pi)/1.+randomn(seed,len)
   b=10.*sin(findgen(len)*53.*df+.3*!pi)/1.+randomn(seed,len)
   
   x=complex(a,b)
   x=complex_corl(x,x)
   p+=my_music(x,evals,nf=nf,fmax=2*!pi);,/corl)
   
;endfor
print,evals
;plot,10.*alog10(p*evals[0]/float(len)/max(p))
CLEAR_PAGE,/NEXT
PLOT_TITLE,'Music Spectrum'
posit   = DEFINE_PANEL(1,1,0,0)
plot,10*alog10(p)                       $
    ,CHARSIZE   = 2                     $
    ,XTITLE     = 'Frequency Number'    $
    ,/XSTYLE                            $
    ,YTITLE     = '10 LOG10(p)'         $
    ,POSITION   = posit

;
;CLEAR_PAGE,/NEXT
;PLOT_TITLE,'Input Signals - Real Part'
;posit   = DEFINE_PANEL(1,1,0,0)
;PLOT,a                                  $
;    ,XTITLE     = 'x'                   $
;    ,/XSTYLE                            $
;    ,YTITLE     = 'y'                   $
;    ,POSITION   = posit

OPLOT,a1,COLOR=GET_RED()

;plot,x
stop
end
