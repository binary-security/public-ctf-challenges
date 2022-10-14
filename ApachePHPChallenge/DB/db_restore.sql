--
-- PostgreSQL database dump
--
CREATE ROLE admin;
ALTER ROLE admin WITH SUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:PcnT1pll5I70PrclWuiWXg==$rS/DZ+rBWGgIDUsw6tgWLKAhKiqOyiMtknWzTNgVGzk=:aBAiq15hIdXUmPS/7igVhVjJK2egUaT6Ue/SbEd11ME=';
CREATE ROLE logger;
ALTER ROLE logger WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE webserver;
ALTER ROLE webserver WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:NJ8RPooug4H2f8BGlpKHeg==$x5JSzCQwXKE3riylDm/Rnsi6Lbdin0sssew0mOhZSH4=:94Vb4Kwpxa9gy4/spPVJtTgFfHXzqtQXkxz0oyF/le0=';


CREATE DATABASE webdb WITH TEMPLATE = template0 ENCODING = 'UTF8';


ALTER DATABASE webdb OWNER TO admin;
-- Dumped from database version 14.5
-- Dumped by pg_dump version 14.5

\c webdb

GRANT pg_write_server_files TO logger;

ALTER USER webserver WITH PASSWORD 'Whatever';

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: admin; Type: SCHEMA; Schema: -; Owner: admin
--

CREATE SCHEMA admin;


ALTER SCHEMA admin OWNER TO admin;

--
-- Name: logs; Type: SCHEMA; Schema: -; Owner: logger
--

CREATE SCHEMA logs;


ALTER SCHEMA logs OWNER TO logger;

--
-- Name: web; Type: SCHEMA; Schema: -; Owner: webserver
--

CREATE SCHEMA web;


ALTER SCHEMA web OWNER TO webserver;

--
-- Name: admin_status; Type: TYPE; Schema: admin; Owner: admin
--

CREATE TYPE admin.admin_status AS ENUM (
    'admin',
    'user',
    'webadmin'
);


ALTER TYPE admin.admin_status OWNER TO admin;

--
-- Name: check_password(character varying, text); Type: FUNCTION; Schema: admin; Owner: admin
--

CREATE FUNCTION admin.check_password(mail character varying, hash text) RETURNS numeric
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'admin', 'pg_temp'
    AS $$
DECLARE passed BOOLEAN;
BEGIN
    SELECT (passhash =hash) INTO passed
    FROM admin.passwd 
    WHERE email = mail;
    IF passed = true THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
$$;


ALTER FUNCTION admin.check_password(mail character varying, hash text) OWNER TO admin;

--
-- Name: get_user_status(character varying); Type: FUNCTION; Schema: admin; Owner: admin
--

CREATE FUNCTION admin.get_user_status(mail character varying) RETURNS admin.admin_status
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'admin', 'pg_temp'
    AS $$
DECLARE o_role admin.admin_status;
BEGIN    
    SELECT role INTO o_role FROM admin.users WHERE email = mail;
    RETURN o_role;
END;
$$;


ALTER FUNCTION admin.get_user_status(mail character varying) OWNER TO admin;

--
-- Name: insert_passwd(character varying, text); Type: FUNCTION; Schema: admin; Owner: admin
--

