;+ 
; NAME: 
; RAD_PSD_PLOT_SCAN
; 
; PURPOSE: 
; This procedure plots a stereographic map grid and overlays coast
; lines and a scan of the currently loaded radar data. This routine will call
; RAD_FIT_PLOT_SCAN_PANEL multiple times if need be.
;
; The scan that will be plot is either chosen by its number (set keyword
; SCAN_NUMBER), the date and time closest to an available scan 
; (set DATE and TIME keywords) or the Juliand Day in SCAN_STARTJUL.
;
; NSCANS then determines how many sequential scan plots are put on one page.
; 
; 
; CATEGORY:  
; Graphics
; 
; CALLING SEQUENCE: 
; RAD_FIT_PLOT_SCAN
;
; KEYWORD PARAMETERS:
; DATE: A scalar giving the date to plot, in YYYYMMDD format.
;
; TIME: A scalar giving the time to plot, in HHII format.
;
; LONG: Set this keyword to indicate that the TIME value is in HHIISS
; format rather than HHII format.
;
; PARAM: Set this keyword to specify the parameter to plot. Allowable
; values are 'power', 'velocity', and 'width'. Default is 'power'.
;
; CHANNEL: Set this keyword to the channel number you want to plot.
;
; SCAN_ID: Set this keyword to the numeric scan id you want to plot.
;
; COORDS: Set this keyword to a string naming the coordinate system.
; Allowable inputs are 'mlt', 'magn' and 'geog'.
; Default is 'magn'.
;
; XRANGE: Set this keyword to change the range of the x axis.
;
; YRANGE: Set this keyword to change the range of the y axis.
;
; SCALE: Set this keyword to change the scale of the plotted values.
;
; SCAN_STARTJUL: Set this to a Julian Day determining the scan to plot.
;
; SCAN_NUMBER: Set this to a numer specifying the scan to plot.
;
; NSCANS: Set this to the number of sequential scans to plot. Default is 1.
;
; CHARTHICK: Set this keyword to change the font thickness.
;
; CHARSIZE: Set this keyword to change the font size. 
;
; SILENT: Set this keyword to surpress all messages/warnings.
;
; FREQ_BAND: Set this keyword to a 2-element vector indicating the
; frequency pass band you wish to plot.
;
; NO_FILL: Set this keyword to surpress filling of land masses and lakes with colors.
;
; NO_TITLE: Set this keyword to omit individual titles for the plots.
;
; COMMON BLOCKS:
; RAD_DATA_BLK: The common block holding radar data.
;
; EXAMPLE: 
; 
; COPYRIGHT:
; MODIFICATION HISTORY: 
; Based on Steve Milan's PLOT_POLAR.
; Written by Lasse Clausen, Nov, 24 2009
; Written by Nathaniel Frissell, October 2011
;-
PRO RAD_PSD_PLOT_SCAN                                                   $
    ,DATE                       = date                                  $
    ,TIME                       = time                                  $
    ,JUL                        = jul                                   $
    ,LONG                       = long                                  $
    ,PARAM                      = param                                 $
    ,SCALE                      = scale                                 $
    ,CHANNEL                    = channel                               $
    ,SCAN_ID                    = scan_id                               $
    ,SCAN_STARTJUL              = scan_startjul                         $
    ,NSCANS                     = nscans                                $
    ,COORDS                     = coords                                $
    ,XRANGE                     = xrange                                $
    ,YRANGE                     = yrange                                $
    ,AUTORANGE                  = autorange                             $
    ,CHARTHICK                  = charthick                             $
    ,CHARSIZE                   = charsize                              $
    ,SCAN_NUMBER                = scan_number                           $
    ,VECTOR                     = vector                                $
    ,FIXED_LENGTH               = fixed_length                          $
    ,FIXED_COLOR                = fixed_color                           $
    ,NO_PLOT_GND_SCATTER        = no_plot_gnd_scatter                   $
    ,FREQ_BAND                  = freq_band                             $
    ,SILENT                     = silent                                $
    ,NO_FILL                    = no_fill                               $
    ,NO_TITLE                   = no_title                              $
    ,NO_FOV                     = no_fov                                $
    ,ROTATE                     = rotate                                $
    ,SOUTH                      = south                                 $
    ,GROUND                     = ground                                $
    ,SC_VALUES                  = sc_values                             $
    ,PREFFT                     = prefft                                $
    ,CONTINUOUS                 = continuous                            $
    ,NO_DATA                    = no_data                               $
    ,BANDLIM                    = bandLim                               $
    ,ISOTROPIC                  = isotropic                             $
    ,NO_CLEAR_PAGE              = no_clear_page                         $
    ,WITH_INFO                  = with_info                             $
    ,SAVFILE                    = savFile

