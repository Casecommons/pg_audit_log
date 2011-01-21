CREATE SEQUENCE audit_log_id_seq
    START WITH 1
    INCREMENT BY 1;

CREATE TABLE audit_log (
    id integer PRIMARY KEY DEFAULT nextval('audit_log_id_seq'),
    user_id integer,
    user_unique_name character varying(255),
    operation character varying(255),
    table_name character varying(255),
    field_name character varying(255),
    field_value_new text,
    field_value_old text,
    "when" timestamp without time zone,
    primary_key character varying(255)
);

ALTER SEQUENCE audit_log_id_seq OWNED BY audit_log.id;
