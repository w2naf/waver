;+
; NAME:
; RAD_FIT_PLOT_RTI_PANEL
;
; PURPOSE:
;
; CATEGORY:
; Graphics
;
; CALLING SEQUENCE:
; RAD_FIT_PLOT_RTI_PANEL
;
; OPTIONAL INPUTS:
; Xmaps: The total number of columns of plots on the resulting page.
; Default is 1.
;
; Ymaps: The total number of rows of plots on the resulting page.
; Default is 1.
;
; Xmap: The current horizontal (column) index of this panel.
; Default is 0.
;
; Ymap: The current vertical (row) index of this panel.
; Default is 0.
;
; KEYWORD PARAMETERS:
; DATE: A scalar or 2-element vector giving the time range to plot,
; in YYYYMMDD or MMMYYYY format.
;
; TIME: A 2-element vector giving the time range to plot, in HHII format.
;
; LONG: Set this keyword to indicate that the TIME value is in HHIISS
; format rather than HHII format.
;
; PARAM: Set this keyword to specify the parameter to plot. Allowable
; values are 'power', 'velocity', and 'width'. Default is 'power'.
;
; BEAM: Set this keyword to specify the beam number from which to plot
; the time series.
;
; CHANNEL: Set this keyword to the channel number you want to plot.
;
; SCAN_ID: Set this keyword to the numeric scan id you want to plot.
;
; COORDS: Set this keyword to a string naming the coordinate system
; of the y axis. Allowable inputs are 'mag', 'geo', 'rang' and 'gate'.
; Default is 'gate'.
;
; YRANGE: Set this keyword to change the range of the y axis.
;
; SCALE: Set this keyword to change the scale of the plotted values.
;
; SILENT: Set this keyword to surpress all messages/warnings.
;
; CHARTHICK: Set this keyword to change the font thickness.
;
; CHARSIZE: Set this keyword to change the font size.
;
; XSTYLE: Set this keyword to change the style of the x axis.
;
; YSTYLE: Set this keyword to change the style of the y axis.
;
; XTITLE: Set this keyword to change the title of the x axis.
;
; YTITLE: Set this keyword to change the title of the y axis.
;
; XTICKS: Set this keyword to change the number of major x tick marks.
;
; XMINOR: Set this keyword to change the number of minor x tick marks.
;
; YTICKS: Set this keyword to change the number of major y tick marks.
;
; YMINOR: Set this keyword to change the number of minor y tick marks.
;
; FREQ_BAND: Set this keyword to a 2-element vector indicating the
; frequency pass band you wish to plot.
;
; BAR: Set this keyword to allow for space right of the panel for a colorbar.
;
; XTICKFORMAT: Set this keyword to a format code to use for formatting of
; the time axis labels. See IDL documentation for LABEL_DATE.
;
; YTICKFORMAT: Set this to a format code to use for the y axis tick labels.
;
; POSITION: Set this keyword to a 4-element vector holding the normalized
; coordinates of the ouput panel. Use this to override internal positioning.
;
; FIRST: Set this keyword to indicate that this panel is the first panel in
; a ROW of plots. That will force Y axis labels.
;
; LAST: Set this keyword to indicate that this is the last panel in a COLUMN of plots.
; That will force X axis labels.
;
; WITH_INFO: Set this keyword to leave some extra space on the top for plotting noise
; and frequency info panels.
;
; TITLE: Set this keyword to a string to put a title above the plotted panel. 
; This is a different title than the one created by PLOT_TITLE or RAD_FIT_PLOT_TITLE.
;
; EXCLUDE: Set this keyword to a 2-element vector to specify the lower and upper cutoff.
; Setting this to [0,30] will only plot values greater than 0 and smaller than 30.
;
; MIN_POWER: Set this to the minimum power value. If a data point is associated with a 
; smaller power value than this one, omit plotting it. Default is 0.
;
; SUN: Set this keyword to overplot sunrise, sunset and solar noon times.
;
; SCATTERFLAG: Overrides default stored in common block.
;       0: plot all backscatter data 
;       1: plot ground backscatter only 
;       2: plot ionospheric backscatter only 
;       3: plot all backscatter data with a ground backscatter flag.
;
; COMMON BLOCKS:
; RAD_DATA_BLK: The common block holding radar data.
;
; EXAMPLE:
;
; COPYRIGHT:
; MODIFICATION HISTORY:
; Based on Steve Milan's PLOT_RTI.
; Written by Lasse Clausen, Nov, 24 2009
;-
pro rad_fit_plot_rti_trace_panel, xmaps, ymaps, xmap, ymap                            $
    ,date               = date                                                  $
    ,time               = time                                                  $
    ,long               = long                                                  $
    ,param              = param                                                 $
    ,beam               = beam                                                  $
    ,channel            = channel                                               $
    ,scan_id            = scan_id                                               $
    ,coords             = coords                                                $
    ,yrange             = yrange                                                $
    ,scale              = scale                                                 $
    ,freq_band          = freq_band                                             $
    ,silent             = silent                                                $
    ,bar                = bar                                                   $
    ,charthick          = charthick                                             $
    ,charsize           = charsize                                              $
    ,xstyle             = xstyle                                                $
    ,ystyle             = ystyle                                                $
    ,xtitle             = xtitle                                                $
    ,ytitle             = ytitle                                                $
    ,xticks             = xticks                                                $
    ,xminor             = xminor                                                $
    ,yticks             = yticks                                                $
    ,yminor             = yminor                                                $
    ,xtickformat        = xtickformat                                           $
    ,ytickformat        = ytickformat                                           $
    ,xtickname          = xtickname                                             $
    ,ytickname          = ytickname                                             $
    ,position           = position                                              $
    ,ground             = ground                                                $
    ,grid               = grid                                                  $
    ,last               = last                                                  $
    ,first              = first                                                 $
    ,with_info          = with_info                                             $
    ,no_title           = no_title                                              $
    ,SCATTERFLAG        = _scatterflag                                          $
    ,title              = title                                                 $
    ,exclude            = exclude                                               $
    ,sc_values          = sc_values                                             $
    ,min_power          = min_power                                             $
    ,sun                = sun