;common rad_data_blk
COMMON wave_blk
IF ~KEYWORD_SET(no_data) THEN BEGIN
    IF ~KEYWORD_SET(preFFT) THEN BEGIN
        infoStruct  = wave_dataproc_info
        dataStruct  = WAVE_intpsd_data
        julVec      = dataStruct.intPwrRtiJulVec
        dataArr     = dataStruct.intPwrRtiArr
        grndArr     = dataStruct.intPwrRtiArrGround
    ENDIF ELSE BEGIN
        infoStruct  = wave_dataproc_info
        dataStruct  = WAVE_intpsd_data
        julVec      = dataStruct.preFFTRtiJulVec
        dataArr     = dataStruct.preFFTRtiArr
        grndArr     = dataStruct.preFFTRtiArrGround
    ENDELSE
    bandLim         = infoStruct.bandLim
    param           = infoStruct.param
ENDIF

SET_PARAMETER,param

IF param EQ 'velocity' || param EQ 'width' THEN BEGIN
    unit$   = TEXTOIDL(' [(m s^{-1})^2]')
    intUnit$= TEXTOIDL(' [(m s^{-1})^2 Hz]')
ENDIF   
IF param EQ 'power' THEN BEGIN
    unit$   = TEXTOIDL(' [(dB)^2]')
    intUnit$= TEXTOIDL(' [(dB)^2 Hz]')
ENDIF


; get index for current data
;data_index = rad_fit_get_data_index()
;if data_index eq -1 then begin
;	if ~keyword_set(silent) then $
;		prinfo, 'No data. '
;	return
;endif
;
;if (*rad_fit_info[data_index]).nrecs eq 0L then begin
;	if ~keyword_set(silent) then begin
;		prinfo, 'No data in index '+string(data_index)
;		rad_fit_info
;	endif
;	return
;endif

IF KEYWORD_SET(jul) THEN BEGIN
;    caldat, jul, month, day, year, hh, ii
;    date        = year*10000L + month*100L + day
;    time        = hh*100 + ii
    caldat, jul, month, day, year, hh, ii, ss
    date        = year*10000L + month*100L + day
    time        = hh*10000 + ii*100 + ss
    long        = 1
ENDIF

if ~keyword_set(date) then begin
	if ~keyword_set(silent) then $
		prinfo, 'No DATE given, trying for scan date.'
	;caldat, (*rad_fit_data[data_index]).juls[0], month, day, year
	caldat, wave_dataproc_info.juls[0], month, day, year
	date = year*10000L + month*100L + day
endif

if n_elements(time) eq 0 then $
	time = 1200
sfjul, date, time, sjul, fjul, long=long

;if n_elements(time) eq 1 then begin
;	if ~keyword_set(nscans) then $
;		nscans=1
;	scans = rad_fit_find_scan(sjul, channel=channel, scan_id=scan_id)
;	scans += findgen(nscans)
;endif else if n_elements(time) eq 2 then begin
;	if keyword_set(nscans) then begin
;		prinfo, 'When using TIME as 2-element vector, you must NOT provived NSCANS.'
;		return
;	endif
;	scans = rad_fit_find_scan([sjul, fjul], channel=channel, scan_id=scan_id)
;	nscans = n_elements(scans)
;endif

if ~keyword_set(param) then $
	param = wave_dataproc_info.param

if ~keyword_set(coords) then $
	coords = get_coordinates()

if keyword_set(autorange) then $
	rad_calculate_map_coords, ids=rad_dataproc_info.id, coords=coords, $
		jul=(sjul+fjul)/2.d, $
		xrange=xrange, yrange=yrange, rotate=rotate

if ~keyword_set(yrange) then $
	yrange = [-31,31]

if ~keyword_set(xrange) then $
	xrange = [-31,31]
aspect = float(xrange[1]-xrange[0])/float(yrange[1]-yrange[0])

; if scan_number is set, use that instead of the
; one just found by using date and time
if n_elements(scan_number) gt 0 then begin
	if scan_number ne -1 then begin
		scans = scan_number
		nscans = 1
	endif
endif
;npanels = nscans
npanels = 1

nparams = n_elements(param)
if nparams gt 1 then begin
	if nscans gt 1 then begin
		prinfo, 'If multiple params are set, nscans must be scalar.'
		return
	endif
	npanels = nparams
endif

; calculate number of panels per page
xmaps = floor(sqrt(npanels)) > 1
ymaps = ceil(npanels/float(xmaps)) > 1

; take into account format of page
; if landscape, make xmaps > ymaps
fmt = get_format(landscape=ls)
if ls then begin
	if ymaps gt xmaps then begin
		tt = xmaps
		xmaps = ymaps
		ymaps = tt
	endif
; if portrait, make ymaps > xmaps
endif else begin
	if xmaps gt ymaps then begin
		tt = ymaps
		ymaps = xmaps
		xmaps = tt
	endif
endelse

; for multiple parameter fan plots
; always stack horizontally them
if nparams gt 1 then begin
	xmaps = npanels
	ymaps = 1
