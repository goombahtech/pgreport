#AUTHORIZED TO Goombah 
#Script: Pre/Post Migration Report
#Script Done by Goombah Tech Solutions 

#!/bin/bash
PSQL=/Library/PostgreSQL/9.1/bin/psql
SAMPLE_DB=postgres
PORT=5432
USER=postgres
# +++++ PSQL Query Runner +++++ #

Query_Runner() 
{
QUERY=$1
DB=$2
$PSQL -U "$USER" -p "$PORT" -d "$DB" -F " " -Atc "$QUERY"
}

# +++++ Report Header +++++ #
clear
printf "%150s\n" " " | tr ' ' '='
echo -e "\t\t\t\t\t\t:::::::  Pre/Post Migration Report ::::::::"
printf "%150s\n" " " | tr ' ' '='
echo
echo -e "\tDate           : `date +"%d/%m/%Y"`"
echo -e "\tHostname       : `hostname -s`"
echo -e "\tOS & Hardware  : `uname -a`"
echo -e "\tNo.of CPU      : `cat /proc/cpuinfo|grep -io processor|wc -l`"
echo -e "\tCPU Model      : `cat /proc/cpuinfo|grep -i 'model name'|awk -F ': ' {'print $2'}|head -1`"
echo -e "\tMainMemory     : `cat /proc/meminfo|grep -i memtotal|awk -F ':' {'print $2'}|sed -e 's/[\t ]//g;/^$/d'`"
echo -e "\tPG Version     : $(Query_Runner "SELECT VERSION()" "$SAMPLE_DB")"
echo -e "\tPG Startup     : $(Query_Runner "SELECT PG_POSTMASTER_START_TIME()" "$SAMPLE_DB")"
echo -e "\tPostgres Port  : $(Query_Runner "SHOW PORT" "$SAMPLE_DB")"
echo -e "\tData Directory : $(Query_Runner "SHOW DATA_DIRECTORY" "$SAMPLE_DB")"
echo -e "\tSuper User     : $(Query_Runner "SELECT  UPPER(ROLNAME) FROM PG_ROLES WHERE ROLSUPER IS TRUE ORDER BY ROLNAME DESC LIMIT 1" "$SAMPLE_DB")"
echo -e "\tArchive Mode   : $(Query_Runner "SHOW ARCHIVE_MODE" "$SAMPLE_DB")"
# +++++ PG Instance Details At OS Level +++++ #
echo
printf "%150s\n" " " | tr ' ' '-'
echo -e "\t\t\t\t\t\t::::::: PG Instance Report At OS Level ::::::::"
printf "%150s\n" " " | tr ' ' '-'
DATA_DIRECTORY=$(Query_Runner "SHOW DATA_DIRECTORY" "$SAMPLE_DB")
echo
echo -e "\tData Directory : $DATA_DIRECTORY"
echo -e "`df -Ph $DATA_DIRECTORY|awk -F ' ' {'print "\t\tTotal Space :"$2 "\tUsed  Space :"$3 "\tAvail Space :"$4'}|grep -E [0-9]+`"
echo -e "\txlog Directory : `ls -ld $DATA_DIRECTORY/pg_xlog|awk -F 'pg_xlog' {'print "pg_xlog" $2'}`"
echo -e "`df -Ph $DATA_DIRECTORY/pg_xlog|awk -F ' ' {'print "\t\tTotal Space :"$2 "\tUsed  Space :"$3 "\tAvail Space :"$4'}|grep -E [0-9]+`"
if [ "$(Query_Runner "SHOW LOGGING_COLLECTOR" "$SAMPLE_DB")" = "on" ]; then

	if [ "$(Query_Runner "SHOW LOG_DIRECTORY" "$SAMPLE_DB")" = "pg_log" ]; then
	
	echo -e "\tLog Directory  : `ls -ld $DATA_DIRECTORY/pg_log|awk -F 'pg_log' {'print "pg_log" $2'}`"
	echo -e "`df -Ph $DATA_DIRECTORY/pg_log|awk -F ' ' {'print "\t\tTotal Space :"$2 "\tUsed  Space :"$3 "\tAvail Space :"$4'}|grep -E [0-9]+`"
	
	else
	
        echo -e "\tLog Directory  : $(Query_Runner "SHOW LOG_DIRECTORY" "$SAMPLE_DB")";
        echo -e "`df -Ph $(Query_Runner "SHOW LOG_DIRECTORY")|awk -F ' ' {'print "\t\tTotal Space :"$2 "\tUsed  Space :"$3 "\tAvail Space :"$4'}|grep -E [0-9]+`"
	fi
