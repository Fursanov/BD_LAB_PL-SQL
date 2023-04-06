SET SERVEROUTPUT ON;
--DROP DIRECTORY test_dir;
--CREATE DIRECTORY test_dir AS 'D:\';
--CREATE OR REPLACE PROCEDURE comparison_schemes(schema_1 VARCHAR2, schema_2 VARCHAR2) IS
DECLARE
    schema_1 VARCHAR2(20) := 'DEV_SCHEMA';
    schema_2 VARCHAR2(20) := 'PROD_SCHEMA';
    CURSOR dev_tables is
    SELECT table_name FROM DBA_TABLES WHERE owner = schema_1
    MINUS
    SELECT table_name FROM DBA_TABLES WHERE owner = schema_2;
    
    CURSOR prod_tables is
    SELECT table_name FROM DBA_TABLES WHERE owner = schema_1
    MINUS 
    (SELECT table_name FROM DBA_TABLES WHERE owner = schema_1
    MINUS
    SELECT table_name FROM DBA_TABLES WHERE owner = schema_2);
    
    CURSOR temp_tables is
    SELECT table_name FROM DBA_TABLES WHERE owner = schema_2
    MINUS
    SELECT table_name FROM DBA_TABLES WHERE owner = schema_1;
    
    TYPE StrList IS TABLE OF VARCHAR2(100);
    strings_dev StrList := StrList();
    strings_prod StrList := StrList();
    
    strings_temp StrList := StrList();
    
    dev_col StrList := StrList();
    dev_type StrList := StrList();
    prod_col StrList := StrList();
    prod_type StrList := StrList();
    
    func_dev StrList := StrList();
    func_prod StrList := StrList();
    
    counter NUMBER := 1;
    exitflag NUMBER :=0;
    
    file_id UTL_FILE.file_type;
BEGIN
    file_id := UTL_FILE.FOPEN ('TEST_DIR', 'test.sql', 'W');
    for i in dev_tables loop
            strings_dev.EXTEND();
            strings_dev(counter) := i.table_name;
            counter := counter + 1;
    end loop;
    counter := 1;
    for i in prod_tables loop
            strings_prod.EXTEND();
            strings_prod(counter) := i.table_name;
            counter := counter + 1;
    end loop;
    if strings_prod.count() != 0 THEN
        FOR i IN strings_prod.FIRST .. strings_prod.LAST LOOP
            counter := 1;
            FOR j IN (SELECT COLUMN_NAME, DATA_TYPE FROM ALL_TAB_COLUMNS WHERE table_name = strings_prod(i) and OWNER = schema_1) LOOP
                dev_col.EXTEND();
                dev_type.EXTEND();
                dev_col(counter) := j.COLUMN_NAME;
                dev_type(counter) := j.DATA_TYPE;
                counter := counter + 1;
            END LOOP;
            counter := 1;
            FOR j IN (SELECT COLUMN_NAME, DATA_TYPE FROM ALL_TAB_COLUMNS WHERE table_name = strings_prod(i) and OWNER = schema_2) LOOP
                prod_col.EXTEND();
                prod_type.EXTEND();
                prod_col(counter) := j.COLUMN_NAME;
                prod_type(counter) := j.DATA_TYPE;
                counter := counter + 1;
            END LOOP;
            for j in 1 .. dev_col.COUNT() LOOP
                if prod_col(j) != dev_col(j) THEN
                    DBMS_OUTPUT.put_line('несоответствие имени столбца '||dev_col(j)||'('||schema_1||') и ' || prod_col(j) || '(' || schema_2 || ') таблицы '|| strings_prod(i) || chr(10));
                    exitflag := 1;
                elsif prod_type(j) != dev_type(j) THEN
                    DBMS_OUTPUT.put_line('несоответствие типа столбца '||dev_col(j)||' таблицы '|| strings_prod(i) || chr(10));
                    exitflag := 1;
                END IF;
            END LOOP;
            if exitflag = 1 THEN
            UTL_FILE.PUTF(file_id, 'DROP TABLE '||schema_2||'.'||strings_prod(i)||';'||chr(10)||chr(10));
            UTL_FILE.PUTF(file_id, 'CREATE TABLE '||schema_2||'.'||strings_prod(i)||' ('||chr(10));
