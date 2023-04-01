SET SERVEROUTPUT ON;
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
    SELECT table_name FROM DBA_TABLES WHERE owner = 'PROD_SCHEMA'
    MINUS
    SELECT table_name FROM DBA_TABLES WHERE owner = 'DEV_SCHEMA';
    
    TYPE StrList IS TABLE OF VARCHAR2(30);
    strings_dev StrList := StrList();
    strings_prod StrList := StrList();
    strings_temp StrList := StrList();
    dev_col StrList := StrList();
    dev_type StrList := StrList();
    prod_col StrList := StrList();
    prod_type StrList := StrList();
    counter NUMBER := 1;
    exitflag NUMBER :=0;
BEGIN
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
                    DBMS_OUTPUT.put_line('несоответствие имени столбца '||dev_col(j)||'('||schema_1||') и '||prod_col(j)||'('||schema_2||') таблицы '|| strings_prod(i));
                    exitflag := 1;
                elsif prod_type(j) != dev_type(j) THEN
                    DBMS_OUTPUT.put_line('несоответствие типа столбца '||dev_col(j)||' таблицы '|| strings_prod(i));
                    exitflag := 1;
                END IF;
            END LOOP;
            if exitflag = 1 THEN
            DBMS_OUTPUT.put_line('DROP TABLE '||strings_prod(i)||' ['||schema_2||'];');
            DBMS_OUTPUT.put_line('CREATE TABLE '||strings_prod(i)||' ['||schema_2||'] (');
            for j in 1 .. dev_col.COUNT() LOOP
                if j != dev_col.COUNT() THEN
                    DBMS_OUTPUT.put_line(dev_col(j)||' '||dev_type(j)||',');
                ELSE
                    DBMS_OUTPUT.put_line(dev_col(j)||' '||dev_type(j));
                END IF;
            END LOOP;
            DBMS_OUTPUT.put_line(');');
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
            DBMS_OUTPUT.put_line('нема таблицы '||strings_dev(i));
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
            DBMS_OUTPUT.put_line('CREATE TABLE '||strings_dev(i)||' ['||schema_2||'] (');
            for j in 1 .. dev_col.COUNT() LOOP
                if j != dev_col.COUNT() THEN
                    DBMS_OUTPUT.put_line(dev_col(j)||' '||dev_type(j)||',');
                ELSE
                    DBMS_OUTPUT.put_line(dev_col(j)||' '||dev_type(j));
                END IF;
            END LOOP;
            DBMS_OUTPUT.put_line(');');
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
            DBMS_OUTPUT.put_line('DROP TABLE '||strings_temp(i)||' ['||schema_2||'];');     
        END LOOP;
    END IF;
------------------------------------------------------------------------------------------------------
    strings_dev := StrList();
    strings_prod := StrList();
    counter := 1;
    FOR i IN (SELECT * FROM ALL_PROCEDURES WHERE owner = schema_1) LOOP
        strings_dev.EXTEND();
        strings_dev(counter) := i.object_name;
        counter := counter + 1;
    END LOOP;
    counter := 1;
    FOR i IN (SELECT * FROM ALL_PROCEDURES WHERE owner = schema_2) LOOP
        strings_prod.EXTEND();
        strings_prod(counter) := i.object_name;
        counter := counter + 1;
    END LOOP;
    strings_dev := strings_dev MULTISET EXCEPT strings_prod;
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
                    DBMS_OUTPUT.put_line('несоответствие имени аргумента '||dev_col(j)||'('||schema_1||') и '||prod_col(j)||'('||schema_2||') таблицы '|| strings_prod(i));
                elsif prod_type(j) != dev_type(j) THEN
                    DBMS_OUTPUT.put_line('несоответствие типа аргумента '||dev_col(j)||' Функции/процедуры '|| strings_prod(i));
                END IF;
            END LOOP;
            prod_col := StrList();
            dev_col := StrList();
            prod_type := StrList();
            dev_type := StrList();
        END LOOP;
    END IF;
    if strings_prod.count() != 0 THEN
        FOR i IN strings_prod.FIRST .. strings_prod.LAST LOOP
            DBMS_OUTPUT.put_line('нема Функции/процедуры '||strings_prod(i));           
        END LOOP;
    END IF;
----------------------------------------------------------------------------------------
    strings_dev := StrList();
    strings_prod := StrList();
    counter := 1;
    FOR i IN (SELECT TABLE_NAME FROM ALL_INDEXES WHERE owner = schema_1) LOOP
        strings_dev.EXTEND();
        strings_dev(counter) := i.TABLE_NAME;
        counter := counter + 1;
    END LOOP;
    counter := 1;
    FOR i IN (SELECT TABLE_NAME FROM ALL_INDEXES WHERE owner = schema_2) LOOP
        strings_prod.EXTEND();
        strings_prod(counter) := i.TABLE_NAME;
        counter := counter + 1;
    END LOOP;
    strings_dev := strings_dev MULTISET EXCEPT strings_prod;
    if strings_prod.count() != 0 THEN
        FOR i IN strings_prod.FIRST .. strings_prod.LAST LOOP
            DBMS_OUTPUT.put_line('нема индекса таблицы '||strings_prod(i));           
        END LOOP;
    END IF;
END;