common rad_data_blk

; get index for current data
data_index = rad_fit_get_data_index()
if data_index eq -1 then $
	return

if (*rad_fit_info[data_index]).nrecs eq 0L then begin
	if ~keyword_set(silent) then begin
		prinfo, 'No data in index '+string(data_index)
		rad_fit_info
	endif
	return
endif

if ~keyword_set(param) then $
	param = get_parameter()

if ~is_valid_parameter(param) then begin
	prinfo, 'Invalid plotting parameter: '+param
	return
endif

if n_elements(beam) eq 0 then $
	beam = rad_get_beam()

if ~keyword_set(coords) then $
	coords = get_coordinates()

if ~is_valid_coord_system(coords) then begin
	prinfo, 'Not a valid coordinate system: '+coords
	prinfo, 'Using gate.'
	coords = 'gate'
endif

if ~keyword_set(freq_band) then $
	freq_band = get_default_range('tfreq')
if n_params() lt 4 then begin
	if ~keyword_set(silent) and ~keyword_set(position) then $
		prinfo, 'XMAPS, YMAPS, XMAP and YMAP not set, using default.'
	xmaps = 1
	ymaps = 1
	xmap = 0
	ymap = 0
endif
if ~keyword_set(position) then $
	position = define_panel(xmaps, ymaps, xmap, ymap, bar=bar, with_info=with_info, no_title=no_title)

if ~keyword_set(date) then begin
	if ~keyword_set(silent) then $
		prinfo, 'No DATE given, trying for scan date.'
	caldat, (*rad_fit_data[data_index]).juls[0], month, day, year
	date = year*10000L + month*100L + day
endif

if ~keyword_set(time) then $
	time = [0000,2400]