--            DBMS_OUTPUT.put_line('DROP TABLE '||schema_2||'.'||strings_prod(i)||';');
--            DBMS_OUTPUT.put_line('CREATE TABLE '||schema_2||'.'||strings_prod(i)||' (');
            for j in 1 .. dev_col.COUNT() LOOP
                if j != dev_col.COUNT() THEN
                    UTL_FILE.PUTF(file_id, dev_col(j)||' '||dev_type(j)||','||chr(10));
--                    DBMS_OUTPUT.put_line(dev_col(j)||' '||dev_type(j)||',');
                ELSE
                    UTL_FILE.PUTF(file_id, dev_col(j)||' '||dev_type(j)||chr(10));
--                    DBMS_OUTPUT.put_line(dev_col(j)||' '||dev_type(j));
                END IF;
            END LOOP;
            UTL_FILE.PUTF(file_id, ');' || chr(10) || chr(10));
--            DBMS_OUTPUT.put_line(');' || chr(10));
            exitflag := 0;
            END IF;
            prod_col := StrList();
            dev_col := StrList();
            prod_type := StrList();
            dev_type := StrList();
        END LOOP; 
    END IF;
    if strings_dev.count() != 0 THEN
        FOR i IN strings_dev.FIRST .. strings_dev.LAST LOOP
            DBMS_OUTPUT.put_line('нема таблицы '||strings_dev(i) || chr(10));
            dev_col := StrList();
            dev_type := StrList();
            counter := 1;
            FOR j IN (SELECT COLUMN_NAME, DATA_TYPE FROM ALL_TAB_COLUMNS WHERE table_name = strings_dev(i) and OWNER = schema_1) LOOP
                dev_col.EXTEND();
                dev_type.EXTEND();
                dev_col(counter) := j.COLUMN_NAME;
                dev_type(counter) := j.DATA_TYPE;
                counter := counter + 1;
            END LOOP;
            UTL_FILE.PUTF(file_id, 'CREATE TABLE '||schema_2||'.'||strings_dev(i)||' (' || chr(10));
--            DBMS_OUTPUT.put_line('CREATE TABLE '||schema_2||'.'||strings_dev(i)||' (');
            for j in 1 .. dev_col.COUNT() LOOP
                if j != dev_col.COUNT() THEN
                    UTL_FILE.PUTF(file_id, dev_col(j)||' '||dev_type(j)||',' || chr(10));
--                    DBMS_OUTPUT.put_line(dev_col(j)||' '||dev_type(j)||',');
                ELSE
                    UTL_FILE.PUTF(file_id, dev_col(j)||' '||dev_type(j) || chr(10));
--                    DBMS_OUTPUT.put_line(dev_col(j)||' '||dev_type(j));
                END IF;
            END LOOP;
            UTL_FILE.PUTF(file_id, ');' || chr(10) || chr(10));
--            DBMS_OUTPUT.put_line(');' || chr(10));
        END LOOP;
    END IF;
    counter := 1;
    for i in temp_tables loop
            strings_temp.EXTEND();
            strings_temp(counter) := i.table_name;
            counter := counter + 1;
    end loop;    
    if strings_temp.count() != 0 THEN
        FOR i IN strings_temp.FIRST .. strings_temp.LAST LOOP
            DBMS_OUTPUT.put_line('лишн€€ таблица '||strings_temp(i)||' в '|| schema_2 || chr(10));
            UTL_FILE.PUTF(file_id, 'DROP TABLE '||schema_2||'.'||strings_temp(i)||';' || chr(10) || chr(10));
--            DBMS_OUTPUT.put_line('DROP TABLE '||schema_2||'.'||strings_temp(i)||';' || chr(10));     
        END LOOP;
    END IF;