CREATE FUNCTION admin.insert_passwd(mail character varying, passhash text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'admin', 'pg_temp'
    AS $$
BEGIN
    INSERT INTO admin.passwd (id, email, passhash) VALUES ((SELECT id FROM admin.users WHERE email=mail), mail, passhash);
END;
$$;


ALTER FUNCTION admin.insert_passwd(mail character varying, passhash text) OWNER TO admin;

--
-- Name: insert_user(character varying, admin.admin_status); Type: FUNCTION; Schema: admin; Owner: admin
--

CREATE FUNCTION admin.insert_user(mail character varying, _role admin.admin_status) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'admin', 'pg_temp'
    AS $$
BEGIN
    INSERT INTO admin.users (role, email) VALUES (_role, mail);
END;
$$;


ALTER FUNCTION admin.insert_user(mail character varying, _role admin.admin_status) OWNER TO admin;

--
-- Name: export_access_log(character varying, character varying, character, integer); Type: FUNCTION; Schema: logs; Owner: admin
--

CREATE FUNCTION logs.export_access_log(identifier character varying DEFAULT 'log_'::character varying, extension character varying DEFAULT 'csv'::character varying, delimiter character DEFAULT ','::bpchar, row_count integer DEFAULT 1000) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'logs', 'pg_temp'
    AS $$
DECLARE fil TEXT;
BEGIN
    SELECT '/var/log/postgresql/' || identifier || md5(identifier) || '_' ||  extract(epoch from now()) || '.log' || '.' || extension INTO fil;

    EXECUTE format ('
    COPY (SELECT * FROM logs.failed_access_logs LIMIT %L) 
    TO %L', row_count,fil);
    DELETE FROM logs.failed_access_logs; 
    RETURN 'TRUE';
END;
$$;


ALTER FUNCTION logs.export_access_log(identifier character varying, extension character varying, delimiter character, row_count integer) OWNER TO admin;

--
-- Name: write_failed_access(character varying, text, text); Type: FUNCTION; Schema: logs; Owner: admin
--

CREATE FUNCTION logs.write_failed_access(email character varying, user_agent text, _ip text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'logs', 'pg_temp'
    AS $$
BEGIN
    INSERT INTO logs.failed_access_logs(email_tried, agent, ip) VALUES (email, user_agent, _ip);
END;
    $$;


ALTER FUNCTION logs.write_failed_access(email character varying, user_agent text, _ip text) OWNER TO admin;

--
-- Name: id; Type: SEQUENCE; Schema: admin; Owner: admin
--

CREATE SEQUENCE admin.id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE admin.id OWNER TO admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: passwd; Type: TABLE; Schema: admin; Owner: admin
--

CREATE TABLE admin.passwd (
    id integer NOT NULL,
    email character varying(255),
    passhash text
);


ALTER TABLE admin.passwd OWNER TO admin;

--
-- Name: users; Type: TABLE; Schema: admin; Owner: admin
--

CREATE TABLE admin.users (
    id integer DEFAULT nextval('admin.id'::regclass) NOT NULL,
    role admin.admin_status DEFAULT 'user'::admin.admin_status,
    email character varying(255) NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE admin.users OWNER TO admin;

--
-- Name: failed_access_logs; Type: TABLE; Schema: logs; Owner: admin
--

CREATE TABLE logs.failed_access_logs (
    attempt_time timestamp without time zone DEFAULT now() NOT NULL,
    email_tried character varying(255),
    agent text,
    ip text
);


ALTER TABLE logs.failed_access_logs OWNER TO logger;

--
-- Name: suggestions; Type: TABLE; Schema: web; Owner: webserver
--

CREATE TABLE web.suggestions (
    freeform text,
    contact text
);


ALTER TABLE web.suggestions OWNER TO webserver;

--
-- Data for Name: passwd; Type: TABLE DATA; Schema: admin; Owner: admin
--

COPY admin.passwd (id, email, passhash) FROM stdin;
1	admin@localhost.com	bad8ae357b4cf1cbeec1653f6438a1598210b3ab3485c4d3aa2ade0ab08a8456
2	webserver@localhost.com	877b75d567a37be79ccd30a7e00f52c473cc422c515237b7a06bcf2a76abc160
3	wiener@peter.com	008c70392e3abfbd0fa47bbc2ed96aa99bd49e159727fcba0f2e6abeb3a9d601
4	carlos@montoya.com	64ba7cb32cb4b8de6f912fb20322593cf59edbeef815b6b0f99953c3b0782c89
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: admin; Owner: admin
--

COPY admin.users (id, role, email, last_update) FROM stdin;
1	admin	admin@localhost.com	2022-09-06 03:50:46.936423
2	webadmin	webserver@localhost.com	2022-09-06 03:52:18.724864
3	user	wiener@peter.com	2022-09-06 03:52:47.751801
4	user	carlos@montoya.com	2022-09-06 03:53:06.73458
\.


--
-- Data for Name: failed_access_logs; Type: TABLE DATA; Schema: logs; Owner: admin
--

COPY logs.failed_access_logs (attempt_time, email_tried, agent, ip) FROM stdin;
\.


--
-- Data for Name: suggestions; Type: TABLE DATA; Schema: web; Owner: webserver
--

COPY web.suggestions (freeform, contact) FROM stdin;
\.


--
-- Name: id; Type: SEQUENCE SET; Schema: admin; Owner: admin
--

SELECT pg_catalog.setval('admin.id', 9, true);


--
-- Name: passwd passwd_pkey; Type: CONSTRAINT; Schema: admin; Owner: admin
--

ALTER TABLE ONLY admin.passwd
    ADD CONSTRAINT passwd_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: admin; Owner: admin
--

ALTER TABLE ONLY admin.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: passwd fk_user_id; Type: FK CONSTRAINT; Schema: admin; Owner: admin
--

ALTER TABLE ONLY admin.passwd
    ADD CONSTRAINT fk_user_id FOREIGN KEY (id) REFERENCES admin.users(id);


--
-- Name: SCHEMA admin; Type: ACL; Schema: -; Owner: admin
--

GRANT USAGE ON SCHEMA admin TO webserver;


--
-- Name: SCHEMA logs; Type: ACL; Schema: -; Owner: logger
--

GRANT USAGE ON SCHEMA logs TO webserver;


--
-- Name: FUNCTION check_password(mail character varying, hash text); Type: ACL; Schema: admin; Owner: admin
--

REVOKE ALL ON FUNCTION admin.check_password(mail character varying, hash text) FROM PUBLIC;
GRANT ALL ON FUNCTION admin.check_password(mail character varying, hash text) TO webserver;


--
-- Name: FUNCTION get_user_status(mail character varying); Type: ACL; Schema: admin; Owner: admin
--

REVOKE ALL ON FUNCTION admin.get_user_status(mail character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION admin.get_user_status(mail character varying) TO webserver;


--
-- Name: FUNCTION insert_passwd(mail character varying, passhash text); Type: ACL; Schema: admin; Owner: admin
--

REVOKE ALL ON FUNCTION admin.insert_passwd(mail character varying, passhash text) FROM PUBLIC;
GRANT ALL ON FUNCTION admin.insert_passwd(mail character varying, passhash text) TO webserver;


--
-- Name: FUNCTION insert_user(mail character varying, _role admin.admin_status); Type: ACL; Schema: admin; Owner: admin
--

REVOKE ALL ON FUNCTION admin.insert_user(mail character varying, _role admin.admin_status) FROM PUBLIC;
GRANT ALL ON FUNCTION admin.insert_user(mail character varying, _role admin.admin_status) TO webserver;


--
-- Name: FUNCTION export_access_log(identifier character varying, extension character varying, delimiter character, row_count integer); Type: ACL; Schema: logs; Owner: admin
--

REVOKE ALL ON FUNCTION logs.export_access_log(identifier character varying, extension character varying, delimiter character, row_count integer) FROM PUBLIC;
GRANT ALL ON FUNCTION logs.export_access_log(identifier character varying, extension character varying, delimiter character, row_count integer) TO webserver;


--
-- Name: FUNCTION write_failed_access(email character varying, user_agent text, _ip text); Type: ACL; Schema: logs; Owner: admin
--

REVOKE ALL ON FUNCTION logs.write_failed_access(email character varying, user_agent text, _ip text) FROM PUBLIC;
GRANT ALL ON FUNCTION logs.write_failed_access(email character varying, user_agent text, _ip text) TO webserver;


--
-- PostgreSQL database dump complete
--

