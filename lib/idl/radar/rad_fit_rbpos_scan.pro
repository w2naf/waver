FUNCTION RAD_FIT_RBPOS_SCAN, scan_number                                    $
            ,DATE                 = date                                    $
            ,TIME                 = time                                    $
            ,JUL                  = jul                                     $
            ,HEIGHT               = height                                  $
            ,FIX_HEIGHT           = fix_height                              $
            ,CENTER               = center                                  $
            ,NO_GS_ADJUSTMENT     = no_gs_adjustment                        $
            ,ALWAYS_GS_ADJUSTMENT = always_gs_adjustment                    $
            ,COORDS               = coords

COMMON radarinfo, network
COMMON rad_data_blk

IF N_ELEMENTS(height) EQ 0 THEN h = 300. ELSE h = height

IF ~KEYWORD_SET(coords) THEN _coords = GET_COORDINATES()
CASE _coords OF
    'geog':     mgflag = 0
    'magn':     mgflag = 1
      ELSE: BEGIN
                PRINFO,"Current coordinate system is: '"+_coords+"'."
                PRINFO,"This does not work.  Therefore, I'm choosing 'magn'."
                mgflag = 1
            END
ENDCASE

inx             = RAD_FIT_GET_DATA_INDEX()

IF N_ELEMENTS(scan_number) EQ 0 THEN BEGIN
        IF ~KEYWORD_SET(date) THEN BEGIN
                caldat, (*rad_fit_info[inx]).sjul, mm, dd, yy
                date = yy*10000L + mm*100L + dd
        ENDIF
        IF  N_ELEMENTS(time) EQ 0 THEN time = 1200
        IF ~KEYWORD_SET(jul) THEN SFJUL, date, time, jul 
        scan_number = RAD_FIT_FIND_SCAN(jul, CHANNEL=channel, SCAN_ID=scan_id)
        IF scan_number EQ -1L THEN RETURN,-1
ENDIF

scanInx         = WHERE( (*rad_fit_data[inx]).beam_scan EQ scan_number)
st_id           = (*RAD_FIT_INFO[inx]).id
juls            = (*rad_fit_data[inx]).juls[scanInx]

;Pull out all necessary date/time variables.
jul             = MIN(juls)
CALDAT,jul,month,day,year,hour,min,sec
yrSec           = (JUL2YRYRSEC(jul))[1]

;Load in hdw.dat data for appropriate radar.
rid             = RadarGetRadar(network,st_id)
site            = RadarYMDHMSGetSite(rid,year,month,day,hour,min,sec)

;Make it easy to get to parameters needed for location determination.
lagfrVec        = (*rad_fit_data[inx]).lagfr[scanInx]
smsepVec        = (*rad_fit_data[inx]).smsep[scanInx]
bmSep           = (*rad_fit_info[inx]).bmsep
rxrise          = site.recrise

;Determine beams and gates 
beamVec     = (*rad_fit_data[inx]).beam[scanInx]
nBeams      = N_ELEMENTS(beamVec)

nGates      = SIZE((*rad_fit_data[inx]).power[scanInx,*],/DIMENSIONS)
nGates      = nGates[1]

;Get ground scatter information.
gscatter        = (*rad_fit_data[inx]).gscatter[scanInx,*]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pos1    = FLTARR(4,2,2)
IF  KEYWORD_SET(center) THEN dims = [4,nBeams,nGates] ELSE dims = [4,2,2,nBeams,nGates]
pos = FLTARR(dims)