------------------------------------------------------------------------------------------------------
    strings_dev := StrList();
    strings_prod := StrList();
    counter := 1;
    FOR i IN 
    (SELECT object_name, object_type FROM ALL_PROCEDURES WHERE owner = schema_1 AND (OBJECT_TYPE = 'PROCEDURE' OR OBJECT_TYPE = 'FUNCTION') 
    MINUS 
    SELECT object_name, object_type FROM ALL_PROCEDURES WHERE owner = schema_2 AND (OBJECT_TYPE = 'PROCEDURE' OR OBJECT_TYPE = 'FUNCTION')) LOOP
        strings_dev.EXTEND();
        strings_dev(counter) := i.object_name;
        counter := counter + 1;
    END LOOP;
    counter := 1;
    FOR i IN 
    (SELECT object_name, object_type FROM ALL_PROCEDURES WHERE owner = schema_1 AND (OBJECT_TYPE = 'PROCEDURE' OR OBJECT_TYPE = 'FUNCTION')
    MINUS 
    (SELECT object_name, object_type FROM ALL_PROCEDURES WHERE owner = schema_1 AND (OBJECT_TYPE = 'PROCEDURE' OR OBJECT_TYPE = 'FUNCTION')
    MINUS 
    SELECT object_name, object_type FROM ALL_PROCEDURES WHERE owner = schema_2 AND (OBJECT_TYPE = 'PROCEDURE' OR OBJECT_TYPE = 'FUNCTION'))) LOOP
        strings_prod.EXTEND();
        strings_prod(counter) := i.object_name;
        counter := counter + 1;
    END LOOP;
    if strings_prod.count() != 0 THEN
        FOR i IN strings_prod.FIRST .. strings_prod.LAST LOOP
            counter := 1;
            FOR j IN (SELECT A.ARGUMENT_NAME, A.DATA_TYPE FROM ALL_ARGUMENTS A, ALL_OBJECTS O WHERE A.OBJECT_ID = O.OBJECT_ID AND O.OWNER = schema_1 AND A.OBJECT_NAME = strings_prod(i)) LOOP
                dev_col.EXTEND();
                dev_type.EXTEND();
                dev_col(counter) := j.ARGUMENT_NAME;
                dev_type(counter) := j.DATA_TYPE;
                counter := counter + 1;
            END LOOP;
            counter := 1;
            FOR j IN (SELECT A.ARGUMENT_NAME, A.DATA_TYPE FROM ALL_ARGUMENTS A, ALL_OBJECTS O WHERE A.OBJECT_ID = O.OBJECT_ID AND O.OWNER = schema_2 AND A.OBJECT_NAME = strings_prod(i)) LOOP
                prod_col.EXTEND();
                prod_type.EXTEND();
                prod_col(counter) := j.ARGUMENT_NAME;
                prod_type(counter) := j.DATA_TYPE;
                counter := counter + 1;
            END LOOP;
            for j in 1 .. prod_col.COUNT() LOOP
                if prod_col(j) != dev_col(j) THEN
                    DBMS_OUTPUT.put_line('несоответствие имени аргумента '||dev_col(j)||'('||schema_1||') и '||prod_col(j)||'('||schema_2||') ‘ункции/процедуры '|| strings_prod(i) || chr(10));
                elsif prod_type(j) != dev_type(j) THEN
                    DBMS_OUTPUT.put_line('несоответствие типа аргумента '||dev_col(j)||' ‘ункции/процедуры '|| strings_prod(i) || chr(10));
                END IF;
            END LOOP;
            counter := 1;
            FOR j IN (SELECT TEXT FROM ALL_SOURCE WHERE OWNER = schema_1 AND NAME = strings_prod(i)) LOOP
                func_dev.EXTEND();
                func_dev(counter) := j.TEXT;
                counter := counter + 1;
            END LOOP;
            counter := 1;
            FOR j IN (SELECT TEXT FROM ALL_SOURCE WHERE OWNER = schema_2 AND NAME = strings_prod(i)) LOOP
                func_prod.EXTEND();
                func_prod(counter) := j.TEXT;
                counter := counter + 1;
            END LOOP;
            for j in 1 .. prod_col.COUNT() LOOP
                if func_prod(j) != func_dev(j) THEN
                    DBMS_OUTPUT.put_line('несоответствие строки '||func_dev(j)||'('||schema_1||') и '||func_prod(j)||'('||schema_2||') ‘ункции/процедуры '|| strings_prod(i) || chr(10));
                    exitflag := 1;
                END IF;
            END LOOP;
            if exitflag = 1 THEN
                UTL_FILE.PUTF(file_id, 'CREATE OR REPLACE ' || chr(10));
