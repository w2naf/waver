FUNCTION CAPITAL,stringIn

len = STRLEN(stringIn)
stringOut = STRUPCASE(STRMID(stringIn,0,1)) + STRLOWCASE(STRMID(stringIn,1,len-1))

RETURN,stringOut
END
