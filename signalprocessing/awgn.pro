PRO AWGN

n       = 100.

IF KEYWORD_SET(seed) THEN s = TEMPORARY(seed)
rand    = RANDOMN(seen,n)

CLEAR_PAGE,/NEXT

PLOT,rand

STOP
END
