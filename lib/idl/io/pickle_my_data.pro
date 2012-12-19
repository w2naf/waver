PRO PICKLE_MY_DATA,radar,julVec,data,ctrFov,bndFov,run_id,PATH=path,PREFIX=prefix
  IF ~KEYWORD_SET(path) THEN path='' ELSE SPAWN,'mkdir -p '+path
  IF ~KEYWORD_SET(prefix) THEN prefix=''
  
  date0$ = JUL2STRING(julVec[0],FORMAT='YYYYMMDD')
  fname = path+prefix+STRUPCASE(radar)+'-'+date0$+'.RID'+run_id+'.sav'

  SAVE,FILENAME=fname,radar,julVec,data,ctrFov,bndFov,run_id,prefix
END