sfjul, date, time, sjul, fjul, long=long
xrange = [sjul, fjul]

if n_elements(xtitle) eq 0 then $
	_xtitle = 'Time UT' $
else $
	_xtitle = xtitle

if n_elements(xtickformat) eq 0 then $
	_xtickformat = 'label_date' $
else $
	_xtickformat = xtickformat

if n_elements(xtickname) eq 0 then $
	_xtickname = '' $
else $
	_xtickname = xtickname

if n_elements(ytitle) eq 0 then $
	_ytitle = get_default_title(coords) $
else $
	_ytitle = ytitle

if n_elements(ytickformat) eq 0 then $
	_ytickformat = '' $
else $
	_ytickformat = ytickformat

if n_elements(ytickname) eq 0 then $
	_ytickname = '' $
else $
	_ytickname = ytickname

if ~keyword_set(scan_id) then $
	scan_id = -1

if ~keyword_set(ground) then $
	ground = -1

if n_elements(channel) eq 0 and scan_id eq -1 then begin
	channel = (*rad_fit_info[data_index]).channels[0]
endif

if ~keyword_set(xstyle) then $
	xstyle = 1

if ~keyword_set(ystyle) then $
	ystyle = 1

if ~keyword_set(charsize) then $
	charsize = get_charsize(xmaps, ymaps)

if ~keyword_set(scale) then begin
	if strcmp(get_parameter(), param) then $
		scale = get_scale() $
	else $
		scale = get_default_range(param)
endif

if ~keyword_set(yrange) then $
	yrange = get_default_range(coords)

if ~keyword_set(xticks) then $
	_xticks = get_xticks(sjul, fjul, xminor=_xminor) $
else $
	_xticks = xticks

if keyword_set(xminor) then $
	_xminor = xminor

if n_elements(min_power) eq 0 then $
	min_power = 0.

; Determine maximum width to plot scan - to decide how big a 'data gap' has to
; be before it really is a data gap.  Default to 5 minutes
if ~keyword_set(max_gap) then $
	max_gap = 2.5

; set up coordinate system for plot
plot, [0,0], /nodata, xstyle=5, ystyle=5, $
	yrange=yrange, xrange=xrange, position=position

; get data
xtag = 'juls'
ytag = param
if ~tag_exists((*rad_fit_data[data_index]), xtag) then begin
	if ~keyword_set(silent) then $
		prinfo, 'Parameter '+xtag+' does not exist in RAD_FIT_DATA.'
	return
endif
if ~tag_exists((*rad_fit_data[data_index]), ytag) then begin
	if ~keyword_set(silent) then $
		prinfo, 'Parameter '+ytag+' does not exist in RAD_FIT_DATA.'
	return
endif
s = execute('xdata = (*rad_fit_data[data_index]).'+xtag)
s = execute('ydata = (*rad_fit_data[data_index]).'+ytag)

; get power if min_power keyword is set
if min_power gt 0. then $
	pwr = (*rad_fit_data[data_index]).power

; select data to plot
; must fit beam, channel, scan_id, time (roughly) and frequency
;
; check first whether data is available for the user selection
; then find data to actually plot
beam_inds = where((*rad_fit_data[data_index]).beam eq beam, cc)
if cc eq 0 then begin
	if ~keyword_set(silent) then $
		prinfo, 'No data found for beam '+string(beam)
	return
endif
txdata = xdata[beam_inds]
tchann = (*rad_fit_data[data_index]).channel[beam_inds]
ttfreq = (*rad_fit_data[data_index]).tfreq[beam_inds]
tscani = (*rad_fit_data[data_index]).scan_id[beam_inds]
if n_elements(channel) ne 0 then begin
	scch_inds = where(tchann eq channel, cc)
	if cc eq 0 then begin
		if ~keyword_set(silent) then $
			prinfo, 'No data found for for beam '+string(beam)+$
				' and channel '+string(channel)
		return
	endif