else
	echo -e "\tLoggint Mode   : Off"	
fi

# +++++ PG Cluster Details +++++ #

echo
printf "%150s\n" " " | tr ' ' '-'
echo -e "\t\t\t\t\t\t::::::: CLUSTER Objects Report ::::::::"
printf "%150s\n" " " | tr ' ' '-'
echo
echo -e "\tDATABASE\t\t\tTABLESPACE\t\t\tUSERS\t\t\tROLES\t\t\tLANGUAGES"
echo -e "\t-=-=-=-=\t\t\t-=-=-=-=-=\t\t\t-=-=-=\t\t\t-=-=\t\t\t-=-=-=-="
MAXROWS=$(Query_Runner "select greatest( (select count(*) from pg_database where datname !~ '^template'),(select count(*) from pg_tablespace),(select count(*) from pg_language),(select count(*) from pg_roles where rolcanlogin is true),(select count(*) from pg_roles where rolcanlogin is false))" "$SAMPLE_DB")
J=1
echo "$(Query_Runner "DROP SEQUENCE __ROWNUMSTEMPSEQ__" "$SAMPLE_DB")" >/dev/null 2>/dev/null
echo "$(Query_Runner "CREATE SEQUENCE __ROWNUMSTEMPSEQ__" "$SAMPLE_DB")" >/dev/null 2>/dev/null
echo "$(Query_Runner "SELECT NEXTVAL('__ROWNUMSTEMPSEQ__')" "$SAMPLE_DB")" >/dev/null 2>/dev/null
#SEQVALUE=$(Query_Runner "SELECT SETVAL('__ROWNUMSTEMPSEQ__',1)" "$SAMPLE_DB") 
for (( i = 1; i <= $MAXROWS; i++ ))
do
printf "\t%-32s%-32s%-24s%-25s%-25s\n" "$(Query_Runner "SELECT (DATNAME) FROM PG_DATABASE WHERE NEXTVAL('__ROWNUMSTEMPSEQ__')-1=$i AND DATNAME !~ '^template' ORDER BY 1" "$SAMPLE_DB")" "$(Query_Runner "SELECT (SPCNAME) FROM PG_TABLESPACE WHERE NEXTVAL('__ROWNUMSTEMPSEQ__')-(SELECT COUNT(*) FROM PG_DATABASE WHERE DATNAME !~ '^template')-1=$i ORDER BY 1" "$SAMPLE_DB")" "$(Query_Runner "SELECT case when rolsuper is true then (ROLNAME||' (S)') else ROLNAME END FROM PG_ROLES WHERE ROLCANLOGIN IS TRUE AND NEXTVAL('__ROWNUMSTEMPSEQ__')-(SELECT COUNT(*) FROM PG_DATABASE WHERE DATNAME !~ '^template')-(SELECT COUNT(*) FROM PG_TABLESPACE)-1=$i" "$SAMPLE_DB")" "$(Query_Runner "SELECT (ROLNAME) FROM PG_ROLES WHERE ROLCANLOGIN IS FALSE AND NEXTVAL('__ROWNUMSTEMPSEQ__')-(SELECT COUNT(*) FROM PG_DATABASE WHERE DATNAME !~ '^template')-(SELECT COUNT(*) FROM PG_TABLESPACE)-(SELECT COUNT(*) FROM PG_ROLES WHERE ROLCANLOGIN IS TRUE)-1=$i" "$SAMPLE_DB")" "$(Query_Runner "SELECT (LANNAME) FROM PG_LANGUAGE WHERE  NEXTVAL('__ROWNUMSTEMPSEQ__')-(SELECT COUNT(*) FROM PG_DATABASE WHERE DATNAME !~ '^template')-(SELECT COUNT(*) FROM PG_TABLESPACE)-(SELECT COUNT(*) FROM PG_ROLES WHERE ROLCANLOGIN IS TRUE)-(SELECT COUNT(*) FROM PG_ROLES WHERE ROLCANLOGIN IS TRUE)=$i" "$SAMPLE_DB")"
Query_Runner "SELECT SETVAL('__ROWNUMSTEMPSEQ__',1)" "$SAMPLE_DB" >/dev/null 2>/dev/null
done
printf "%150s\n" " " | tr ' ' '-'
printf "%9s%32s%32s%24s%25s\n" "$(Query_Runner "SELECT COUNT(*) FROM PG_DATABASE WHERE DATNAME !~ '^template'" "$SAMPLE_DB")" "$(Query_Runner "SELECT COUNT(*) FROM PG_TABLESPACE" "$SAMPLE_DB")" "$(Query_Runner "SELECT COUNT(*) FROM PG_ROLES WHERE ROLCANLOGIN IS TRUE" "$SAMPLE_DB")" "$(Query_Runner "SELECT COUNT(*) FROM PG_ROLES WHERE ROLCANLOGIN IS FALSE" "$SAMPLE_DB")" "$(Query_Runner "SELECT COUNT(*) FROM PG_LANGUAGE" "$SAMPLE_DB")"

