;+ 
; NAME: 
; RAD_PSD_PLOT_SCAN_PANEL
; 
; PURPOSE: 
; This procedure plots a stereographic map grid and overlays coast
; lines and a scan of the currently loaded radar data.
; 
; CATEGORY:  
; Graphics
; 
; CALLING SEQUENCE: 
; RAD_FIT_PLOT_SCAN_PANEL
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
; SILENT: Set this keyword to surpress all messages/warnings.
;
; CHARTHICK: Set this keyword to change the font thickness.
;
; CHARSIZE: Set this keyword to change the font size. 
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
; POSITION: Set this keyword to a 4-element vector holding the normalized
; coordinates of the ouput panel. Use this to override internal positioning.
;
; FOV_LINESTYLE: Set this keyword to change the style of the field-of-view line.
; Default is 0 (solid).
;
; FOV_LINECOLOR: Set this keyword to a color index to change the color of the field-of-view line.
; Default is black.
;
; FOV_LINETHICK: Set this keyword to change the thickness of the field-of-view line.
; Default is 1.
;
; GRID_LINESTYLE: Set this keyword to change the style of the grid lines.
; Default is 0 (solid).
;
; GRID_LINECOLOR: Set this keyword to a color index to change the color of the grid lines.
; Default is black.
;
; GRID_LINETHICK: Set this keyword to change the thickness of the grid lines.
; Default is 1.
;
; COAST_LINESTYLE: Set this keyword to change the style of the coast line.
; Default is 0 (solid).
;
; COAST_LINECOLOR: Set this keyword to a color index to change the color of the coast line.
; Default is black.
;
; COAST_LINETHICK: Set this keyword to change the thickness of the coast line.
; Default is 1.
;
; LAND_FILLCOLOR: Set this keyword to the color index to use for filling land masses.
; Default is green (123).
;
; LAKE_FILLCOLOR: Set this keyword to the color index to use for filling lakes.
; Default is blue (20).
;
; HEMISPHERE: Set this keyword to one to plot the Northern hemisphere, -1 for Southern.
; Default is 1 (Northern).
;
; NO_FILL: Set this keyword to surpress filling of land masses and lakes with colors.
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
PRO RAD_PSD_PLOT_SCAN_PANEL, xmaps, ymaps, xmap, ymap                   $
    ,DATE                       = date                                  $
    ,TIME                       = time                                  $
    ,JUL                        = jul                                   $
    ,LONG                       = long                                  $
    ,PARAM                      = param                                 $
    ,CHANNEL                    = channel                               $
    ,SCAN_ID                    = scan_id                               $
    ,SCAN_NUMBER                = scan_number                           $
    ,SCAN_STARTJUL              = scan_startjul                         $
    ,COORDS                     = coords                                $
    ,XRANGE                     = xrange                                $
    ,YRANGE                     = yrange                                $
    ,SCALE                      = scale                                 $
    ,AUTORANGE                  = autorange                             $
    ,FREQ_BAND                  = freq_band                             $
    ,SILENT                     = silent                                $
    ,CHARTHICK                  = charthick                             $
    ,CHARSIZE                   = charsize                              $ 
    ,XTITLE                     = xtitle                                $
    ,YTITLE                     = ytitle                                $
    ,XTICKS                     = xticks                                $
    ,XMINOR                     = xminor                                $
    ,YTICKS                     = yticks                                $
    ,YMINOR                     = yminor                                $
    ,POSITION                   = position                              $
    ,FOV_LINESTYLE              = fov_linestyle                         $
    ,FOV_LINECOLOR              = fov_linecolor                         $
    ,FOV_LINETHICK              = fov_linethick                         $
    ,GRID_LINESTYLE             = grid_linestyle                        $
    ,GRID_LINECOLOR             = grid_linecolor                        $
    ,GRID_LINETHICK             = grid_linethick                        $
    ,COAST_LINESTYLE            = coast_linestyle                       $
    ,COAST_LINECOLOR            = coast_linecolor                       $
    ,COAST_LINETHICK            = coast_linethick                       $
    ,LAND_FILLCOLOR             = land_fillcolor                        $
    ,LAKE_FILLCOLOR             = lake_fillcolor                        $
    ,HEMISPHERE                 = hemisphere                            $
    ,ROTATE                     = rotate                                $
    ,NO_FILL                    = no_fill                               $
    ,NO_FOV                     = no_fov                                $
    ,VECTOR                     = vector                                $
    ,FIXED_LENGTH               = fixed_length                          $
    ,FIXED_COLOR                = fixed_color                           $
    ,NORTH                      = north                                 $
    ,SOUTH                      = south                                 $
    ,TITLE                      = title                                 $
    ,GROUND                     = ground                                $
    ,NO_PLOT_GND_SCATTER        = no_plot_gnd_scatter                   $
    ,SC_VALUES                  = sc_values                             $
    ,PREFFT                     = prefft                                $
    ,ISOTROPIC                  = isotropic                             $
    ,NO_DATA                    = no_data                               $
    ,WITH_INFO                  = with_info                             $
    ,SAVFILE                    = savFile