endif else if scan_id ne -1 then begin
	if scan_id eq -1 then $
		return
	scch_inds = where(tscani eq scan_id, cc)
	if cc eq 0 then begin
		if ~keyword_set(silent) then $
			prinfo, 'No data found for for beam '+string(beam)+$
				' and scan_id '+string(scan_id)
		return
	endif
endif
tchann = 0
tscani = 0
txdata = txdata[scch_inds]
ttfreq = ttfreq[scch_inds]
juls_inds = where(txdata ge sjul-10.d/1440.d and txdata le fjul+10.d/1440.d, cc)
if cc eq 0 then begin
	if ~keyword_set(silent) then $
		prinfo, 'No data found for beam '+string(beam)+$
			' and time '+format_time(time)
	return
endif
txdata = 0
ttfreq = ttfreq[juls_inds]
tfre_inds = where(ttfreq*0.001 ge freq_band[0] and ttfreq*0.001 le freq_band[1], cc)
if cc eq 0 then begin
	if ~keyword_set(silent) then $
		prinfo, 'No data found for beam '+string(beam)+$
			' and channel '+string(channel)+' and time '+format_time(time) + $
			' and freq. band '+strjoin(string(freq_band,format='(F4.1)'),'-')
	return
endif
ttfreq = 0

; get indeces of data to plot
if n_elements(channel) ne 0 then begin
	beam_inds = where((*rad_fit_data[data_index]).beam eq beam and $
		(*rad_fit_data[data_index]).channel eq channel and $
		(*rad_fit_data[data_index]).juls ge sjul-10.d/1440.d and $
		(*rad_fit_data[data_index]).juls le fjul+10.d/1440.d and $
		(*rad_fit_data[data_index]).tfreq*0.001 ge freq_band[0] and $
		(*rad_fit_data[data_index]).tfreq*0.001 le freq_band[1], $
		nbeam_inds)
endif else if scan_id ne -1 then begin
	beam_inds = where((*rad_fit_data[data_index]).beam eq beam and $
		(*rad_fit_data[data_index]).scan_id eq scan_id and $
		(*rad_fit_data[data_index]).juls ge sjul-10.d/1440.d and $
		(*rad_fit_data[data_index]).juls le fjul+10.d/1440.d and $
		(*rad_fit_data[data_index]).tfreq*0.001 ge freq_band[0] and $
		(*rad_fit_data[data_index]).tfreq*0.001 le freq_band[1], $
		nbeam_inds)
endif

old_lagfr = (*rad_fit_data[data_index]).lagfr[beam_inds[0]]
old_smsep = (*rad_fit_data[data_index]).smsep[beam_inds[0]]

; check if interferometer data is plotted, whether it is available
if strcmp(param, 'phi0', /fold) or strcmp(param, 'elevation', /fold) then begin
	dummy = where( (*rad_fit_data[data_index]).xcf[beam_inds] gt 0b, xcc )
	if xcc lt 2L then begin
		prinfo, 'No interferometer data for this time.'
		return
	endif
endif

; get color preferences
foreground  = get_foreground()

; and some user preferences
IF N_ELEMENTS(_scatterflag) EQ 0 THEN scatterflag = rad_get_scatterflag() ELSE scatterflag = _scatterflag

; shift/rotate color indeces if param is velocity
;rot = 0
;shi = 0
;IF param EQ 'velocity' then begin
;	if strcmp(get_colortable(), 'bluewhitered', /fold) or strcmp(get_colortable(), 'leicester', /fold) or strcmp(get_colortable(), 'default', /fold) THEN $
;		rot = 1
;	if strcmp(get_colortable(), 'aj', /fold) or strcmp(get_colortable(), 'bw', /fold) or strcmp(get_colortable(), 'whitered', /fold) THEN $
;		shi = 1
;endif

ajul = (sjul+fjul)/2.d
caldat, ajul, mm, dd, year
yrsec = (ajul-julday(1,1,year,0,0,0))*86400.d

