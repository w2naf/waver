FUNCTION FIR_FILT,julVec,dataVec          $
  ,FLOW       = _fLow                     $
  ,FHIGH      = _fHigh                    $
  ,A          = a                         $
  ,NTERMS     = nTerms                    $
  ,VALIDJULS  = validJuls                 $
  ,PLOT_INFO  = plot_info;                 $
;  ,FILENAME   = _fileName

IF N_ELEMENTS(a)      EQ 0 THEN a = 50
IF N_ELEMENTS(nTerms) EQ 0 THEN nTerms = 100

dt  = (julVec[1] - julVec[0]) * 24. * 60. * 60.
nyq = 1./(2.*dt)

IF N_ELEMENTS(_fLow)   EQ 0 THEN BEGIN
  fLow  = 0  
  _fLow = !VALUES.F_NAN
ENDIF ELSE fLow  = _fLow/nyq

IF N_ELEMENTS(_fHigh)  EQ 0 THEN BEGIN
  fHigh = 1
  _fHigh = !VALUES.F_NAN
ENDIF ELSE fHigh = _fHigh/nyq

IF fLow GT 1 THEN BEGIN
  PRINFO,'WARNING!!!!!'
  PRINT,'Your chosen fLow frequency of '+NUMSTR(_fLow,5)+' Hz'
  PRINT,'is greater than the Nyquist frequency of '+NUMSTR(nyq,5)+' Hz.'
  PRINT,'I will not continue until you fix this problem.'
  STOP
ENDIF

IF fLow GT 1 THEN BEGIN
  PRINFO,'WARNING!!!!!'
  PRINT,'Your chosen fHigh frequency of '+NUMSTR(_fHigh,5)+' Hz'
  PRINT,'is greater than the Nyquist frequency of '+NUMSTR(nyq,5)+' Hz.'
  PRINT,'I will not continue until you fix this problem.'
  STOP
ENDIF

lenBad = CEIL(nTerms/2.)
lenBad = nTerms
validJuls = [julVec[lenBad],julVec[N_ELEMENTS(julVec)-lenBad-1]]
coeff     = DIGITAL_FILTER(fLow,fHigh,A, nTerms)
filtData  = CONVOL(dataVec,coeff)

IF KEYWORD_SET(plot_info) THEN BEGIN
  txFn      = FFT(coeff)
  txFn      = txFn[0:nTerms]
  freqVec   = nyq*(FINDGEN(nTerms+1)/nTerms)

  thick = 4
  !X.THICK = thick
  !Y.THICK = thick
  !P.THICK = thick
  !P.CHARTHICK = thick
  SET_FORMAT,/GUPPIES,/PORTRAIT
;  IF KEYWORD_SET(_fileName) THEN BEGIN
;    fileName = _fileName 
;    PS_OPEN,fileName
;  ENDIF ELSE BEGIN
;    fileName = 'filter.ps'
;    fileName = DIR(fileName,/PS)
;  ENDELSE
  subTitle = TEXTOIDL('f_{low}=')+NUMSTR(_fLow*1000.,2) + ' mHz, '     $
           + TEXTOIDL('f_{high}=')+NUMSTR(_fHigh*1000.,2) + ' mHz. '     $
           + 'A='+NUMSTR(a) + ', ' $
           + 'nTerms='+NUMSTR(nTerms)
  PLOT_TITLE,'Filter Characteristics',subTitle
  posit  = DEFINE_PANEL(1,3,0,0)
  PLOT,coeff                                      $
    ,XTITLE       = 'Time [sec]'                  $
    ,YTITLE       = 'Impulse Response'            $
    ,XTICKS       = xTicks                        $
    ,XMINOR       = xMinor                        $
    ,/XSTYLE                                      $
    ,POSITION     = posit

  posit  = DEFINE_PANEL(1,3,0,1)
  PLOT,freqVec,10.*ALOG10(ABS(txFn))              $
    ,XTITLE       = 'Frequency [Hz]'              $
    ,YTITLE       = 'Transfer Fn Magnitude!C[dB]' $
    ,XTICKS       = xTicks                        $
    ,XMINOR       = xMinor                        $
  ;  ,YRANGE       = 1.05 * [0,MAX(ABS(txFn))] $
    ,PSYM         = -2                            $
    ,/XSTYLE                                      $
    ,POSITION     = posit

  posit  = DEFINE_PANEL(1,3,0,2)
  PLOT,freqVec,ATAN(txFn,/PHASE)/!DTOR            $
    ,XTITLE       = 'Frequency [Hz]'              $
    ,YTITLE       = 'Transfer Fn Phase!C[deg]'    $
    ,YTICKS       = 6                             $
    ,YMINOR       = 0                             $
    ,YRANGE       = [-180,180]                    $
    ,PSYM         = -2                            $
    ,/XSTYLE                                      $
    ,/YSTYLE                                      $
    ,POSITION     = posit

;  PS_CLOSE
;  PS2PNG,fileName;,ROTATE=0
ENDIF

RETURN,filtData
END