# +++++ PG Database Details +++++ #

echo
#printf "%150s\n" " " | tr ' ' '-'
#echo -e "\t\t\t\t\t\t::::::: PG Database Report ::::::::"
#printf "%150s\n" " " | tr ' ' '-'
#echo
#echo -e "\tDBNAME\t\t\tSIZE\t\tNO.OF SCHEMAS\t\tTOTAL OBJECTS"
#echo -e "\t-=-=-=\t\t\t-=-=-=-=\t-=-=-=-=-=-=-\t\t-=-=-=-=-=-=-"
J=0
for DBNAME in $(Query_Runner "SELECT (DATNAME) FROM PG_DATABASE WHERE DATNAME !~ '^template'" "$SAMPLE_DB")
do
#echo -e "\t$(Query_Runner "SELECT RPAD(UPPER('$DBNAME'),20,' ')")$(Query_Runner "SELECT LPAD(PG_SIZE_PRETTY(PG_DATABASE_SIZE('$DBNAME')),9,' ') "$DBNAME"")$(Query_Runner "SELECT LPAD(COUNT(*)::TEXT,17,' ') FROM PG_NAMESPACE WHERE NSPNAME !~ '^pg_toast|^pg_temp|^pg_catalog|^information_schema'" "$DBNAME")$(Query_Runner "SELECT LPAD(COUNT(*)::TEXT,26,' ') FROM PG_CLASS P,PG_NAMESPACE S WHERE S.NSPNAME !~ '^pg_toast|^pg_temp|^pg_catalog|^information_schema' AND P.RELNAMESPACE=S.OID" "$DBNAME")"
echo -e "\t\t\t\t\t\t\t:: $DBNAME [ "$(Query_Runner "SELECT PG_SIZE_PRETTY(PG_DATABASE_SIZE(('$DBNAME')))" "$DBNAME")" ] :: Details "
printf "%150s\n" " " | tr ' ' '-'
echo 
echo -e "\tTABLESPACE\t\tLOCATION\t\t\tSIZE\t\tNo.of Tables\tNo.of Indexes"
echo -e "\t-=-=-=-=-=\t\t-=-=-=-=\t\t\t-=-=\t\t-=-=-=-=-=-=\t-=-=-=-=-=-=-"
for TABSPACE in $(Query_Runner "SELECT SPCNAME FROM PG_TABLESPACE" "$DBNAME")
do
echo -e "$(Query_Runner "select LPAD(RPAD(spcname::TEXT,23,' '),31,' '),RPAD((case when spcname='pg_default' then 'pgdata/base' when spcname='pg_global' then 'pgdata/global' else spclocation end)::TEXT,31,' '),RPAD(pg_size_pretty(pg_tablespace_size(spcname)),15,' ') from pg_tablespace where spcname='$TABSPACE'" "$DBNAME")" "$(Query_Runner "SELECT RPAD(COUNT(*)::text,15,' ') FROM PG_TABLES WHERE schemaname !~ '^pg_toast|^pg_temp|^pg_catalog|^information_schema' AND coalesce(tablespace,null,'pg_default')='$TABSPACE'" "$DBNAME")" "$(Query_Runner "SELECT COUNT(*) FROM PG_INDEXES WHERE SCHEMANAME !~ '^pg_toast|^pg_temp|^pg_catalog|^information_schema' AND coalesce(TABLESPACE,null,'pg_default')='$TABSPACE'" "$DBNAME")"
done
printf "%150s\n" " " | tr ' ' '-'
printf "%9s" "$(Query_Runner "SELECT COUNT(*) FROM PG_TABLESPACE" "$DBNAME")"
echo
echo
if [ $J -eq 0 ]; then
echo -e "\tSCHEMAS\t\t\t\tTABLES\t\tINDEXES\t\tSEQUENCES\tVIWS\t\tSIZE"
echo -e "\t-=-=-=-\t\t\t\t-=-=-=\t\t-=-=-=-=\t-=-=-=-=\t-=-=\t\t-=-="
fi
echo -e "$(Query_Runner "SELECT LPAD(RPAD(NSPNAME,31,' '),39,' '),RPAD((SELECT COUNT(*) FROM PG_TABLES WHERE SCHEMANAME=NSPNAME)::TEXT,15,' '),RPAD((SELECT COUNT(*) FROM PG_INDEXES WHERE SCHEMANAME=NSPNAME)::TEXT,15,' '),RPAD((SELECT COUNT(*) FROM PG_CLASS WHERE RELKIND='S' AND RELNAMESPACE=PG_NAMESPACE.OID)::TEXT,15,' ') ,RPAD((SELECT COUNT(*) FROM PG_VIEWS WHERE SCHEMANAME=NSPNAME)::TEXT,15,' '),(SELECT pg_size_pretty(sum(pg_relation_size(nspname||'.\"'||relname||'\"'))::bigint)  from pg_class where relnamespace=pg_namespace.oid and relkind in ('r','i','t')group by nspname) AS SIZE FROM PG_NAMESPACE WHERE NSPNAME !~ '^pg_toast|^pg_temp|^information_schema|^pg_catalog' ORDER BY 2 DESC" "$DBNAME") "
printf "%150s\n" " " | tr ' ' '-'
printf "%9s%32s%16s%16s%16s\n" "$(Query_Runner "SELECT COUNT(*) FROM PG_NAMESPACE WHERE NSPNAME !~ '^pg_toast|^pg_temp|^information_schema|^pg_catalog'" "$DBNAME")" "$(Query_Runner "SELECT COUNT(*) FROM PG_TABLES WHERE SCHEMANAME !~ '^pg_toast|^pg_temp|^information_schema|^pg_catalog'" "$DBNAME")" "$(Query_Runner "SELECT COUNT(*) FROM PG_INDEXES WHERE SCHEMANAME !~ '^pg_toast|^pg_temp|^information_schema|^pg_catalog' " "$DBNAME")" "$(Query_Runner "SELECT COUNT(*) FROM PG_CLASS,PG_NAMESPACE WHERE RELKIND='S' AND RELNAMESPACE=PG_NAMESPACE.OID AND NSPNAME !~ '^pg_toast|^pg_temp|^information_schema|^pg_catalog'" "$DBNAME")" "$(Query_Runner "SELECT COUNT(*) FROM PG_VIEWS WHERE SCHEMANAME !~ '^pg_toast|^pg_temp|^information_schema|^pg_catalog'" "$DBNAME")"
echo