CASE coords OF
    'mix_rang': gsCoords = 'gs_rang'
    'mix_geog': gsCoords = 'gs_geog'
    'mix_magn': gsCoords = 'gs_magn'
          ELSE: gsCoords = coords
ENDCASE

IF (coords EQ 'gs_rang')  OR (coords EQ 'gs_geog')  OR (coords EQ 'gs_magn')    $
OR (coords EQ 'mix_rang') OR (coords EQ 'mix_geog') OR (coords EQ 'mix_magn')   $
    THEN gsMapping = 1 ELSE gsMapping = 0

RAD_DEFINE_BEAMS                                                                $
    ,(*rad_fit_info[data_index]).id                                             $
    ,(*rad_fit_info[data_index]).nbeams                                         $
    ,(*rad_fit_info[data_index]).ngates                                         $
    ,year                                                                       $
    ,yrsec                                                                      $
    ,coords             = coords                                                $
    ,lagfr0             = (*rad_fit_data[data_index]).lagfr[beam_inds[0]]       $
    ,smsep0             = (*rad_fit_data[data_index]).smsep[beam_inds[0]]       $
    ,fov_loc_full       = fov_loc_full                                          $
    ,fov_loc_center     = fov_loc_center

RAD_DEFINE_BEAMS                                                                $
    ,(*rad_fit_info[data_index]).id                                             $
    ,(*rad_fit_info[data_index]).nbeams                                         $
    ,(*rad_fit_info[data_index]).ngates                                         $
    ,year                                                                       $
    ,yrsec                                                                      $
    ,coords             = gsCoords                                              $
    ,lagfr0             = (*rad_fit_data[data_index]).lagfr[beam_inds[0]]       $
    ,smsep0             = (*rad_fit_data[data_index]).smsep[beam_inds[0]]       $
    ,fov_loc_full       = gs_fov_loc_full                                       $
    ,fov_loc_center     = gs_fov_loc_center

; overplot data
; Cycle through beams to plot

dataArr = FLTARR(nbeam_inds-1,(*rad_fit_info[data_index]).nGates)
clrArr  = FLTARR(nbeam_inds-1,(*rad_fit_info[data_index]).nGates)
dataXVec = DBLARR(nbeam_inds-1)
dataYVec = FLTARR((*rad_fit_info[data_index]).nGates)

dataArr[*] = !VALUES.F_NAN
clrArr[*]  = GET_BACKGROUND()

