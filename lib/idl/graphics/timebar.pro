;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Create Time Progress Bar ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Use this one if WITH_INFO=1
position = define_panel(1,1,0,0, /BAR, /with_info, no_title=no_title)
yShift  = 0.04
position = [position[0], position[3]+0.05+yShift, $
        position[2], position[3]+0.09+yShift]

xticks  = GET_XTICKS(julStepVec[0],julStepVec[nFrames-1],XMINOR=xMinor)

; Use this one if WITH_INFO=0
;                position = define_panel(xmaps, ymaps, xmap, ymap, bar=bar, with_info=with_info, no_title=no_title)

PLOT,julStepVec,julStepVec*0+1                                          $   
    ,/NODATA                                                            $   
    ,XTICKFORMAT        = 'LABEL_DATE'                                  $   
    ,CHARSIZE           = 0.75                                          $   
    ,XTITLE             = 'Time [UT]'                                   $   
    ,XTICKS             = xTicks                                        $   
    ,XMINOR             = xMinor                                        $   
    ,YRANGE             = [0,1]                                         $   
    ,YTICKS             = 1                                             $   
    ,YTICKNAME          = REPLICATE(' ',2)                              $   
    ,POSITION           = position                                      $   
    ,/XSTYLE                                                            $   
    ,/YSTYLE
polyX   = [julStepVec[0],julStepVec[0],jul,jul]
polyY   = [0,1,1,0]
POLYFILL,polyX,polyY
; End Time Progress Bar ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