done

#PRIMARY KEY TABLES DETAILS 

for DBNAME in $(Query_Runner "SELECT (DATNAME) FROM PG_DATABASE WHERE DATNAME !~ '^template'" "$SAMPLE_DB")
do
echo -e "Collecting Statistics for "$DBNAME" .... "
Query_Runner "ANALYZE" "$DBNAME"
echo -e "Collected Statistics .... "
for SCHEMA in $(Query_Runner "SELECT NSPNAME FROM PG_NAMESPACE WHERE NSPNAME !~ '^pg_toast|^pg_temp|^information_schema|^pg_catalog'" "$DBNAME")
do
echo -e "\t\t\t\t\t:: DATABASE -> $DBNAME  SCHEMA -> $SCHEMA Primary Key Tables Details ::"
printf "%150s\n" " " | tr ' ' '-'
echo
echo -e "\tTABLES\t\t\t\t\tTABLESPACE\t\tPRIMARY KEY\t\t\t\tROWCOUNT\tBLOAT\tTABLESIZE"
echo -e "\t-=-=-=\t\t\t\t\t-=-=-=-=-=-\t\t-=-=-=-=-=\t\t\t\t-=-=-=--\t-=-=-\t-=-=-=-=-"
echo -e "$(Query_Runner "SELECT LPAD(RPAD(table_name,39,' '),47,' '),RPAD(COALESCE(tablespace,null,'base'),23,' '),RPAD(constraint_name,39,' '),rpad(n_live_tup::text,15,' '),rpad(round(n_dead_tup/(case when (n_live_tup+n_dead_tup)=0 then 1 else (n_live_tup+n_dead_tup)::real end)*100)||'%',7,' ') as bloat, (pg_size_pretty(pg_relation_size(pg_stat_all_tables.schemaname||'.'||relname))::TEXT) FROM information_schema.table_constraints,pg_stat_all_tables,pg_tables WHERE constraint_type IN ('PRIMARY KEY') AND table_schema='$SCHEMA' AND pg_stat_all_tables.schemaname=pg_tables.schemaname and  pg_tables.schemaname=table_schema and relname=table_name and table_name=tablename ORDER BY 3 DESC" "$DBNAME") "
printf "%150s\n" " " | tr ' ' '-'
printf "%9s" "$(Query_Runner "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS,PG_STAT_ALL_TABLES,pg_tables WHERE constraint_type IN ('PRIMARY KEY') AND table_schema='$SCHEMA' AND pg_stat_all_tables.schemaname=pg_tables.schemaname and  pg_tables.schemaname=table_schema and relname=table_name and table_name=tablename" "$DBNAME")"
echo
done
done

