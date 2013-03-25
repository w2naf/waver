PRO MUSIC_BLK
COMMON MUSIC_PARAMS                     $   
        ,radar                          $   
        ,date                           $   
        ,time                           $   
        ,fir_filter                     $
        ,fir_date                       $   
        ,fir_time                       $   
        ,fir_scale                      $
        ,zero_padding                   $
        ,timeStep                       $   
        ,param                          $   
        ,scale                          $
        ,filter                         $   
        ,ajground                       $   
        ,scatterflag                    $   
        ,bandLim                        $   
        ,dRange                         $   
        ,sim                            $   
        ,keep_lr                        $   
        ,kx_min                         $   
        ,ky_min                         $   
        ,use_all_cells                  $   ;Don't make things sparse for kx_min and ky_min
        ,coord                          $   
        ,mapXRange                      $   
        ,mapYRange                      $   
        ,lrdMapXRange                   $   
        ,lrdMapYRange                   $   
        ,lrdRotate                      $   
        ,movieXrange                    $   
        ,movieYrange                    $   
        ,movieRotate                    $   
        ,fftXMax                        $   
        ,frange                         $   
        ,foi                            $       ;Frequecy of Interest
        ,dkx                            $   
        ,dky                            $   
        ,kx_max                         $
        ,ky_max                         $
        ,event$                         $
        ,varNames$                      $
        ,run_id                         $
        ,ctrLat                         $
        ,ctrLon                         $
        ,ctrMLat                        $
        ,ctrMLon                        $
        ,ctrMLT                         $
        ,ctrJul                         $
        ,nmax                           $
        ,gl                             $   
        ,height                         $
        ,fix_height                     $
        ,statistics                     $   ;Run in statistics mode; that is keep a log file of all found karr and save all karr.sav
        ,savName                        $
        ,savPath                        $
        ,test

COMMON LOAD_MUSIC_EVENTS_BLK            $
        ,eventArr                       $
        ,varNames                       $
        ,eventArr$
        
END
