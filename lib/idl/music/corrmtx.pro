function corrmtx,x,m,overlap

n=n_elements(x)
tp=size(x,/type)
if tp eq 4 then corm=fltarr(n+m,m+1)
if tp eq 5 then corm=doublearr(n+m,m+1)
if tp eq 6 then corm=complexarr(n+m,m+1)


;s = 4
;x = [1, 2, 3, 4]
;THEN
;corm =  [1, 2, 3, 4, 0, 0, 0, 0]
;        |0, 1, 2, 3, 4, 0, 0, 0|
;        |0, 0, 1, 2, 3, 4, 0, 0|
;        |0, 0, 0, 1, 2, 3, 4, 0|
;        [0, 0, 0, 0, 1, 2, 3, 4]
for j1=0,m do corm[j1:j1+n-1,j1]=x

;5x5
;      30      20      11       4       0
;      20      30      20      11       4
;      11      20      30      20      11
;       4      11      20      30      20
;       0       4      11      20      30

;return,corm#transpose(conj(corm))
return,transpose(conj(corm))#corm
end
