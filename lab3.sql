SET SERVEROUTPUT ON;
--CREATE OR REPLACE PROCEDURE comparison_schemes(schema_1 VARCHAR2, schema_2 VARCHAR2) IS
DECLARE
    schema_1 VARCHAR2(20) := 'DEV_SCHEMA';
    schema_2 VARCHAR2(20) := 'PROD_SCHEMA';
    CURSOR dev_tables is
    SELECT table_name FROM DBA_TABLES WHERE owner = schema_1;
    CURSOR prod_tables is
    SELECT table_name FROM DBA_TABLES WHERE owner = schema_2;
    TYPE StrList IS TABLE OF VARCHAR2(30);
    strings_dev StrList := StrList();
    strings_prod StrList := StrList();
    dev_col StrList := StrList();
    dev_type StrList := StrList();
    prod_col StrList := StrList();
    prod_type StrList := StrList();
    counter NUMBER := 1;
BEGIN
--    for i in dev_tables loop
--            strings_dev.EXTEND();
--            strings_dev(counter) := i.table_name;
--            counter := counter + 1;
--    end loop;
--    counter := 1;
--    for i in prod_tables loop
--            strings_prod.EXTEND();
--            strings_prod(counter) := i.table_name;
--            counter := counter + 1;
--    end loop;
--    strings_dev := strings_dev MULTISET EXCEPT strings_prod;
--    if strings_prod.count() != 0 THEN
--        FOR i IN strings_prod.FIRST .. strings_prod.LAST LOOP
--            counter := 1;
--            FOR j IN (SELECT COLUMN_NAME, DATA_TYPE FROM ALL_TAB_COLUMNS WHERE table_name = strings_prod(i) and OWNER = schema_1) LOOP
--                dev_col.EXTEND();
--                dev_type.EXTEND();
--                dev_col(counter) := j.COLUMN_NAME;
--                dev_type(counter) := j.DATA_TYPE;
--                counter := counter + 1;
--            END LOOP;
--            counter := 1;
--            FOR j IN (SELECT COLUMN_NAME, DATA_TYPE FROM ALL_TAB_COLUMNS WHERE table_name = strings_prod(i) and OWNER = schema_2) LOOP
--                prod_col.EXTEND();
--                prod_type.EXTEND();
--                prod_col(counter) := j.COLUMN_NAME;
--                prod_type(counter) := j.DATA_TYPE;
--                counter := counter + 1;
--            END LOOP;
--            for j in 1 .. prod_col.COUNT() LOOP
--                if prod_col(j) != dev_col(j) THEN
--                    DBMS_OUTPUT.put_line('�������������� ����� ������� '||dev_col(j)||'('||schema_1||') � '||prod_col(j)||'('||schema_2||') ������� '|| strings_prod(i));
--                elsif prod_type(j) != dev_type(j) THEN
--                    DBMS_OUTPUT.put_line('�������������� ���� ������� '||dev_col(j)||' ������� '|| strings_prod(i));
--                END IF;
--            END LOOP;
--            prod_col := StrList();
--            dev_col := StrList();
--            prod_type := StrList();
--            dev_type := StrList();
--        END LOOP; 
--    END IF;
--    if strings_dev.count() != 0 THEN
--        FOR i IN strings_dev.FIRST .. strings_dev.LAST LOOP
--            DBMS_OUTPUT.put_line('���� ������� '||strings_dev(i));
--        END LOOP;
--    END IF;
END;
