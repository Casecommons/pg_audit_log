CREATE TABLE audit_log (
    id integer NOT NULL,
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

CREATE SEQUENCE audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE audit_log_id_seq OWNED BY audit_log.id;

ALTER TABLE ONLY audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);