endif

; clear output area
IF ~KEYWORD_SET(no_clear_page) THEN CLEAR_PAGE

Ascale = 0


; loop through panels
for s=0, npanels-1 do begin

	if nparams gt 1 then begin
		aparam = param[s]
		;ascan = scans[0]
		if keyword_set(scale) then $
			ascale = scale[s*2:s*2+1] $
		else $
			ascale = get_default_range(aparam)
	endif else begin
		aparam = param[0]
		;ascan = scans[s]
		if keyword_set(scale) then $
			ascale = scale
	endelse

	xmap = s mod xmaps
	ymap = s/xmaps

	ytitle = ' '
	if xmap eq 0 then $
		ytitle = ''

	xtitle = ' '
	if ymap eq ymaps-1 then $
		xtitle = ''

	panel_position = 0

        IF ~KEYWORD_SET(preFFT) THEN BEGIN
            cbScale = 1E6 * ascale
            IF param EQ 'velocity' || param EQ 'width' THEN BEGIN
                intUnit$= TEXTOIDL(' [(m s^{-1})^2 Hz]')
            ENDIF   
            IF param EQ 'power' THEN BEGIN
                intUnit$= TEXTOIDL(' [(dB)^2 Hz]')
            ENDIF
            cbLegend$   = TEXTOIDL('10^6 \cdot') + intUnit$
        ENDIF ELSE BEGIN 
            cbScale     = aScale
            aparam      = 'velocity'
            cbLegend$   = GET_DEFAULT_TITLE(param)
        ENDELSE
        IF nparams EQ 1 THEN BEGIN
            PLOT_COLORBAR, 1, 1, 0, 0                                                   $
                ,SCALE                          = cbScale                               $
                ,PARAM                          = aparam                                $
                ,PANEL_POSITION                 = panel_position                        $
                ,GROUND                         = ground                                $
                ,LEGEND                         = cbLegend$                             $
                ,/KEEP_FIRST_LAST_LABEL                                                 $
                ,WITH_INFO                      = with_info                             $
        ;        ,SC_VALUES                      = sc_values                             $
                ,CONTINUOUS                     = continuous
        ENDIF

	if nparams gt 1 then $
		plot_colorbar, xmaps, ymaps, xmap, ymap, param=aparam, scale=ascale, $
			panel_position=panel_position, /horizontal, ground=ground,      $
                        CONTINUOUS=continuous,WITH_INFO=with_info

	; plot an fan panel for each scan/parameter
	RAD_PSD_PLOT_SCAN_PANEL, xmaps, ymaps, xmap, ymap                       $
            ,DATE                       = date                                  $
            ,TIME                       = time                                  $
            ,LONG                       = long                                  $
            ,COORDS                     = coords                                $
            ,PARAM                      = aparam                                $
            ,XRANGE                     = xrange                                $
            ,YRANGE                     = yrange                                $
            ,SCALE                      = ascale                                $
;            ,SCAN_NUMBER                = ascan                                 $
            ,CHANNEL                    = channel                               $
            ,SCAN_ID                    = scan_id                               $
            ,SCAN_STARTJUL              = scan_startjul                         $
            ,/NO_FILL                                                           $
            ,FREQ_BAND                  = freq_band                             $
            ,SILENT                     = silent                                $
            ,CHARTHICK                  = charthick                             $
            ,CHARSIZE                   = charsize                              $
            ,VECTOR                     = vector                                $
            ,NO_FOV                     = no_fov                                $
            ,FIXED_LENGTH               = fixed_length                          $
            ,FIXED_COLOR                = fixed_color                           $
            ,ROTATE                     = rotate                                $
            ,SOUTH                      = south                                 $
            ,GROUND                     = ground                                $
            ,NO_PLOT_GND_SCATTER        = no_plot_gnd_scatter                   $
            ,POSITION                   = panel_position                        $
            ,SC_VALUES                  = sc_values                             $
            ,PREFFT                     = prefft                                $
            ,NO_DATA                    = no_data                               $
            ,ISOTROPIC                  = isotropic                             $
            ,WITH_INFO                  = with_info                             $
            ,SAVFILE                    = savFile

ENDFOR


IF ~KEYWORD_SET(no_title) THEN BEGIN
    IF KEYWORD_SET(no_data) THEN scan_startJul = jul
    IF KEYWORD_SET(preFFT) THEN BEGIN
        title$          = 'Pre-FFT RTI Parameter Plot'
    ENDIF ELSE BEGIN
        title$          = 'Integrated Power Spectral Density Plot'
    ENDELSE
    subTitle$       = JUL2STRING(scan_startjul)                         $
                    + ' (' + NUMSTR(1000*bandLim[0],1) + ' - ' $
                    + NUMSTR(1000*bandLim[1],1) + ' mHz)'
    PLOT_TITLE,title$,subTitle$
ENDIF

end
