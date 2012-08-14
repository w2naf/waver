; create HDF5 file 
file = 'hdf5_out.h5' 
fid = H5F_CREATE(file) 
 
; create some data 
data = hanning(100,200) 
 
; create a datatype 
datatype_id = H5T_IDL_CREATE(data) 
 
; create a dataspace, allow the dataspace to be extendable 
dataspace_id = $ 
     H5S_CREATE_SIMPLE([100,100],max_dimensions=[200,200]) 
    
   ; create the dataset 
   dataset_id = H5D_CREATE(fid,'Hanning',datatype_id,dataspace_id, $ 
        chunk_dimensions=[20,20]) 
       
      ; extend the size of the dataset to fit the data 
      H5D_EXTEND,dataset_id,size(data,/dimensions) 
       
      ; write the data to the dataset 
      H5D_WRITE,dataset_id,data 
       
      ; close some identifiers 
      H5S_CLOSE,dataspace_id 
      H5T_CLOSE,datatype_id 
       
      ; create a reference attribute attached to the dataset 
      dataspace_id = H5S_CREATE_SIMPLE(size(data,/dimensions)) 
       
      ; select a 30x30 element region of interest in the dataset 
      H5S_SELECT_HYPERSLAB,dataspace_id,[40,40],[1,1], $ 
           block=[30,30],/reset 
          
         ; create a dataspace region reference 
         ref = H5R_CREATE(fid,'Hanning',dataspace=dataspace_id) 
          
         ; create a datatype for the reference 
         datatype_id = H5T_REFERENCE_CREATE(/region) 
          
         ; create a one element dataspace for the single reference 
         dataspace_id = H5S_CREATE_SIMPLE(1) 
          
         ; make the reference an attribute of the dataset  
         attr_id = H5A_CREATE(dataset_id,'Ref',datatype_id,dataspace_id) 
         H5A_WRITE,attr_id,ref 
         H5A_CLOSE,attr_id 
          
         ; create a dummy attribute and delete it 
         attr_id2 = $ 
           H5A_CREATE(dataset_id,'Dummy',datatype_id,dataspace_id) 
          
         ; attribute must be closed before it can be deleted 
         H5A_CLOSE,attr_id2 
         H5A_DELETE,dataset_id,'Dummy' 
          
         ; create a group to hold sample datatypes and links 
         group_id = H5G_CREATE(fid,'Datatypes and links') 
          
         ; add a comment to the group 
         H5G_SET_COMMENT,fid,'Datatypes and links', $ 
              'This is a sample comment' 
            ; add a datatype to the group 
            datatype_id2 = H5T_IDL_CREATE(1) 
             
            ; add the datatype to the group and give it a name 
            H5T_COMMIT,group_id,'Integer',datatype_id2 
             
            ; create an array datatype and add it to the group with a name 
            datatype_id3 = H5T_ARRAY_CREATE(datatype_id2,[3,4]) 
            H5T_COMMIT,group_id,'Integer 2',datatype_id3 
             
            ; rename previous datatype 
            H5G_MOVE,group_id,'Integer 2','Integer Array' 
             
            ; close temporary datatypes 
            H5T_CLOSE,datatype_id3 
            H5T_CLOSE,datatype_id2 
             
            ; create a compound datatype and add it to the group 
            struct = {float:1.0, double:1.0d} 
            datatype_id4 = $ 
                 H5T_IDL_CREATE(struct,member_names=['Float','Double']) 
                
               ; create an integer datatype and insert it in the  
               ; compound datatype 
               datatype_id5 = H5T_IDL_CREATE(1) 
               H5T_INSERT,datatype_id4,'Integer',datatype_id5 
                
               ; add the datatype to the group and give it a name 
               H5T_COMMIT,group_id,'Compound',datatype_id4 
                
               ; close datatype identifiers 
               H5T_CLOSE,datatype_id5 
               H5T_CLOSE,datatype_id4 
                
               ; add a hard link from the group to the Hanning dataset  
               H5G_LINK,fid,'Hanning','Link to Hanning',new_loc_id=group_id 
                
               ; add a dummy link 
               H5G_LINK,group_id,'Integer','Link to Integer' 
                
               ; remove dummy link 
               H5G_UNLINK,group_id,'Link to Integer' 
                
               ; close remaining open identifiers 
               H5G_CLOSE,group_id 
               H5D_CLOSE,dataset_id 
               H5T_CLOSE,datatype_id 
               H5S_CLOSE,dataspace_id 
               H5F_CLOSE,fid 
               END