FOR b=0L, nbeam_inds-2L DO BEGIN
	; If lag to first range or gate length has changed then update
	; field-of-view info
	IF ((*rad_fit_data[data_index]).lagfr[beam_inds[b]] NE old_lagfr)                       $
        OR ((*rad_fit_data[data_index]).smsep[beam_inds[b]] NE old_smsep) THEN BEGIN
		RAD_DEFINE_BEAMS                                                                $
                    ,(*rad_fit_info[data_index]).id                                             $
                    ,(*rad_fit_info[data_index]).nbeams                                         $
		    ,(*rad_fit_info[data_index]).ngates                                         $
                    ,year                                                                       $
                    ,yrsec                                                                      $
                    ,coords             = coords                                                $
		    ,lagfr0             = (*rad_fit_data[data_index]).lagfr[beam_inds[b]]       $
                    ,smsep0             = (*rad_fit_data[data_index]).smsep[beam_inds[b]]       $
		    ,fov_loc_full       = fov_loc_full                                          $
                    ,fov_loc_center     = fov_loc_center

		RAD_DEFINE_BEAMS                                                                $
                    ,(*rad_fit_info[data_index]).id                                             $
                    ,(*rad_fit_info[data_index]).nbeams                                         $
		    ,(*rad_fit_info[data_index]).ngates                                         $
                    ,year                                                                       $
                    ,yrsec                                                                      $
                    ,coords             = gsCoords                                              $
		    ,lagfr0             = (*rad_fit_data[data_index]).lagfr[beam_inds[b]]       $
                    ,smsep0             = (*rad_fit_data[data_index]).smsep[beam_inds[b]]       $
		    ,fov_loc_full       = gs_fov_loc_full                                       $
                    ,fov_loc_center     = gs_fov_loc_center

		old_lagfr = (*rad_fit_data[data_index]).lagfr[beam_inds[b]]
		old_smsep = (*rad_fit_data[data_index]).smsep[beam_inds[b]]
	ENDIF

	start_time = xdata[beam_inds[b]]
	; check for data gaps
	if xdata[beam_inds[b+1]] gt start_time+max_gap/1440.d then $
		; make this point 1 minute long, just for default reasons
		end_time = start_time+1./1440.d $
	else $
		end_time = xdata[beam_inds[b+1]]

	; check for freaky time travel scenario, as ETS calls it....
	if end_time lt start_time then begin
		prinfo, 'EndTime < StartTime: '+format_juldate(start_time, /time)+'->'+format_juldate(end_time, /time)
		end_time = start_time+1./1440.d
	endif

	; cycle through ranges
	FOR r=0, (*rad_fit_info[data_index]).ngates-1 DO BEGIN
                plt = 1
                gs = (*rad_fit_data[data_index]).gscatter[beam_inds[b],r]

                IF KEYWORD_SET(gsMapping) AND KEYWORD_SET(gs) THEN BEGIN
                    IF (ABS(gs_fov_loc_center[0,beam,r+1]) LT ABS(yrange[0]))                           $
                    OR (ABS(gs_fov_loc_center[0,beam,r])   GT ABS(yrange[1])) THEN plt = 0
                ENDIF ELSE BEGIN
                    IF (ABS(fov_loc_center[0,beam,r+1]) LT ABS(yrange[0]))                              $
                    OR (ABS(fov_loc_center[0,beam,r])   GT ABS(yrange[1])) THEN plt = 0
                ENDELSE

		; only plot points with real data in it
		IF ydata[beam_inds[b],r] eq 10000. THEN $
			plt=0

		; only plot values above power threshold
		if min_power gt 0. then $
			if pwr[beam_inds[b],r] lt min_power then $
				plt=0

		; check whether to exclude values
		if n_elements(exclude) eq 2 then begin
			if ydata[beam_inds[b],r] lt exclude[0] or ydata[beam_inds[b],r] gt exclude[1] then $
				plt=0
		endif

		; if only plotting ground scatter, skip all points where
		; the gscatter flag is not 1
		IF scatterflag EQ 1 AND gs NE 1 THEN plt=0

		; if only plotting ionospheric scatter, skip all points where
		; the gscatter flag is 1
		IF scatterflag EQ 2 AND gs EQ 1 THEN plt=0

		; if scatter flag is 3, plot ground scatter in gray
		; only for velocity, though
		IF param EQ 'velocity' AND ( ( scatterflag EQ 3 AND $
			(*rad_fit_data[data_index]).gscatter[beam_inds[b],r] EQ 1 ) or abs(ydata[beam_inds[b],r]) lt ground ) THEN $
				col = get_gray() $
		ELSE $
			col = get_color_index(ydata[beam_inds[b],r], param=param, scale=scale, sc_values=sc_values)

		;print, b, r, ydata[beam_inds[b],r], col
		;print, scale, sc_values

		; finally plot the point
                avgTime         = (start_time + end_time)/2.
                dataXVec[b]     = (start_time + end_time)/2.
                IF KEYWORD_SET(gsMapping) AND gs EQ 1 THEN BEGIN
                    dataYVec[r]     = (gs_fov_loc_center[0,beam,r+1] + gs_fov_loc_center[0,beam,r]) / 2.
                ENDIF ELSE BEGIN
                    dataYVec[r]     = (fov_loc_center[0,beam,r+1] + fov_loc_center[0,beam,r]) / 2.
                ENDELSE


                IF KEYWORD_SET(plt) THEN BEGIN
                    clrArr[b,r]     = col
                    dataArr[b,r]    = ydata[beam_inds[b],r] 
                ENDIF
	ENDFOR

	; check whether we have a change of scan id
	if (*rad_fit_data[data_index]).scan_id[beam_inds[b]] ne (*rad_fit_data[data_index]).scan_id[beam_inds[b+1L]] then begin
		oplot, replicate(end_time, 2), !y.crange, linestyle=2, thick=!p.thick, color=get_gray()
	endif

	; check whether we have a change of hf/if mode
	if (*rad_fit_data[data_index]).ifmode[beam_inds[b]] ne (*rad_fit_data[data_index]).ifmode[beam_inds[b+1L]] then begin
		oplot, replicate(end_time, 2), !y.crange, linestyle=2, thick=!p.thick, color=get_gray()
	endif

