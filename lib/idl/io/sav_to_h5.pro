PRO SAV_TO_H5,file_in,file_out,varConvert
ff = 0

obj = OBJ_NEW('IDL_Savefile',file_in)
varConvert = obj -> NAMES()

fid = H5F_CREATE(file_out)

FOR kk=0,N_ELEMENTS(varConvert) -1 DO BEGIN
  PRINT,'Restoring '+varConvert[kk]+'...'
  obj -> RESTORE,varConvert[kk]

  ; create some data  
  s = EXECUTE('data = ' + varConvert[kk])


  type  = SIZE(data,/TYPE)

  IF type EQ 8 THEN BEGIN
    group_id  = H5G_CREATE(fid,varConvert[kk])
    tags  = TAG_NAMES(data)
    nTags = N_ELEMENTS(tags)
    FOR tt=0,nTags-1 DO BEGIN
      s = EXECUTE('data_tag = ' + varConvert[kk]+'.'+tags[tt])
      print,tags[tt]
      help,data_tag
;      print,data_tag
      datatype_id = H5T_IDL_CREATE(data_tag)
;      H5T_COMMIT,group_ID,tags[tt],datatype_id
          dims  = SIZE(data_tag,/DIM)
          IF dims[0] EQ 0 THEN dims=1

          ; create a dataspace, allow the dataspace to be extendable  
          dataspace_id  = H5S_CREATE_SIMPLE(dims)
          ; create the dataset  
          dataset_id    = H5D_CREATE(fid,tags[tt],datatype_id,dataspace_id)
          ; extend the size of the dataset to fit the data  
          ;H5D_EXTEND,dataset_id,size(data,/dimensions)  

          ; write the data to the dataset  
          H5D_WRITE,dataset_id,data_tag 
          ; close some identifiers  
          H5S_CLOSE,dataspace_id  

      H5T_CLOSE,datatype_id  
    ENDFOR
    H5G_CLOSE,group_ID
  ENDIF ELSE BEGIN
    ; create a datatype  
    datatype_id = H5T_IDL_CREATE(data)  
    dims  = SIZE(data,/DIM)
  ENDELSE
    
;  ; create a dataspace, allow the dataspace to be extendable  
;  dataspace_id = H5S_CREATE_SIMPLE(dims)
;  ; create the dataset  
;  dataset_id = H5D_CREATE(fid,varConvert[kk],datatype_id,dataspace_id)
;  ; extend the size of the dataset to fit the data  
;  ;H5D_EXTEND,dataset_id,size(data,/dimensions)  
;
;  ; write the data to the dataset  
;  H5D_WRITE,dataset_id,data  
;  ; close some identifiers  
;  H5S_CLOSE,dataspace_id  
ENDFOR
H5F_CLOSE,fid  
OBJ_DESTROY,obj
END