#NON-PRIMARY KEY TABLES

for DBNAME in $(Query_Runner "SELECT (DATNAME) FROM PG_DATABASE WHERE DATNAME !~ '^template'" "$SAMPLE_DB")
do
for SCHEMA in $(Query_Runner "SELECT NSPNAME FROM PG_NAMESPACE WHERE NSPNAME !~ '^pg_toast|^pg_temp|^information_schema|^pg_catalog'" "$DBNAME")
do
echo -e "\t\t\t\t\t:: DATABASE -> $DBNAME  SCHEMA -> $SCHEMA Non Primary Key Tables Details ::"
printf "%150s\n" " " | tr ' ' '-'
echo
echo -e "\tTABLES\t\t\t\t\t\tTABLESPACE\t\tROWCOUNT\tBLOAT\tTABLESIZE"
echo -e "\t-=-=-=\t\t\t\t\t\t-=-=-=----\t\t-=-=-=-=\t-=-=-\t-=-=--=-=" 
echo -e "$(Query_Runner "SELECT LPAD(RPAD(table_name,47,' '),55,' '),RPAD(COALESCE(tablespace,null,'base'),23,' '),rpad(n_live_tup::text,15,' '),rpad(round(n_dead_tup/(case when (n_live_tup+n_dead_tup)=0 then 1 else (n_live_tup+n_dead_tup)::real end)*100)||'%',7,' ') as bloat, (pg_size_pretty(pg_relation_size(pg_stat_all_tables.schemaname||'.'||relname))::TEXT) FROM information_schema.tables,pg_stat_all_tables,pg_tables
WHERE (table_catalog, table_schema, table_name) NOT IN (SELECT table_catalog, table_schema, table_name FROM information_schema.table_constraints WHERE constraint_type IN ('PRIMARY KEY')) AND table_schema='$SCHEMA' AND pg_stat_all_tables.schemaname=pg_tables.schemaname and pg_tables.schemaname=table_schema and relname=table_name and table_name=tablename ORDER BY 2 DESC" "$DBNAME") "
printf "%150s\n" " " | tr ' ' '-'
printf "%9s" "$(Query_Runner "SELECT COUNT(*) FROM information_schema.tables,pg_stat_all_tables,pg_tables WHERE (table_catalog, table_schema, table_name) NOT IN (SELECT table_catalog, table_schema, table_name FROM information_schema.table_constraints WHERE constraint_type IN ('PRIMARY KEY')) AND table_schema='$SCHEMA' AND pg_stat_all_tables.schemaname=pg_tables.schemaname and pg_tables.schemaname=table_schema and relname=table_name and table_name=tablename" "$DBNAME")"
echo
done
done

