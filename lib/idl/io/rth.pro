PRO rth
;'RAWTSR_TO_H5'
type    = 'intpsd'
in_dir  = 'psdsav'
out_dir = 'psdsav'
varConvert  = ['wave_dataproc_info','wave_rawtsr_data']

srch    = in_dir+'/*.'+type+'.sav'
files   = FILE_SEARCH(srch,COUNT=cnt)

IF cnt EQ 0 THEN STOP

FOR ff  = 0,cnt-1 DO BEGIN
  file_out  = out_dir+'/'+FILE_BASENAME(files[ff],'sav')+'h5'
  SAV_TO_H5,files[ff],file_out,varConvert

  STOP
ENDFOR



STOP
END