--                DBMS_OUTPUT.put_line('CREATE OR REPLACE ');
                for j in 1 .. func_dev.COUNT() LOOP
                    if func_dev(j) LIKE '%PROCEDURE%' OR func_dev(j) LIKE '%FUNCTION%' THEN
                        UTL_FILE.PUTF(file_id, REPLACE(func_dev(j), LOWER(strings_prod(i)), schema_2||'.'||LOWER(strings_prod(i))));
--                        DBMS_OUTPUT.put_line(REPLACE(func_dev(j), LOWER(strings_prod(i)), schema_2||'.'||LOWER(strings_prod(i))));
                    else
                        UTL_FILE.PUTF(file_id, func_dev(j));
--                        DBMS_OUTPUT.put_line(func_dev(j));
                    END IF;
                END LOOP;
                UTL_FILE.PUTF(file_id, chr(10) || chr(10));
--                DBMS_OUTPUT.put_line(chr(10));
                exitflag := 0;
            END IF;
            prod_col := StrList();
            dev_col := StrList();
            prod_type := StrList();
            dev_type := StrList();
            func_prod := StrList();
            func_dev := StrList();
        END LOOP;
    END IF;
    if strings_dev.count() != 0 THEN
        FOR i IN strings_dev.FIRST .. strings_dev.LAST LOOP
            DBMS_OUTPUT.put_line('нема ‘ункции/процедуры '||strings_dev(i) || chr(10));
            UTL_FILE.PUTF(file_id, 'CREATE OR REPLACE ' || chr(10));
--            DBMS_OUTPUT.put_line('CREATE OR REPLACE ');
            FOR j IN (SELECT TEXT FROM ALL_SOURCE WHERE OWNER = schema_1 AND NAME = strings_dev(i)) LOOP
                if j.TEXT LIKE '%PROCEDURE%' OR j.TEXT LIKE '%FUNCTION%' THEN
                    UTL_FILE.PUTF(file_id, REPLACE(j.TEXT, LOWER(strings_dev(i)), schema_2||'.'||LOWER(strings_dev(i))));
--                    DBMS_OUTPUT.put_line(REPLACE(j.TEXT, LOWER(strings_dev(i)), schema_2||'.'||LOWER(strings_dev(i))));
                else
                    UTL_FILE.PUTF(file_id, j.TEXT);
--                    DBMS_OUTPUT.put_line(j.TEXT);
                END IF;
            END LOOP;
            UTL_FILE.PUTF(file_id, chr(10) || chr(10));
--            DBMS_OUTPUT.put_line(chr(10));
        END LOOP;
    END IF;
    FOR i IN 
    (SELECT object_name, object_type FROM ALL_PROCEDURES WHERE owner = schema_2 AND OBJECT_TYPE != 'PACKAGE' 
    MINUS 
    SELECT object_name, object_type FROM ALL_PROCEDURES WHERE owner = schema_1 AND OBJECT_TYPE != 'PACKAGE') LOOP
        DBMS_OUTPUT.put_line('лишн€€ функци€\процедура ' || i.object_name ||' в '|| schema_2 || chr(10));   
        UTL_FILE.PUTF(file_id, 'DROP ' || i.object_type || ' ' || schema_2 || '.' || i.object_name || ';' || chr(10) || chr(10));
--        DBMS_OUTPUT.put_line('DROP ' || i.object_type|| ' ' || i.object_name || ' [' || schema_2 || '];' || chr(10));     
    END LOOP;
