PRO DOYPSD_TO_HDF
ff = 0
savDir  = 'doypsd/'
fileVec = ['20111101-gbr.sav']
RESTORE,/VERBOSE,savDir+fileVec[ff]

;WAVE_DATAPROC_INFO
;JULVEC
;PSDVEC
;DOYJULVEC
;DOYPSDVEC
;FTESTVEC

hdfVec  = FILE_BASENAME(fileVec,'.sav') + '.hdf'
hdfP  = savDir+hdfVec[ff]
sdFileId  = HDF_SD_START(hdfP,/CREATE)

tagVec  = TAG_NAMES(wave_dataproc_info)
FOR nn=0,N_ELEMENTS(tagVec)-1 DO BEGIN
  s = EXECUTE('val = wave_dataproc_info.'+tagVec[nn])

  HDF_SD_ATTRSET,sdFileId,tagVec[nn],val
ENDFOR

;HDF_SD_ATTRSET,sdFileId,'DATE_0',wave_dataproc_info.date
;;HDF_SD_ATTRSET,sdFileId,'DATE_0',wave_dataproc_info.date[0]
;;HDF_SD_ATTRSET,sdFileId,'DATE_1',wave_dataproc_info.date[1]
;HDF_SD_ATTRSET,sdFileId,'TIME_0',wave_dataproc_info.time[0]
;HDF_SD_ATTRSET,sdFileId,'TIME_1',wave_dataproc_info.time[1]

varConvert  = ['julVec', 'psdVec', 'doyJulVec', 'doyPsdVec', 'fTestVec']
FOR nn=0,N_ELEMENTS(varConvert)-1 DO BEGIN
  sdsName   = varConvert[nn]

  str$  = 'dims = SIZE('+sdsName+',/DIM)'
  s = EXECUTE(str$)

  str$  = 'type = HDF_IDL2HDFTYPE(SIZE('+sdsName+',/TYPE))'
  s = EXECUTE(str$)

  sdsID     = HDF_SD_CREATE(sdFileId,sdsName,dims,HDF_TYPE=type)

  str$  = 'HDF_SD_ADDDATA,sdsID,'+sdsName
  s = EXECUTE(str$)
ENDFOR

HDF_SD_ENDACCESS,sdsId
HDF_SD_END,sdFileId
STOP
END