COMMON wave_blk

IF KEYWORD_SET(jul) THEN BEGIN
    caldat, jul, month, day, year, hh, ii
    date        = year*10000L + month*100L + day 
    time        = hh*100 + ii
END

IF ~KEYWORD_SET(param) THEN param = wave_dataproc_info.param

;if ~is_valid_parameter(param) then begin
;	prinfo, 'Invalid plotting parameter: '+param
;	return
;endif

if ~keyword_set(scan_id) then $
	scan_id = -1
;
;if n_elements(channel) eq 0 and scan_id eq -1 then begin
;		channel = (*rad_fit_info[data_index]).channels[0]
;endif

if ~keyword_set(freq_band) then $
	freq_band = [3.0, 30.0]

if n_params() lt 4 then begin
	if ~keyword_set(silent) and ~keyword_set(position) then $
		prinfo, 'XMAPS, YMAPS, XMAP and YMAP not set, using default.'
	xmaps = 1
	ymaps = 1
	xmap = 0
	ymap = 0
endif

if ~keyword_set(date) then begin
	if ~keyword_set(silent) then $
		prinfo, 'No DATE given, trying for scan date.'
	;caldat, (*rad_fit_data[data_index]).juls[0], month, day, year, hh, ii
	caldat, wave_dataproc_info.juls[0], month, day, year, hh, ii
	date = year*10000L + month*100L + day
	_time = hh*100 + ii
endif

IF N_ELEMENTS(date) NE 0 AND N_ELEMENTS(time) EQ 0 THEN _time = 1200

if n_elements(time) ne 0 then $
	_time = time

if ~keyword_set(scan_number) then $
	scan_number = -1

sfjul, date, _time, jul, long=long

if ~keyword_set(charsize) then $
	charsize = get_charsize(xmaps, ymaps)

if ~keyword_set(coords) then $
	coords = get_coordinates()

if ~is_valid_coord_system(coords) then begin
	prinfo, 'Invalid coordinate system: '+coords
	return
endif

; check coordinate system
if coords ne 'magn' and coords ne 'geog' and coords ne 'mlt' then begin
	prinfo, 'Coordinate system not supported: '+coords
	prinfo, 'Using magnetic coordinates.'
	coords = 'magn'
endif

if ~keyword_set(scale) then $
	scale = get_default_range(param)

if keyword_set(autorange) then $
	rad_calculate_map_coords, ids=wave_dataproc_info.id, coords=coords, $
		jul=jul, $
		xrange=xrange, yrange=yrange, rotate=rotate

if ~keyword_set(yrange) then $
	yrange = [-31,31]

if ~keyword_set(xrange) then $
	xrange = [-31,31]

aspect = float(xrange[1]-xrange[0])/float(yrange[1]-yrange[0])
if ~keyword_set(position) then $
	position = define_panel(xmaps, ymaps, xmap, ymap, aspect=aspect, WITH_INFO=with_info,/bar)

if ~keyword_set(grid_linethick) then $
	grid_linethick = 1

if n_elements(grid_linestyle) eq 0 then $
	grid_linestyle = 0

if n_elements(grid_linecolor) eq 0 then $
	grid_linecolor = get_gray()