FOR bm_i=0,nBeams-1 DO BEGIN
        bmnum       = beamVec[bm_i]
        frang       = 0.15*lagfrVec[bm_i]
        rsep        = 0.15*smsepVec[bm_i]
    FOR rg_i=0,nGates-1 DO BEGIN
        IF (~KEYWORD_SET(no_gs_adjustment) AND gscatter[bm_i,rg_i])     $
            || KEYWORD_SET(always_gs_adjustment) THEN gs = 1 ELSE gs = 0
        r           = rg_i+1    ;What gate do we really start things at??
        IF KEYWORD_SET(center) THEN BEGIN
            IF gs THEN BEGIN
                s=RadarPosGsD(1,bmnum,r-1,site,frang,rsep,rxrise,h,rho,lat,lon,d,FIX_HEIGHT=fix_height)
            ENDIF ELSE BEGIN
                s=RadarPosD(1,bmnum,r-1,site,frang,rsep,rxrise,h,rho,lat,lon,d,FIX_HEIGHT=fix_height)
            ENDELSE
            IF KEYWORD_SET(mgflag) THEN s=AACGMConvert(lat,lon,h,lat,lon,rad)
            pos1[0,0,0]=lat
            pos1[1,0,0]=lon
            pos1[2,0,0]=rho
            pos1[3,0,0]=d

            pos[*,bm_i,rg_i]    = pos1[*,0,0]
        ENDIF ELSE BEGIN
            IF gs THEN BEGIN
                s=RadarPosGsD(0,bmnum,r-1,site,frang,rsep,rxrise,h,rho,lat,lon,d,FIX_HEIGHT=fix_height)
            ENDIF ELSE BEGIN
                s=RadarPosD(0,bmnum,r-1,site,frang,rsep,rxrise,h,rho,lat,lon,d,FIX_HEIGHT=fix_height)
            ENDELSE
            IF KEYWORD_SET(mgflag) THEN s=AACGMConvert(lat,lon,h,lat,lon,rad)
            pos1[0,0,0]=lat
            pos1[1,0,0]=lon
            pos1[2,0,0]=rho
            pos1[3,0,0]=d

            IF gs THEN BEGIN
                s=RadarPosGsD(0,bmnum+1,r-1,site,frang,rsep,rxrise,h,rho,lat,lon,d,FIX_HEIGHT=fix_height)
            ENDIF ELSE BEGIN
                s=RadarPosD(0,bmnum+1,r-1,site,frang,rsep,rxrise,h,rho,lat,lon,d,FIX_HEIGHT=fix_height)
            ENDELSE
            IF KEYWORD_SET(mgflag) THEN s=AACGMConvert(lat,lon,h,lat,lon,rad)
            pos1[0,1,0]=lat
            pos1[1,1,0]=lon
            pos1[2,1,0]=rho
            pos1[3,1,0]=d

            IF gs THEN BEGIN
                s=RadarPosGsD(0,bmnum,r,site,frang,rsep,rxrise,h,rho,lat,lon,d,FIX_HEIGHT=fix_height)
            ENDIF ELSE BEGIN
                s=RadarPosD(0,bmnum,r,site,frang,rsep,rxrise,h,rho,lat,lon,d,FIX_HEIGHT=fix_height)
            ENDELSE
            IF KEYWORD_SET(mgflag) THEN s=AACGMConvert(lat,lon,h,lat,lon,rad)
            pos1[0,0,1]=lat
            pos1[1,0,1]=lon
            pos1[2,0,1]=rho
            pos1[3,0,1]=d

            IF gs THEN BEGIN
                s=RadarPosGsD(0,bmnum+1,r,site,frang,rsep,rxrise,h,rho,lat,lon,d,FIX_HEIGHT=fix_height)
            ENDIF ELSE BEGIN
                s=RadarPosD(0,bmnum+1,r,site,frang,rsep,rxrise,h,rho,lat,lon,d,FIX_HEIGHT=fix_height)
            ENDELSE
            IF KEYWORD_SET(mgflag) THEN s=AACGMConvert(lat,lon,h,lat,lon,rad)
            pos1[0,1,1]=lat
            pos1[1,1,1]=lon
            pos1[2,1,1]=rho
            pos1[3,1,1]=d

            pos[*,*,*,bm_i,rg_i]= pos1
        ENDELSE
    ENDFOR ;rg_i
ENDFOR ;bm_i

result  = REFORM(pos)
RETURN,result
END
