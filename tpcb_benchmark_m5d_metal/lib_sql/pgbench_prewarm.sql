DO $$
    DECLARE
        rec TEXT;
        is_partition BOOLEAN;
    BEGIN

        SELECT CASE WHEN COUNT(1) > 1 THEN
                        TRUE
                    ELSE 
                        FALSE
                END INTO is_partition
        FROM pg_class
        WHERE relname ~* 'pgbench_accounts' AND relkind = 'r';
       
        IF is_partition THEN
            FOR rec IN  SELECT relname 
                    FROM   pg_class 
                    WHERE  relname NOT IN ( 'pgbench_accounts', 'pgbench_accounts_pkey' ) 
                        AND relname ~* 'pgbench_accounts' 
             LOOP
                RAISE NOTICE 'prewarming %',rec;
                PERFORM pg_prewarm(rec);
            END LOOP;
        ELSE
            FOR rec IN  SELECT relname 
                    FROM   pg_class 
                    WHERE  relname IN ( 'pgbench_accounts', 'pgbench_accounts_pkey' ) 
                        AND relname ~* 'pgbench_accounts' AND relispartition = false 
            LOOP
                RAISE NOTICE 'prewarming %',rec;
                PERFORM pg_prewarm(rec);
            END LOOP;
        END IF;

    END;
$$ LANGUAGE plpgsql