ENDFOR

;Make sure the range vector is monotonic.  It can become non-monotonic when looking at
;ionospheric and turning-point footpoint ranges simultaneously.
srt     = SORT(dataYvec)
dataYvec        = dataYvec[srt]
dataArr         = dataArr[*,srt]
clrArr          = clrArr[*,srt]

;Remove invalid (negative) ranges.
good = WHERE(dataYvec GE 0, cnt)
IF cnt GT 0 THEN BEGIN
    dataYvec    = dataYvec[good]
    dataArr     = dataArr[*,good]
    clrArr      = clrArr[*,good]
ENDIF

;Add on extra element for x/y vectors for the draw image routine.
dxVec   = SHIFT(dataXvec,-1) - dataXVec
nDx     = N_ELEMENTS(dxVec)
dxAvg   = MEAN(dxVec[0:nDx-2])
dataXdi = [dataXvec, dataXvec[nDx-1]+dxAvg]


dyVec   = SHIFT(dataYvec,-1) - dataYvec
nDy     = N_ELEMENTS(dyVec)
dyAvg   = MEAN(dyVec[0:nDy-2])
dataYdi = [dataYvec, dataYvec[nDy-1]+dyAvg]

;Draw RTI data.
DRAW_IMAGE,clrArr,dataXdi,dataYdi,/OVERLAY,/NO_SCALE

;CONTOUR,dataArr,dataXVec,dataYVec                               $
;    ,LEVELS     = [18.]                                         $
;    ,/CLOSED                                                    $
;    ,/PATH_DATA_COORDS                                          $
;    ,PATH_INFO  = pathinfo                                     $
;    ,PATH_XY    = pathxy                                       $
;    ,/OVERPLOT

;Scatter Plot Range
scRang  = [29,60]

nx      = N_ELEMENTS(dataXVec)
ny      = N_ELEMENTS(dataYVec)

dataXArr        = DBLARR(nx,ny)
dataYArr        = FLTARR(nx,ny)

FOR nn=0,ny-1 DO dataXarr[*,nn] = dataXVec
FOR nn=0,nx-1 DO dataYarr[nn,*] = dataYVec

good            = WHERE(dataArr GE scRang[0] AND dataArr LE scRang[1],cnt)
IF cnt GT 0 THEN BEGIN
    scatX       = dataXArr[good]
    scatY       = dataYArr[good]

    srt         = SORT(scatX)
    scatX       = scatX[srt]
    scatY       = scatY[srt]

    ;OPLOT,scatX,scatY,PSYM=6,SYMSIZE=0.5
ENDIF

;UT0     = [1400, 1425, 1435, 1510]
;rn0     = [ 900,  757,  900,  900]
;UT1     = [1415, 1434, 1500, 1555]
;rn1     = [ 700,  659,  650,  600]

UT0     = [1425, 1435, 1510]
rn0     = [ 757,  900,  900]
UT1     = [1434, 1500, 1555]
rn1     = [ 659,  700,  600]