#SEQUENCES DETAILS

for DBNAME in $(Query_Runner "SELECT (DATNAME) FROM PG_DATABASE WHERE DATNAME !~ '^template'" "$SAMPLE_DB")
do
for SCHEMA in $(Query_Runner "SELECT NSPNAME FROM PG_NAMESPACE WHERE NSPNAME !~ '^pg_toast|^pg_temp|^information_schema|^pg_catalog'" "$DBNAME")
do
echo -e "\t\t\t\t\t:: DATABASE -> $DBNAME  SCHEMA -> $SCHEMA Sequences Details ::"
printf "%150s\n" " " | tr ' ' '-'
echo -e "\tTABLES\t\t\t\t\t\tCOLUMN\t\t\tSEQUENCE"
echo -e "\t-=-=-=\t\t\t\t\t\t-=-=-=\t\t\t-=-=-=-="
echo -e "$(Query_Runner "SELECT LPAD(RPAD(TAB_SEQ_LIST.table::text,47,' '),55, ' '),RPAD(TAB_SEQ_LIST.column::text,23,' '),TAB_SEQ_LIST.sequence_def FROM (SELECT a.attname as column,a.attrelid::regclass as table ,(SELECT substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128) FROM pg_catalog.pg_attrdef d WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef) as sequence_def FROM pg_catalog.pg_attribute a WHERE a.attrelid::regclass::text in (select table_name::text from information_schema.tables where table_schema IN('$SCHEMA') ) AND a.attnum >0 AND NOT a.attisdropped ORDER BY a.attnum) AS TAB_SEQ_LIST WHERE TAB_SEQ_LIST.sequence_def is not null and TAB_SEQ_LIST.sequence_def ilike '%nextval(''%''::regclass)'" "$DBNAME")"
printf "%150s\n" " " | tr ' ' '-'
echo -e "\t$(Query_Runner "SELECT COUNT(*) FROM (SELECT a.attname as column,a.attrelid::regclass as table ,(SELECT substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128) FROM pg_catalog.pg_attrdef d WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef) as sequence_def FROM pg_catalog.pg_attribute a WHERE a.attrelid::regclass::text in (select table_name::text from information_schema.tables where table_schema IN('$SCHEMA') ) AND a.attnum >0 AND NOT a.attisdropped ORDER BY a.attnum) AS TAB_SEQ_LIST WHERE TAB_SEQ_LIST.sequence_def is not null and TAB_SEQ_LIST.sequence_def ilike '%nextval(''%''::regclass)'" "$DBNAME")"
echo
done
done

