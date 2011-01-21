CREATE OR REPLACE PROCEDURAL LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION audit_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
            DECLARE
              col information_schema.columns %ROWTYPE;
              new_value text;
              old_value text;
              primary_key_column varchar;
              primary_key_value varchar;
              user_identifier integer;
              unique_name varchar;
              column_name varchar;
            BEGIN
              FOR col IN SELECT * FROM information_schema.columns WHERE table_name = TG_RELNAME LOOP
                new_value := NULL;
                old_value := NULL;
                primary_key_column := NULL;
                primary_key_value := NULL;
                user_identifier := current_setting('audit.user_id');
                unique_name := current_setting('audit.user_unique_name');
                column_name := col.column_name;

                EXECUTE 'SELECT pg_attribute.attname
                         FROM pg_index, pg_class, pg_attribute
                         WHERE pg_class.oid = $1::regclass
                         AND indrelid = pg_class.oid
                         AND pg_attribute.attrelid = pg_class.oid
                         AND pg_attribute.attnum = any(pg_index.indkey)
                         AND indisprimary'
                INTO primary_key_column USING TG_RELNAME;

                IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
                  EXECUTE 'SELECT CAST($1 . '|| column_name ||' AS TEXT)' INTO new_value USING NEW;
                  IF primary_key_column IS NOT NULL THEN
                    EXECUTE 'SELECT CAST($1 . '|| primary_key_column ||' AS VARCHAR)' INTO primary_key_value USING NEW;
                  END IF;
                END IF;
                IF TG_OP = 'DELETE' OR TG_OP = 'UPDATE' THEN
                  EXECUTE 'SELECT CAST($1 . '|| column_name ||' AS TEXT)' INTO old_value USING OLD;
                  EXECUTE 'SELECT CAST($1 . '|| primary_key_column ||' AS VARCHAR)' INTO primary_key_value USING OLD;
                END IF;

                IF TG_RELNAME = 'users' AND column_name = 'last_accessed_at' THEN
                  NULL;
                ELSE
                  IF TG_OP != 'UPDATE' OR new_value != old_value OR (TG_OP = 'UPDATE' AND ( (new_value IS NULL AND old_value IS NOT NULL) OR (new_value IS NOT NULL AND old_value IS NULL))) THEN
                    INSERT INTO audit_log("operation",
                                          "table_name",
                                          "primary_key",
                                          "field_name",
                                          "field_value_old",
                                          "field_value_new",
                                          "user_id",
                                          "user_unique_name",
                                          "when"
                                         )
                    VALUES(TG_OP,
                          TG_RELNAME,
                          primary_key_value,
                          column_name,
                          old_value,
                          new_value,
                          user_identifier,
                          unique_name,
                          current_timestamp);
                  END IF;
                END IF;
              END LOOP;
              RETURN NULL;
            END
            $_$;
