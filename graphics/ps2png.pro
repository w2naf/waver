PRO PS2PNG,fileName_in$,ROTATE=rotate

;IF KEYWORD_SET(rotate) THEN rot$ = ' -rotate '+NUMSTR(rotate)+' ' ELSE rot$=''

baseName$       = FILE_BASENAME(fileName_in$,'.ps')
path$           = FILE_DIRNAME(fileName_in$)

fileName_out$   = path$ + '/' + baseName$ + '.png'

cmd$            = 'convert -density 300 -quality 100 -page letter +repage +matte '         $
                + fileName_in$ + ' ' + fileName_out$
SPAWN,cmd$,result$,error$
;IF KEYWORD_SET(rotate) THEN rot$ = ' -rotate '+NUMSTR(rotate)+' ' ELSE rot$=''

IF KEYWORD_SET(rotate) THEN BEGIN
    cmd$            = 'mogrify -rotate '+NUMSTR(rotate)+' +repage '             $
                    + fileName_out$
    SPAWN,cmd$,result$,error$
ENDIF

END
