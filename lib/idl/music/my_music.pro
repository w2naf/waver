function my_music,invec,evals,nf=nf,fmin=fmin,fmax=fmax,thresh=thresh,corl=corl,s_dim=s_dim

vec=invec
len=n_elements(invec)

if keyword_set(nf) then nf=nf else nf=128
if keyword_set(fmin) then fmin=fmin else fmin=0.
if keyword_set(fmax) then fmax=fmax else fmax=2*!pi
if keyword_set(thresh) then thresh=thresh else thresh=0.2
if keyword_set(s_dim) then s_dim=s_dim else s_dim=4

df=(fmax-fmin)/nf
p=fltarr(nf)

cormat=corrmtx(vec,s_dim)

H = LA_ELMHES(cormat,q,PERMUTE_RESULT = permute, SCALE_RESULT = scale,/double)  
evals = LA_HQR(h, q, PERMUTE_RESULT = permute,status=status,/double)  
if cond(cormat) eq -1 then return,p
if status ne 0 then return,p
evecs = LA_EIGENVEC(H,Q,EIGENINDEX=eigenindex,PERMUTE_RESULT=permute,SCALE_RESULT=scale,/double)  

if max(abs(evals)) lt thresh then return,p

a=max(abs(evals))
q=where(abs(evals) le .2*a,qcount)

if qcount lt 3 then return,p
b=size(evecs,/dimensions)
en=complexarr(qcount,b[0])
for n=0,qcount-1 do en[n,*]=evecs[*,q[n]]

enen=conj(transpose(en))#en

for j=0,nf-1 do begin
   freq=fmin+float(j)*df
   mvec=complex(cos(findgen(b[0])*freq),sin(findgen(b[0])*freq))
   if keyword_set(corl) then mvec=complex_corl(mvec,mvec) else mvec=mvec
   p(j)=1./abs((conj(mvec)#enen)#mvec)
endfor


return,p
end