#FUNCTIONS DETAILS
for DBNAME in $(Query_Runner "SELECT (DATNAME) FROM PG_DATABASE WHERE DATNAME !~ '^template'" "$SAMPLE_DB")
do
for SCHEMA in $(Query_Runner "SELECT NSPNAME FROM PG_NAMESPACE WHERE NSPNAME !~ '^pg_toast|^pg_temp|^information_schema|^pg_catalog'" "$DBNAME")
do
echo -e "\t\t\t\t\t:: DATABASE -> $DBNAME  SCHEMA -> $SCHEMA Function Details ::"
printf "%150s\n" " " | tr ' ' '-'
echo -e "\tFunction\t\t\t\t\t\tLanguage"
echo -e "\t-=-=-=\t\t\t\t\t\t\t-=-=-=-="
echo -e "$(Query_Runner "SELECT LPAD(RPAD(proname,55,' '),63,' '),lanname FROM PG_PROC,PG_NAMESPACE,PG_LANGUAGE WHERE PRONAMESPACE=PG_NAMESPACE.OID AND NSPNAME='$SCHEMA' AND PROLANG=PG_LANGUAGE.OID and lanname !~ '^internal' " "$DBNAME")"
printf "%150s\n" " " | tr ' ' '-'
echo -e "\t$(Query_Runner "SELECT COUNT(*) FROM PG_PROC,PG_NAMESPACE,PG_LANGUAGE WHERE PRONAMESPACE=PG_NAMESPACE.OID AND NSPNAME='$SCHEMA' AND PROLANG=PG_LANGUAGE.OID and lanname !~ '^internal'" "$DBNAME")"
echo
done
done

#TRIGGER DETAILS
for DBNAME in $(Query_Runner "SELECT (DATNAME) FROM PG_DATABASE WHERE DATNAME !~ '^template'" "$SAMPLE_DB")
do
echo -e "\t\t\t\t\t:: DATABASE -> $DBNAME Trigger Details :: "
printf "%150s\n" " " | tr ' ' '-'
echo -e "\tTable\t\t\t\t\t\t\t\tTrigger"
echo -e "\t-=-=-\t\t\t\t\t\t\t\t-=-=-=-"
echo -e "$(Query_Runner "select LPAD(RPAD(tgrelid::regclass::text,63,' '),71,' '),tgname from pg_trigger where tgname !~ 'RI_ConstraintTrigger_'" "$DBNAME")"
printf "%150s\n" " " | tr ' ' '-'
echo -e "\t$(Query_Runner "Select count(*) from pg_trigger where tgname !~ 'RI_ConstraintTrigger_'" "$DBNAME")"
done

#FOREIGNKEY DETAILS
for DBNAME in $(Query_Runner "SELECT (DATNAME) FROM PG_DATABASE WHERE DATNAME !~ '^template'" "$SAMPLE_DB")
do
echo -e "\t\t\t\t\t:: DATABASE -> $DBNAME ForeignKey Details :: "
printf "%150s\n" " " | tr ' ' '-'
echo -e "\tTable\t\t\t\t\t\t\t\tForeign KEY"
echo -e "\t-=-=-\t\t\t\t\t\t\t\t-=-=-=-=-=-"
echo -e "$(Query_Runner "select LPAD(RPAD(conrelid::regclass::text,63,' '),71,' '),pg_get_constraintdef(oid, true) from pg_constraint where contype='f'" "$DBNAME")"
printf "%150s\n" " " | tr ' ' '-'
echo -e "\t$(Query_Runner "Select count(*) from pg_constraint where contype='f'" "$DBNAME")"
done

echo 
exit
