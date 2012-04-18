PRO OPEN_LOOP_PLOT,direct,ptype,step

step$       = STRING(step,FORMAT='(I03)')
path        = direct+pType+'/' 
file        = step$+'-'+pType+'.ps'
IF step EQ 0 THEN BEGIN
    SPAWN,'mkdir -p ' + path
    SPAWN,'rm ' + path+'*.ps ' + path+'*.pdf '
ENDIF
file            = DIR(path+file,/PS)

END
