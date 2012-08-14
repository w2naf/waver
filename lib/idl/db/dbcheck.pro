PRO DBCHECK

db$     = 'ulf'
usr$    = 'ulf'
psd$    = 'ulf'
OPENMYSQL,lun,db$,USER=usr$,PASSWORD=psd$
query$  = "SELECT * FROM Events INTO OUTFILE '/tmp/mysql/test.sql' FIELDS TERMINATED BY ',';"
query$  = "SELECT * FROM Events;"
MYSQLCMD,lun,query$,answer,nlines
FREE_LUN,lun

print,answer
STOP
END