if ~keyword_set(fov_linethick) then $
	fov_linethick = 1

if n_elements(fov_linestyle) eq 0 then $
	fov_linestyle = 0

if n_elements(fov_linecolor) eq 0 then $
	fov_linecolor = get_gray()

if ~keyword_set(coast_linethick) then $
	coast_linethick = 3

if n_elements(coast_linestyle) eq 0 then $
	coast_linestyle = 0

if n_elements(coast_linecolor) eq 0 then $
	coast_linecolor = get_gray()

if n_elements(land_fillcolor) eq 0 then $
	land_fillcolor = 123

if n_elements(lake_fillcolor) eq 0 then $
	lake_fillcolor = 20

if ~keyword_set(hemisphere) then begin
  if keyword_set(north) then $
    hemisphere = 1. $
  else if keyword_set(south) then $
    hemisphere = -1. $
  else $
    hemisphere = 1.
endif

map_plot_panel, xmaps, ymaps, xmap, ymap, $
	date=date, time=_time, long=long, $
	coords=coords, xrange=xrange, yrange=yrange, $
	silent=silent, $
	charthick=charthick, charsize=charsize, $ 
	xtitle=xtitle, ytitle=ytitle, $
	xticks=xticks, xminor=xminor, yticks=yticks, yminor=yminor, $
	position=position, $
	grid_linestyle=grid_linestyle, grid_linecolor=grid_linecolor, $
	grid_linethick=grid_linethick, $
	coast_linestyle=coast_linestyle, coast_linecolor=coast_linecolor, $
	coast_linethick=coast_linethick, $
	land_fillcolor=land_fillcolor, lake_fillcolor=lake_fillcolor, $
	hemisphere=hemisphere, rotate=rotate, no_fill=no_fill, /no_axis, south=south,   $
        ISOTROPIC = isotropic

IF ~KEYWORD_SET(no_data) THEN BEGIN
    RAD_PSD_OVERLAY_SCAN, scan_number                                       $
        ,COORDS                     = coords                                $
        ,JUL                        = jul                                   $
        ,PARAM                      = param                                 $
        ,CHANNEL                    = channel                               $
        ,SCAN_ID                    = scan_id                               $
        ,ROTATE                     = rotate                                $
        ,SCAN_STARTJUL              = scan_startjul                         $
        ,SCALE                      = scale                                 $
        ,VECTOR                     = vector                                $
        ,GROUND                     = ground                                $
        ,FIXED_LENGTH               = fixed_length                          $
        ,FIXED_COLOR                = fixed_color                           $
        ,NO_PLOT_GND_SCATTER        = no_plot_gnd_scatter                   $
        ,SC_VALUES                  = sc_values                             $
        ,PREFFT                     = preFFT                                $
        ,SAVFILE                    = savFile
ENDIF

;if ~keyword_set(no_fov) then $
;	overlay_fov, coords=coords, jul=jul, $
;		fov_linestyle=fov_linestyle, fov_linecolor=fov_linecolor, $
;		fov_linethick=fov_linethick, fov_fillcolor=fov_fillcolor, $
;		rotate=rotate, /no_fill

; Plot axis
map_plot_panel, xmaps, ymaps, xmap, ymap, $
	date=date, time=_time, long=long, $
	coords=coords, xrange=xrange, yrange=yrange, $
	silent=silent, $
	charthick=charthick, charsize=charsize, $ 
	xtitle=xtitle, ytitle=ytitle, $
	xticks=xticks, xminor=xminor, yticks=yticks, yminor=yminor, $
	position=position, $
	/no_coast, /no_label, /no_grid, $
	hemisphere=hemisphere, rotate=rotate, south=south,      $
        ISOTROPIC = isotropic

; returned the actually used scan_id
;if scan_id eq -1 then begin
;	bmno = rad_fit_find_scan(scan_startjul)
;	if bmno eq -1L then $
;		return
;	inds = where((*rad_fit_data[data_index]).beam_scan eq bmno, cc)
;	if cc eq 0L then $
;		return
;	scan_id = (*rad_fit_data[data_index]).scan_id[inds[0]]
;endif

end