SFJUL,ddate,ttime,xrange[0],/JUL_TO_DATE
FOR kk=0,N_ELEMENTS(UT0)-1 DO BEGIN
    SFJUL,[ddate,ddate],[UT0[kk],UT1[kk]],x0,x1

    y0  = rn0[kk]
    y1  = rn1[kk]

    m   = (y0-y1)/(x0-x1)
    b   = -m*x1 + y1

    yy  = m*dataXVec + b

    OPLOT,dataXVec,yy,THICK=10
ENDFOR


;sUT     = [1400, 1410, 1440, 1510, 1530]
;eUT     = [1420, 1440, 1510, 1530, 1555]
;
;SFJUL,ddate,ttime,xrange[0],/JUL_TO_DATE
;FOR kk=0,N_ELEMENTS(sUT)-1 DO BEGIN
;    SFJUL,[ddate,ddate],[sUT[kk],eUT[kk]],ssJul,eeJul
;
;    inxOI = WHERE(scatX GE ssJul AND scatX LE eeJul,cnt)
;    IF cnt GT 0 THEN BEGIN
;        xOI     = scatX[inxOI]
;        yOI     = scatY[inxOI]
;        OPLOT,xOI,yOI,PSYM=6,SYMSIZE=0.2
;
;        lf      = LINFIT(xOI,yOI,CHISQ=chiSq,MEASURE_ERRORS=mErr)
;        
;;        dur     = eeJul - ssJul
;;        nMin    = CEIL(dur * 1440.)
;;        linJul  = dur * (DINDGEN(nMin) / (nMin-1)) + ssJul
;        linY    = lf[0] + lf[1]*dataXVec
;
;        OPLOT,dataXVec,linY,THICK=10
;    ENDIF
;ENDFOR


; plot sunrise/sunset/solar noon
if keyword_set(sun) then begin
	rad_calc_sunset, date, (*rad_fit_info[data_index]).code, beam, (*rad_fit_info[data_index]).ngates, $
		risetime=risetime, settime=settime, solnoon=solnoon
	oplot, risetime, fov_loc_center[0,beam,*], linestyle=2, thick=!p.thick
	oplot, settime, fov_loc_center[0,beam,*], linestyle=2, thick=!p.thick
	oplot, solnoon, fov_loc_center[0,beam,*], linestyle=2, thick=!p.thick
endif

;IF param EQ 'velocity' then $
;	rad_load_colortable

; check if format is sardines.
; if yes, loose the x axis information
; unless it is given
fmt = get_format(sardines=sd, tokyo=ty)
if sd and ~keyword_set(last) then begin
	if ~keyword_set(xtitle) then $
		_xtitle = ' '
	if ~keyword_set(xtickformat) then $
		_xtickformat = ''
	if ~keyword_set(xtickname) then $
		_xtickname = replicate(' ', 60)
endif
if ty and ~keyword_set(first) then begin
	if ~keyword_set(ytitle) then $
		_ytitle = ' '
	if ~keyword_set(ytickformat) then $
		_ytickformat = ''
	if ~keyword_set(ytickname) then $
		_ytickname = replicate(' ', 60)
endif

; Overlay grid if required
if keyword_set(grid) then begin
	_gridstyle = 1
	_xticklen = 1.
	_yticklen = 1.
endif else begin
	_xticklen = -.02;-!x.ticklen
	_yticklen = -.02;-!y.ticklen
endelse

; "over"plot axis
plot, [0,0], /nodata, position=position, $
	charthick=charthick, charsize=charsize, $
	yrange=yrange, xrange=xrange, $
	xstyle=xstyle, ystyle=ystyle, xtitle=_xtitle, ytitle=_ytitle, $
	xticks=_xticks, xminor=_xminor, yticks=yticks, yminor=yminor, $
	xtickformat=_xtickformat, ytickformat=_ytickformat, $
	xtickname=_xtickname, ytickname=_ytickname, $
	color=get_foreground(), title=title, $
	xticklen=_xticklen, yticklen=_xticklen, $
	xgridstyle=_gridstyle, ygridstyle=_gridstyle

end
