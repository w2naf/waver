FUNCTION ROI_INX,roi_in,array,cnt                       $
        ,VALUE          = value                         $
        ,EXPANDALL      = expandAll                     $
        ,XMINUS         = xMinus                        $
        ,XPLUS          = xPlus                         $
        ,YMINUS         = yMinus                        $
        ,YPLUS          = yPlus                         $
        ,ROI_OUT        = roi_out                       $
        ,ROI_SUM        = roi_sum

change  = LONARR(4)
IF ~KEYWORD_SET(value)  THEN value = 1 

IF  KEYWORD_SET(xMinus) THEN change = change + [-value,      0,     0,      0]  
IF  KEYWORD_SET(xPlus)  THEN change = change + [     0,      0, value,      0]  
IF  KEYWORD_SET(yMinus) THEN change = change + [     0, -value,     0,      0]  
IF  KEYWORD_SET(yPlus)  THEN change = change + [     0,      0,     0,  value]

IF ~KEYWORD_SET(xMinus) AND ~KEYWORD_SET(xPlus) AND                             $   
   ~KEYWORD_SET(yMinus) AND ~KEYWORD_SET(yPlus) AND                             $
    KEYWORD_SET(expandAll)   THEN                                               $   
    change      = change + value * [-1, -1, 1, 1]
    roi_out     = roi_in + change

minXinx = roi_out[0]
maxXinx = roi_out[2]
minYinx = roi_out[1]
maxYinx = roi_out[3]

nX      = N_ELEMENTS(array[0,*])
nY      = N_ELEMENTS(array[*,0])

xInxArr = TRANSPOSE(CMREPLICATE(LINDGEN(nX),nY))
yInxArr = CMREPLICATE(LINDGEN(nY),nX)

inx     = WHERE(xInxArr GE minXinx      $
            AND xInxArr LE maxXinx      $
            AND yInxArr GE minYinx      $   
            AND yInxArr LE maxYinx, cnt)

IF cnt GT 0 THEN BEGIN 
    lwLft   = MIN(inx) 
    lwLft   = REVERSE(ARRAY_INDICES(array,lwLft)) ;Reverse puts it into (x,y) order. 
    upRgt   = MAX(inx) 
    upRgt   = REVERSE(ARRAY_INDICES(array,upRgt)) 
    roi_out = [lwLft, upRgt]
ENDIF ELSE roi_out = [0,0,0,0]

roi_sum = TOTAL(array[inx])      

RETURN,inx
END
