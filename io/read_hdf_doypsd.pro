PRO READ_HDF_DOYPSD
hdfp  = 'doypsd/20111101-gbr.hdf'

;Ok, now lets try reading it back...
sdFileId  = HDF_SD_START(hdfp,/RdWr)

HDF_SD_FILEINFO,sdFileId,dataSets,attributes

FOR nn=0,attributes-1 DO BEGIN
  HDF_SD_ATTRINFO,sdFileId,nn,NAME=name,DATA=data,HDF_TYPE=hdf_type
  PRINT,name,data;,hdf_type
  ;help,data
ENDFOR

FOR nn=0,dataSets-1 DO BEGIN
  sdsId = HDF_SD_SELECT(sdFileId,nn)
  HDF_SD_GETINFO,sdsId,NAME=sdsName
  str$ = 'HDF_SD_GETDATA,sdsId,'+sdsName
  s = EXECUTE(str$)

  PRINT,'HDF Variable Loaded: ' + sdsName
ENDFOR

HDF_SD_ENDACCESS,sdsId
HDF_SD_END,sdFileId

STOP
END
