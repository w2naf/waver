function complex_corl,s1i,s2i,normalize=normalize,do_plot=do_plot,periodic=periodic

s1=s1i
s2=s2i

badval = 10000.
q=where(s1 ne badval,qcount)
if qcount le 0 then return,-1

q2=where(s2 ne badval,q2count)
if q2count le 0 then return,-1


if keyword_set(normalize) then begin
   m1=moment(s1[q])
   s1[q]=(s1[q]-m1(0))/sqrt(m1(1))

   m2=moment(s2[q2])
   s2[q2]=(s2[q2]-m2(0))/sqrt(m2(1))
   
endif

if keyword_set(do_plot) then begin
   a=max(abs(s1[q]))
   plot,s1,/xstyle,yrange=[-a,a]
   oplot,s2,color=100
endif

;if qcount ge 2*q2count then hold1=s1 else hold1 = [s1,s1]
if keyword_set(periodic) then hold1=[s1,s1] else begin
   len=n_elements(s1)
   hold1=complexarr(2*len)
   hold1[0:len-1]=s1
endelse

a = size(s2,/n_elements)

corr = complexarr(a)
cor_cnt = intarr(a)
for j=0,a-1 do begin
   sl1=hold1[j:j+a-1]
   q=where( s2 ne badval and sl1 ne badval,qcount)
   if qcount gt 0 then begin
      s2r=real_part(s2[q])
      s2i=imaginary(s2[q])
      sl1r=real_part(sl1[q])
      sl1i=imaginary(sl1[q])
      corr[j]=complex(total(s2r*sl1r+s2i*sl1i),total(s2r*sl1i-s2i*sl1r))/float(qcount)
   endif
endfor
return,corr
end


