; radarposgsd.pro
; =======
;--> Same as radarposgs(), but gives access to slant range using d keyword.
; Author: R.J.Barnes, D.Andre, and N. A. Frissell

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
; NAME:
;       RadarPosGS
;
; PURPOSE:
;       Convert a range/beam coordinates to geographic position for
;       ground scatter.
;       
;
; CALLING SEQUENCE:
;       RadarPosGS(center,bcrd,rcrd,site,frang,rsep,rxrise,
;                      height,rho,lat,lng)
;
;       This function converts a range/beam coordinate to 
;       geographic positiion for ground scatter
;       The range (starting at zero) is 
;       given by rcrd, the beam by bcrd. The radar hardware
;       table is given by the structure site. The position
;       of the first range gate in kilometers is given by
;       frang and the range seperation in kilometers is given
;       by rsep. The receiver rise time is given by rxrise, if
;       this value is zero then the rise time is taken from
;       the parameter block. The height of the transformation is
;       given by height, if this value is less than 90 then it
;       is asuumed to be the elevation angle from the radar.
;       If center is not equal to zero, then the calculation is
;       assumed to be for the center of the cell, not the edge.       
;
;       The calculated values are returned in rho, lat and lng
;       The returned value is zero.
;-----------------------------------------------------------------
;



function RadarPosGSd,center,bcrd,rcrd,site,frang,rsep,rxrise,$
                        height,rho,lat,lng,d
  re=6356.779D
  bm_edge=0.0D;
  range_edge=0.0D

  offset=site.maxbeam/2.0-0.5

  if  N_ELEMENTS(bcrd) ne 1 then begin

     n=N_ELEMENTS(bcrd)

     if N_ELEMENTS(rcrd) ne n then begin
        message, "beam and range arrays must be of equal length"
     end

     if (N_ELEMENTS(frang) ne 1) && (N_ELEMENTS(frang) ne n) then begin
        message, "beam and frang arrays must be of equal length"
     end

     if (N_ELEMENTS(rsep) ne 1) && (N_ELEMENTS(rsep) ne n) then begin
        message, "beam and rsep arrays must be of equal length"
     end

     if (N_ELEMENTS(rxrise) ne 1) && (N_ELEMENTS(rxrise) ne n) then begin
        message, "beam and rxrise arrays must be of equal length"
     end

     if (N_ELEMENTS(height) ne 1) && (N_ELEMENTS(height) ne n) then begin
        message, "beam and height arrays must be of equal length"
     end

     sze=SIZE(bcrd)

     rho=dblarr(sze[1:sze[0]])
     lat=dblarr(sze[1:sze[0]])
     lng=dblarr(sze[1:sze[0]])
       d=dblarr(sze[1:sze[0]])
 
     if (center eq 0) then bm_edge=-site.bmsep*0.5;
    
     if (N_ELEMENTS(frang) eq 1) then fr=frang
     if (N_ELEMENTS(rsep) eq 1) then begin 
       if (center eq 0) then re=-0.5*rsep*20.0/3.0
       rs=rsep
     endif

     if N_ELEMENTS(rxrise) eq 1 then begin
       if (rxrise eq 0) then rx=site.recrise $
       else rx=rxrise
     endif
     if N_ELEMENTS(height) eq 1 then hgt=height

     for i=0,n-1 do begin
        if N_ELEMENTS(frang) ne 1 then fr=frang[i]
        if N_ELEMENTS(rsep) ne 1 then begin 
          if (center eq 0) then re=-0.5*rsep*20.0/3.0
          rs=rsep[i]
        endif
        if N_ELEMENTS(rxrise) ne 1 then rx=rxrise[i]
        if N_ELEMENTS(height) ne 1 then hgt=height[i]
      

       psi=site.bmsep*(bcrd[i]-offset)+bm_edge
       rang=RadarSlantRange(fr,rs,rx,range_edge,rcrd[i]+1)

       if (hgt lt 90) then $
       hgt=-re+sqrt((re*re)+2*rang*re*sin(!PI*hgt/180.0)+(rang^2.));
        
       IF (rang^2/4. - height^2) GE 0 THEN BEGIN
           slantRange = re * ASIN(SQRT(rang^2/4. - hgt^2)/re) ;From Bristow et al. [1994]
        ENDIF ELSE slantRange = -1
;    ENDIF ELSE d = rang / 2.0D

       RadarFldPnthGS,site.geolat,site.geolon,psi,site.boresite,hgt,$ 
                    slantRange,r,la,ln 


       rho[i]=r
       lat[i]=la
       lng[i]=ln         
         d[i]=slantRange

     endfor
  end else begin

    if (rxrise eq 0) then rx=site.recrise $
    else rx=rxrise

    if (center eq 0) then begin
      bm_edge=-site.bmsep*0.5;
      range_edge=-0.5*rsep*20.0/3.0
    endif
    
    rho=0.0D
    lat=0.0D
    lng=0.0D 


    psi=site.bmsep*(bcrd-offset)+bm_edge
    rang=RadarSlantRange(frang,rsep,rx,range_edge,rcrd+1)

    if (height lt 90) then $
        height=-re+sqrt((re*re)+2*rang*re*sin(!PI*height/180.0)+(rang^2.));
    IF (rang^2/4. - height^2) GE 0 THEN BEGIN
        d = re * ASIN(SQRT(rang^2/4. - height^2)/re) ;From Bristow et al. [1994]
    ENDIF ELSE d = -1
;    ENDIF ELSE d = rang / 2.0D

    RadarFldPnthGS,site.geolat,site.geolon,psi,site.boresite,height,d,$ 
                   rho,lat,lng 
  endelse

  return, 0
end