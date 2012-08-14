PRO DOYPSD_TO_H5
ff = 0
savDir  = 'doypsd/'
fileVec = ['20111101-gbr.sav']
RESTORE,/VERBOSE,RESTORED_OBJECTS=varConvert,savDir+fileVec[ff]

;WAVE_DATAPROC_INFO
;JULVEC
;PSDVEC
;DOYJULVEC
;DOYPSDVEC
;FTESTVEC

file = 'doypsd/20111101-gbr.h5'
fid = H5F_CREATE(file)

varConvert  = ['wave_dataproc_info','julVec', 'psdVec', 'doyJulVec', 'doyPsdVec', 'fTestVec']
FOR kk=0,N_ELEMENTS(varConvert) -1 DO BEGIN
  ; create some data  
  s = EXECUTE('data = ' + varConvert[kk])

  ; create a datatype  
  datatype_id = H5T_IDL_CREATE(data)  

  dims  = SIZE(data,/DIM)
  ; create a dataspace, allow the dataspace to be extendable  
  dataspace_id = H5S_CREATE_SIMPLE(dims)

  ; create the dataset  
  dataset_id = H5D_CREATE(fid,varConvert[kk],datatype_id,dataspace_id)

  ; extend the size of the dataset to fit the data  
  ;H5D_EXTEND,dataset_id,size(data,/dimensions)  

  ; write the data to the dataset  
  H5D_WRITE,dataset_id,data  

  ; close some identifiers  
  H5T_CLOSE,datatype_id  
  H5S_CLOSE,dataspace_id  
ENDFOR
H5F_CLOSE,fid  
STOP
END