----------------------------------------------------------------------------------------
    dev_col := StrList();
    dev_type := StrList();
    prod_col := StrList();
    prod_type := StrList();
    counter := 1;
    FOR i IN (SELECT TABLE_NAME, COLUMN_NAME FROM ALL_IND_COLUMNS WHERE table_owner = schema_1
                MINUS
                SELECT TABLE_NAME, COLUMN_NAME FROM ALL_IND_COLUMNS WHERE table_owner = schema_2) LOOP
        dev_col.EXTEND();
        dev_col(counter) := i.COLUMN_NAME;
        dev_type.EXTEND();
        dev_type(counter) := i.TABLE_NAME;
        counter := counter + 1;
    END LOOP;
    counter := 1;
    FOR i IN (SELECT TABLE_NAME, COLUMN_NAME FROM ALL_IND_COLUMNS WHERE table_owner = schema_2
                MINUS
                SELECT TABLE_NAME, COLUMN_NAME FROM ALL_IND_COLUMNS WHERE table_owner = schema_1) LOOP
        prod_col.EXTEND();
        prod_col(counter) := i.COLUMN_NAME;
        prod_type.EXTEND();
        prod_type(counter) := i.TABLE_NAME;
        counter := counter + 1;
    END LOOP;
    if prod_col.count() != 0 THEN
        FOR i IN prod_col.FIRST .. prod_col.LAST LOOP
            UTL_FILE.PUTF(file_id, 'DROP INDEX ' || schema_2 || '.' || prod_col(i) || ';' || chr(10) || chr(10));
            DBMS_OUTPUT.put_line('лишний индекс '||prod_col(i)||' таблицы '||prod_type(i) || chr(10));           
        END LOOP;
    END IF;
    if dev_col.count() != 0 THEN
        FOR i IN dev_col.FIRST .. dev_col.LAST LOOP
            UTL_FILE.PUTF(file_id, 'CREATE INDEX ' || schema_2 || '.' || dev_col(i) || ' ON ' || schema_2 || '.' || dev_type(i) || '(' || dev_col(i) || ') TABLESPACE TABLESPACE1;' || chr(10) || chr(10));
            DBMS_OUTPUT.put_line('нема индекса '||dev_col(i)||' таблицы '||dev_type(i) || chr(10));           
        END LOOP;
    END IF;
------------------------------------------------------------------------------------------------------------------------------------
    FOR i IN (SELECT NAME FROM ALL_SOURCE WHERE OWNER = schema_1 AND TYPE = 'PACKAGE' GROUP BY NAME
                MINUS
                SELECT NAME FROM ALL_SOURCE WHERE OWNER = schema_2 AND TYPE = 'PACKAGE' GROUP BY NAME) LOOP
        DBMS_OUTPUT.put_line('нема пакета '||i.NAME|| chr(10));
        UTL_FILE.PUTF(file_id, 'CREATE OR REPLACE ' || chr(10));
        FOR j IN (SELECT TEXT FROM ALL_SOURCE WHERE OWNER = schema_1 AND NAME = i.NAME) LOOP
            if j.TEXT LIKE '%PACKAGE%' AND j.TEXT NOT LIKE '%END%' THEN
                UTL_FILE.PUTF(file_id, REPLACE(j.TEXT, i.NAME, schema_2||'.'||LOWER(i.NAME)));
            elsif j.TEXT LIKE '%END%' THEN
                UTL_FILE.PUTF(file_id, j.TEXT || chr(10) || chr(10));
            else
                UTL_FILE.PUTF(file_id, j.TEXT);
            END IF;
        END LOOP;
    END LOOP;
    FOR i IN (SELECT NAME FROM ALL_SOURCE WHERE OWNER = schema_2 AND TYPE = 'PACKAGE' GROUP BY NAME
                MINUS
                SELECT NAME FROM ALL_SOURCE WHERE OWNER = schema_1 AND TYPE = 'PACKAGE' GROUP BY NAME) LOOP
        DBMS_OUTPUT.put_line('лишний пакет '||i.NAME|| chr(10));
        UTL_FILE.PUTF(file_id, 'DROP PACKAGE '|| schema_2 || '.' || i.NAME || ';' || chr(10));
    END LOOP;
    UTL_FILE.FCLOSE(file_id);
END;