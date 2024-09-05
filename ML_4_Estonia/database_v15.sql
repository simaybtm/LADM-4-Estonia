--
-- PostgreSQL database dump
--

-- Dumped from database version 16.1
-- Dumped by pg_dump version 16.1

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
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS '';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: get_triggers(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_triggers() RETURNS TABLE(table_name text, trigger_name text)
    LANGUAGE plpgsql
    AS $$
begin
	return query select 
	  trg.event_object_table::text AS table_name, 
	  trg.trigger_name::text
	from 
	  information_schema.triggers trg
	group by 
	  table_name, 
	  trg.trigger_name
	order by
	  table_name, 
	  trg.trigger_name;
end;
$$;


--
-- Name: insert_default_administrative_source(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.insert_default_administrative_source() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Insert a dummy entry into LA_AdministrativeSource with laSourceID set to la_source_id
    INSERT INTO LA_AdministrativeSource (la_source_id)
    VALUES (NEW.la_source_id);

    RETURN NEW;
END;
$$;


--
-- Name: insert_default_spatial_source(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.insert_default_spatial_source() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Insert a dummy entry into LA_SpatialSource with laSourceID set to la_source_id
    INSERT INTO LA_SpatialSource (la_source_id)
    VALUES (NEW.la_source_id);

    RETURN NEW;
END;
$$;


--
-- Name: set_la_source_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_la_source_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.la_source_id := nextval('la_source_id_seq');
    RETURN NEW;
END;
$$;


--
-- Name: set_no_name_for_county_unit(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_no_name_for_county_unit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.name = 'NONAME' THEN
        SELECT name INTO NEW.name
        FROM est_county_plan
        WHERE plan_id = NEW.plan_id
        ORDER BY county_plan_id DESC
        LIMIT 1;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: set_no_name_for_master_unit(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_no_name_for_master_unit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.name = 'NONAME' THEN
        SELECT name INTO NEW.name
        FROM est_master_plan
        WHERE plan_id = NEW.plan_id
        ORDER BY master_plan_id DESC
        LIMIT 1;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: set_no_name_for_national_unit(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_no_name_for_national_unit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.name = 'NONAME' THEN
        SELECT name INTO NEW.name
        FROM est_national_plan
        WHERE plan_id = NEW.plan_id
        ORDER BY national_plan_id DESC
        LIMIT 1;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: set_no_name_for_unit(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_no_name_for_unit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if the incoming data has 'NONAME' as the name
    IF NEW.name = 'NONAME' THEN
        -- Retrieve the last created name for the same plan_id from est_detailed_plan
        SELECT name INTO NEW.name
        FROM est_detailed_plan
        WHERE plan_id = NEW.plan_id
        ORDER BY detailed_plan_id DESC
        LIMIT 1;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: set_noname(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_noname() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    existing_name TEXT;
BEGIN
    -- Check if the incoming data has 'NONAME' as the name
    IF NEW.name = 'NONAME' THEN
        BEGIN
            -- Try to retrieve the existing name for the plan_id
            SELECT name INTO existing_name
            FROM est_detailed_plan
            WHERE plan_id = NEW.plan_id
            ORDER BY detailed_plan_id DESC
            LIMIT 1;
        EXCEPTION
            -- Catch the exception if the plan_id doesn't exist
            WHEN NO_DATA_FOUND THEN
                existing_name := NULL;
        END;

        -- If a name is found for the same plan_id, use it
        IF existing_name IS NOT NULL THEN
            NEW.name := existing_name;
        ELSE
            -- If no name is found for the plan_id, generate a new name from the sequence
            NEW.name := 'NoName' || nextval('noname_seq');
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: set_noname_county(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_noname_county() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    existing_name TEXT;
BEGIN
    IF NEW.name = 'NONAME' THEN
        BEGIN
            SELECT name INTO existing_name
            FROM est_county_plan
            WHERE plan_id = NEW.plan_id
            ORDER BY county_plan_id DESC
            LIMIT 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                existing_name := NULL;
        END;

        IF existing_name IS NOT NULL THEN
            NEW.name := existing_name;
        ELSE
            NEW.name := 'NoName' || nextval('noname_seq');
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: set_noname_master(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_noname_master() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    existing_name TEXT;
BEGIN
    IF NEW.name = 'NONAME' THEN
        BEGIN
            SELECT name INTO existing_name
            FROM est_master_plan
            WHERE plan_id = NEW.plan_id
            ORDER BY master_plan_id DESC
            LIMIT 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                existing_name := NULL;
        END;

        IF existing_name IS NOT NULL THEN
            NEW.name := existing_name;
        ELSE
            NEW.name := 'NoName' || nextval('noname_seq');
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: set_noname_national(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_noname_national() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    existing_name TEXT;
BEGIN
    IF NEW.name = 'NONAME' THEN
        BEGIN
            SELECT name INTO existing_name
            FROM est_national_plan
            WHERE plan_id = NEW.plan_id
            ORDER BY national_plan_id DESC
            LIMIT 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                existing_name := NULL;
        END;

        IF existing_name IS NOT NULL THEN
            NEW.name := existing_name;
        ELSE
            NEW.name := 'NoName' || nextval('noname_seq');
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: update_c_plan_beginlifespanlastversion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_c_plan_beginlifespanlastversion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE est_county_plan
    SET begin_lifespan_lastversion = NEW.begin_lifespan_version
    WHERE plan_id = NEW.plan_id
      AND begin_lifespan_version < NEW.begin_lifespan_version;

    RETURN NEW;
END;
$$;


--
-- Name: update_c_unit_beginlifespanlastversion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_c_unit_beginlifespanlastversion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE est_county_unit
    SET begin_lifespan_lastversion = NEW.begin_lifespan_version
    WHERE plan_id = NEW.plan_id
      AND begin_lifespan_version < NEW.begin_lifespan_version;

    RETURN NEW;
END;
$$;


--
-- Name: update_d_plan_beginlifespanlastversion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_d_plan_beginlifespanlastversion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update the begin_lifespan_lastversion for all related records if the new begin_lifespan_version is greater
    UPDATE est_detailed_plan
    SET begin_lifespan_lastversion = NEW.begin_lifespan_version
    WHERE plan_id = NEW.plan_id
      AND begin_lifespan_version < NEW.begin_lifespan_version;

    RETURN NEW;
END;
$$;


--
-- Name: update_d_unit_beginlifespanlastversion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_d_unit_beginlifespanlastversion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update the begin_lifespan_lastversion for all related records if the new begin_lifespan_version is greater
    UPDATE est_detailed_unit
    SET begin_lifespan_lastversion = NEW.begin_lifespan_version
    WHERE plan_id = NEW.plan_id
      AND begin_lifespan_version < NEW.begin_lifespan_version;

    RETURN NEW;
END;
$$;


--
-- Name: update_m_plan_beginlifespanlastversion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_m_plan_beginlifespanlastversion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE est_master_plan
    SET begin_lifespan_lastversion = NEW.begin_lifespan_version
    WHERE plan_id = NEW.plan_id
      AND begin_lifespan_version < NEW.begin_lifespan_version;

    RETURN NEW;
END;
$$;


--
-- Name: update_m_unit_beginlifespanlastversion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_m_unit_beginlifespanlastversion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE est_master_unit
    SET begin_lifespan_lastversion = NEW.begin_lifespan_version
    WHERE plan_id = NEW.plan_id
      AND begin_lifespan_version < NEW.begin_lifespan_version;

    RETURN NEW;
END;
$$;


--
-- Name: update_n_plan_beginlifespanlastversion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_n_plan_beginlifespanlastversion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE est_national_plan
    SET begin_lifespan_lastversion = NEW.begin_lifespan_version
    WHERE plan_id = NEW.plan_id
      AND begin_lifespan_version < NEW.begin_lifespan_version;

    RETURN NEW;
END;
$$;


--
-- Name: update_n_unit_beginlifespanlastversion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_n_unit_beginlifespanlastversion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE est_national_unit
    SET begin_lifespan_lastversion = NEW.begin_lifespan_version
    WHERE plan_id = NEW.plan_id
      AND begin_lifespan_version < NEW.begin_lifespan_version;

    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ci_responsibility; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_responsibility (
    id integer NOT NULL,
    org_name character varying(255) NOT NULL,
    role_code_id integer
);


--
-- Name: ci_responsibility_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_responsibility_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_responsibility_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_responsibility_id_seq OWNED BY public.ci_responsibility.id;


--
-- Name: ci_rolecode; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_rolecode (
    id integer NOT NULL,
    name character varying(255) NOT NULL
);


--
-- Name: ci_rolecode_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_rolecode_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_rolecode_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_rolecode_id_seq OWNED BY public.ci_rolecode.id;


--
-- Name: county_plan_la_source; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.county_plan_la_source (
    county_plan_id integer NOT NULL,
    la_source_id character varying(255) NOT NULL
);


--
-- Name: detailed_plan_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.detailed_plan_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: detailed_plan_la_source; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.detailed_plan_la_source (
    detailed_plan_id character varying NOT NULL,
    la_source_id character varying(255) NOT NULL
);


--
-- Name: detailed_plan_unit_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.detailed_plan_unit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: est_county_plan; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.est_county_plan (
    geometry public.geometry(GeometryZ,3301),
    county_plan_id integer NOT NULL,
    name text,
    organizer_reference text,
    seia_conducted boolean,
    modifies_general_plan boolean,
    planning_objective text,
    hierarchy_level integer,
    label text,
    land_use_type_id integer,
    begin_lifespan_version date,
    begin_real_world_lifespan_version date,
    end_lifespan_version date,
    initiated_date date,
    source_id character varying(255),
    national_plan_id integer
);


--
-- Name: est_county_plan_county_plan_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.est_county_plan_county_plan_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: est_county_plan_county_plan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.est_county_plan_county_plan_id_seq OWNED BY public.est_county_plan.county_plan_id;


--
-- Name: est_county_plan_unit_count; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.est_county_plan_unit_count AS
SELECT
    NULL::integer AS plan_id,
    NULL::text AS plan_name,
    NULL::date AS initiated_date,
    NULL::bigint AS unit_count;


--
-- Name: est_county_unit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.est_county_unit (
    geometry public.geometry(GeometryZ,3301),
    county_plan_unit_id integer NOT NULL,
    county_plan_id integer NOT NULL,
    plan_unit_group_name text,
    begin_lifespan_version date,
    begin_real_world_lifespan_version date,
    end_lifespan_version date,
    initiated_date date
);


--
-- Name: est_county_unit_county_plan_unit_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.est_county_unit_county_plan_unit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: est_county_unit_county_plan_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.est_county_unit_county_plan_unit_id_seq OWNED BY public.est_county_unit.county_plan_unit_id;


--
-- Name: est_detailed_plan_detailed_plan_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.est_detailed_plan_detailed_plan_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: est_detailed_plan; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.est_detailed_plan (
    geometry public.geometry(GeometryZ,3301),
    detailed_plan_id character varying(255) DEFAULT nextval('public.est_detailed_plan_detailed_plan_id_seq'::regclass) NOT NULL,
    name text,
    organizer_reference text,
    seia_conducted boolean,
    modifies_general_plan boolean,
    planning_objective text,
    block_name text,
    constraint_description text[],
    constraint_name text[],
    function_type_id integer,
    begin_lifespan_version date,
    begin_real_world_lifespan_version date,
    end_lifespan_version date,
    plan_id character varying(255),
    master_plan_id integer,
    initiated_date integer,
    begin_lifespan_lastversion date,
    source_id character varying(255)
);


--
-- Name: est_detailed_plan_unit_count; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.est_detailed_plan_unit_count AS
SELECT
    NULL::character varying(255) AS plan_id,
    NULL::text AS plan_name,
    NULL::integer AS initiated_date,
    NULL::bigint AS unit_count;


--
-- Name: est_detailed_unit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.est_detailed_unit (
    geometry public.geometry(GeometryZ,3301),
    detailed_plan_unit_id integer DEFAULT nextval('public.detailed_plan_unit_id_seq'::regclass) NOT NULL,
    detailed_plan_id character varying(255) NOT NULL,
    plan_id character varying,
    name text,
    feature_protected text[],
    max_area_indications integer,
    max_height_indications integer,
    max_volume_indications integer,
    other_construction_indications text[],
    other_indications text[],
    status_type integer,
    sub_function_name text,
    sub_function_type integer,
    surface_relation integer,
    type_of_building_indications text[],
    type_of_shape_indications text[],
    unit_indications integer,
    begin_lifespan_version date,
    begin_real_world_lifespan_version date,
    end_lifespan_version date,
    begin_lifespan_lastversion date,
    initiated_date integer,
    current_area integer,
    current_volume integer,
    discipline character varying,
    global_id character varying,
    element_type character varying,
    conditions character varying,
    description text,
    floor_below_ground character varying,
    floor_above_ground character varying,
    depth_below_ground character varying,
    tile_id integer
);


--
-- Name: est_detailed_unit_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.est_detailed_unit_view AS
 SELECT detailed_plan_unit_id,
    detailed_plan_id,
    plan_id AS source_id,
    name,
    global_id,
    begin_lifespan_version,
    begin_real_world_lifespan_version,
    end_lifespan_version,
    begin_lifespan_lastversion,
    initiated_date,
    discipline,
    element_type,
    conditions,
    description,
    current_area,
    current_volume,
    max_area_indications,
    sub_function_type,
    surface_relation,
    max_height_indications,
    depth_below_ground,
    feature_protected,
    other_construction_indications,
    other_indications,
    sub_function_name,
    type_of_building_indications,
    type_of_shape_indications,
    status_type,
    max_volume_indications,
    unit_indications,
    geometry
   FROM public.est_detailed_unit
  ORDER BY detailed_plan_unit_id;


--
-- Name: est_greennetworktype; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.est_greennetworktype (
    id integer NOT NULL,
    type character varying(255)
);


--
-- Name: est_greennetworktype_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.est_greennetworktype_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: est_greennetworktype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.est_greennetworktype_id_seq OWNED BY public.est_greennetworktype.id;


--
-- Name: est_master_plan; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.est_master_plan (
    geometry public.geometry(GeometryZ,3301),
    master_plan_id integer NOT NULL,
    name text,
    organizer_reference text,
    seia_conducted boolean,
    modifies_general_plan boolean,
    planning_objective text,
    strategic_principle_areas text,
    hierarchy_level integer,
    label text,
    land_use_type_id integer,
    begin_lifespan_version date,
    begin_real_world_lifespan_version date,
    end_lifespan_version date,
    initiated_date date,
    source_id character varying(255),
    county_plan_id integer
);


--
-- Name: est_master_plan_master_plan_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.est_master_plan_master_plan_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: est_master_plan_master_plan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.est_master_plan_master_plan_id_seq OWNED BY public.est_master_plan.master_plan_id;


--
-- Name: est_master_plan_unit_count; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.est_master_plan_unit_count AS
SELECT
    NULL::integer AS plan_id,
    NULL::text AS plan_name,
    NULL::date AS initiated_date,
    NULL::bigint AS unit_count;


--
-- Name: est_master_unit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.est_master_unit (
    geometry public.geometry(GeometryZ,3301),
    master_plan_unit_id integer NOT NULL,
    master_plan_id integer NOT NULL,
    plan_unit_group_name text,
    land_use_symbol text,
    begin_lifespan_version date,
    begin_real_world_lifespan_version date,
    end_lifespan_version date,
    initiated_date date
);


--
-- Name: est_master_unit_master_plan_unit_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.est_master_unit_master_plan_unit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: est_master_unit_master_plan_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.est_master_unit_master_plan_unit_id_seq OWNED BY public.est_master_unit.master_plan_unit_id;


--
-- Name: est_national_plan; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.est_national_plan (
    geometry public.geometry(GeometryZ,3301),
    national_plan_id integer NOT NULL,
    description text,
    hierarchy_level integer,
    label text,
    begin_lifespan_version date,
    begin_real_world_lifespan_version date,
    end_lifespan_version date,
    initiated_date date,
    source_id character varying(255)
);


--
-- Name: est_national_plan_national_plan_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.est_national_plan_national_plan_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: est_national_plan_national_plan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.est_national_plan_national_plan_id_seq OWNED BY public.est_national_plan.national_plan_id;


--
-- Name: est_national_plan_unit_count; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.est_national_plan_unit_count AS
SELECT
    NULL::integer AS plan_id,
    NULL::text AS plan_name,
    NULL::date AS initiated_date,
    NULL::bigint AS unit_count;


--
-- Name: est_national_unit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.est_national_unit (
    geometry public.geometry(GeometryZ,3301),
    national_plan_unit_id integer NOT NULL,
    plan_unit_group_name text,
    begin_lifespan_version date,
    begin_real_world_lifespan_version date,
    end_lifespan_version date,
    initiated_date date,
    national_plan_id integer NOT NULL
);


--
-- Name: est_national_unit_national_plan_unit_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.est_national_unit_national_plan_unit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: est_national_unit_national_plan_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.est_national_unit_national_plan_unit_id_seq OWNED BY public.est_national_unit.national_plan_unit_id;


--
-- Name: est_transportinfrastructuretype; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.est_transportinfrastructuretype (
    id integer NOT NULL,
    type character varying(255)
);


--
-- Name: est_transportinfrastructuretype_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.est_transportinfrastructuretype_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: est_transportinfrastructuretype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.est_transportinfrastructuretype_id_seq OWNED BY public.est_transportinfrastructuretype.id;


--
-- Name: la_administrativesource; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.la_administrativesource (
    administrative_id integer NOT NULL,
    text character varying(255),
    la_source_id character varying(255)
);


--
-- Name: la_administrativesource_sid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.la_administrativesource_sid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: la_administrativesource_sid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.la_administrativesource_sid_seq OWNED BY public.la_administrativesource.administrative_id;


--
-- Name: la_mediatype; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.la_mediatype (
    id integer NOT NULL,
    type character varying(255)
);


--
-- Name: la_mediatype_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.la_mediatype_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: la_mediatype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.la_mediatype_id_seq OWNED BY public.la_mediatype.id;


--
-- Name: la_multimediatype; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.la_multimediatype (
    id integer NOT NULL,
    type character varying(255)
);


--
-- Name: la_multimediatype_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.la_multimediatype_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: la_multimediatype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.la_multimediatype_id_seq OWNED BY public.la_multimediatype.id;


--
-- Name: la_source_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.la_source_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: la_source; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.la_source (
    la_source_id character varying(255) DEFAULT nextval('public.la_source_id_seq'::regclass) NOT NULL,
    acceptance date,
    availability_status text,
    ext_archivel_id integer,
    life_span_stamp date,
    maintype text,
    quality text[],
    recordation date,
    submission date,
    source integer,
    plan_id character varying
);


--
-- Name: la_spatialsource; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.la_spatialsource (
    spatial_id integer NOT NULL,
    media character varying(255),
    surveypurpose character varying(255),
    type character varying(255),
    plannername character varying(255),
    draftsmanname character varying(255),
    datamodel integer,
    coordinatesystem character varying(255),
    correctionsystem character varying(255),
    scale integer,
    contact character varying(255),
    la_source_id character varying(255)
);


--
-- Name: la_spatialsource_sid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.la_spatialsource_sid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: la_spatialsource_sid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.la_spatialsource_sid_seq OWNED BY public.la_spatialsource.spatial_id;


--
-- Name: la_spatialsourcetype; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.la_spatialsourcetype (
    id integer NOT NULL,
    type character varying(255)
);


--
-- Name: la_spatialsourcetype_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.la_spatialsourcetype_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: la_spatialsourcetype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.la_spatialsourcetype_id_seq OWNED BY public.la_spatialsourcetype.id;


--
-- Name: la_surfacerelationtype; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.la_surfacerelationtype (
    id integer NOT NULL,
    type character varying(255)
);


--
-- Name: la_surfacerelationtype_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.la_surfacerelationtype_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: la_surfacerelationtype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.la_surfacerelationtype_id_seq OWNED BY public.la_surfacerelationtype.id;


--
-- Name: la_surveypurposetype; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.la_surveypurposetype (
    id integer NOT NULL,
    type character varying(255)
);


--
-- Name: la_surveypurposetype_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.la_surveypurposetype_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: la_surveypurposetype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.la_surveypurposetype_id_seq OWNED BY public.la_surveypurposetype.id;


--
-- Name: master_plan_la_source; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.master_plan_la_source (
    master_plan_id integer NOT NULL,
    la_source_id character varying(255) NOT NULL
);


--
-- Name: national_plan_la_source; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.national_plan_la_source (
    national_plan_id integer NOT NULL,
    la_source_id character varying(255) NOT NULL
);


--
-- Name: noname_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.noname_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sp_higherlevelspacefunction; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sp_higherlevelspacefunction (
    id integer NOT NULL,
    type character varying(255)
);


--
-- Name: sp_higherlevelspacefunction_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sp_higherlevelspacefunction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sp_higherlevelspacefunction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sp_higherlevelspacefunction_id_seq OWNED BY public.sp_higherlevelspacefunction.id;


--
-- Name: sp_permit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sp_permit (
    pid integer NOT NULL,
    decision_date date,
    description text,
    duration text[],
    name text,
    period text[],
    type_of_permit_id integer,
    detailed_unit_id integer
);


--
-- Name: sp_permit_pid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sp_permit_pid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sp_permit_pid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sp_permit_pid_seq OWNED BY public.sp_permit.pid;


--
-- Name: sp_permittype; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sp_permittype (
    id integer NOT NULL,
    type character varying(255)
);


--
-- Name: sp_permittype_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sp_permittype_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sp_permittype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sp_permittype_id_seq OWNED BY public.sp_permittype.id;


--
-- Name: sp_spacefunctiontype; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sp_spacefunctiontype (
    id integer NOT NULL,
    type character varying(255)
);


--
-- Name: sp_spacefunctiontype_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sp_spacefunctiontype_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sp_spacefunctiontype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sp_spacefunctiontype_id_seq OWNED BY public.sp_spacefunctiontype.id;


--
-- Name: sp_statustype; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sp_statustype (
    id integer NOT NULL,
    type character varying(255)
);


--
-- Name: sp_statustype_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sp_statustype_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sp_statustype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sp_statustype_id_seq OWNED BY public.sp_statustype.id;


--
-- Name: sp_subspacefunctiontype; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sp_subspacefunctiontype (
    id integer NOT NULL,
    type character varying(255)
);


--
-- Name: sp_subspacefunctiontype_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sp_subspacefunctiontype_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sp_subspacefunctiontype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sp_subspacefunctiontype_id_seq OWNED BY public.sp_subspacefunctiontype.id;


--
-- Name: tile_sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tile_sets (
    id integer NOT NULL,
    name character varying(255),
    url text,
    access_token text
);


--
-- Name: tile_sets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tile_sets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tile_sets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tile_sets_id_seq OWNED BY public.tile_sets.id;


--
-- Name: ci_responsibility id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_responsibility ALTER COLUMN id SET DEFAULT nextval('public.ci_responsibility_id_seq'::regclass);


--
-- Name: ci_rolecode id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_rolecode ALTER COLUMN id SET DEFAULT nextval('public.ci_rolecode_id_seq'::regclass);


--
-- Name: est_county_plan county_plan_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_county_plan ALTER COLUMN county_plan_id SET DEFAULT nextval('public.est_county_plan_county_plan_id_seq'::regclass);


--
-- Name: est_county_unit county_plan_unit_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_county_unit ALTER COLUMN county_plan_unit_id SET DEFAULT nextval('public.est_county_unit_county_plan_unit_id_seq'::regclass);


--
-- Name: est_greennetworktype id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_greennetworktype ALTER COLUMN id SET DEFAULT nextval('public.est_greennetworktype_id_seq'::regclass);


--
-- Name: est_master_plan master_plan_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_master_plan ALTER COLUMN master_plan_id SET DEFAULT nextval('public.est_master_plan_master_plan_id_seq'::regclass);


--
-- Name: est_master_unit master_plan_unit_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_master_unit ALTER COLUMN master_plan_unit_id SET DEFAULT nextval('public.est_master_unit_master_plan_unit_id_seq'::regclass);


--
-- Name: est_national_plan national_plan_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_national_plan ALTER COLUMN national_plan_id SET DEFAULT nextval('public.est_national_plan_national_plan_id_seq'::regclass);


--
-- Name: est_national_unit national_plan_unit_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_national_unit ALTER COLUMN national_plan_unit_id SET DEFAULT nextval('public.est_national_unit_national_plan_unit_id_seq'::regclass);


--
-- Name: est_transportinfrastructuretype id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_transportinfrastructuretype ALTER COLUMN id SET DEFAULT nextval('public.est_transportinfrastructuretype_id_seq'::regclass);


--
-- Name: la_administrativesource administrative_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.la_administrativesource ALTER COLUMN administrative_id SET DEFAULT nextval('public.la_administrativesource_sid_seq'::regclass);


--
-- Name: la_mediatype id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.la_mediatype ALTER COLUMN id SET DEFAULT nextval('public.la_mediatype_id_seq'::regclass);


--
-- Name: la_multimediatype id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.la_multimediatype ALTER COLUMN id SET DEFAULT nextval('public.la_multimediatype_id_seq'::regclass);


--
-- Name: la_spatialsource spatial_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.la_spatialsource ALTER COLUMN spatial_id SET DEFAULT nextval('public.la_spatialsource_sid_seq'::regclass);


--
-- Name: la_spatialsourcetype id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.la_spatialsourcetype ALTER COLUMN id SET DEFAULT nextval('public.la_spatialsourcetype_id_seq'::regclass);


--
-- Name: la_surfacerelationtype id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.la_surfacerelationtype ALTER COLUMN id SET DEFAULT nextval('public.la_surfacerelationtype_id_seq'::regclass);


--
-- Name: la_surveypurposetype id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.la_surveypurposetype ALTER COLUMN id SET DEFAULT nextval('public.la_surveypurposetype_id_seq'::regclass);


--
-- Name: sp_higherlevelspacefunction id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sp_higherlevelspacefunction ALTER COLUMN id SET DEFAULT nextval('public.sp_higherlevelspacefunction_id_seq'::regclass);


--
-- Name: sp_permit pid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sp_permit ALTER COLUMN pid SET DEFAULT nextval('public.sp_permit_pid_seq'::regclass);


--
-- Name: sp_permittype id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sp_permittype ALTER COLUMN id SET DEFAULT nextval('public.sp_permittype_id_seq'::regclass);


--
-- Name: sp_spacefunctiontype id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sp_spacefunctiontype ALTER COLUMN id SET DEFAULT nextval('public.sp_spacefunctiontype_id_seq'::regclass);


--
-- Name: sp_statustype id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sp_statustype ALTER COLUMN id SET DEFAULT nextval('public.sp_statustype_id_seq'::regclass);


--
-- Name: sp_subspacefunctiontype id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sp_subspacefunctiontype ALTER COLUMN id SET DEFAULT nextval('public.sp_subspacefunctiontype_id_seq'::regclass);


--
-- Name: tile_sets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tile_sets ALTER COLUMN id SET DEFAULT nextval('public.tile_sets_id_seq'::regclass);


--
-- Data for Name: ci_responsibility; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ci_responsibility (id, org_name, role_code_id) FROM stdin;
\.


--
-- Data for Name: ci_rolecode; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ci_rolecode (id, name) FROM stdin;
1	architect
2	planner
3	resourceProvider
4	custodian
5	owner
6	user
7	distributor
8	originator
9	pointOfContact
10	principalinvestigator
11	processor
12	publisher
13	author
14	sponsor
15	coAuthor
16	collaborator
17	editor
18	mediator
19	rightsHolder
20	contributor
21	funder
22	stakeholder
\.


--
-- Data for Name: county_plan_la_source; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.county_plan_la_source (county_plan_id, la_source_id) FROM stdin;
\.


--
-- Data for Name: detailed_plan_la_source; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.detailed_plan_la_source (detailed_plan_id, la_source_id) FROM stdin;
\.


--
-- Data for Name: est_county_plan; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.est_county_plan (geometry, county_plan_id, name, organizer_reference, seia_conducted, modifies_general_plan, planning_objective, hierarchy_level, label, land_use_type_id, begin_lifespan_version, begin_real_world_lifespan_version, end_lifespan_version, initiated_date, source_id, national_plan_id) FROM stdin;
\.


--
-- Data for Name: est_county_unit; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.est_county_unit (geometry, county_plan_unit_id, county_plan_id, plan_unit_group_name, begin_lifespan_version, begin_real_world_lifespan_version, end_lifespan_version, initiated_date) FROM stdin;
\.


--
-- Data for Name: est_detailed_plan; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.est_detailed_plan (geometry, detailed_plan_id, name, organizer_reference, seia_conducted, modifies_general_plan, planning_objective, block_name, constraint_description, constraint_name, function_type_id, begin_lifespan_version, begin_real_world_lifespan_version, end_lifespan_version, plan_id, master_plan_id, initiated_date, begin_lifespan_lastversion, source_id) FROM stdin;
\.


--
-- Data for Name: est_detailed_unit; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.est_detailed_unit (geometry, detailed_plan_unit_id, detailed_plan_id, plan_id, name, feature_protected, max_area_indications, max_height_indications, max_volume_indications, other_construction_indications, other_indications, status_type, sub_function_name, sub_function_type, surface_relation, type_of_building_indications, type_of_shape_indications, unit_indications, begin_lifespan_version, begin_real_world_lifespan_version, end_lifespan_version, begin_lifespan_lastversion, initiated_date, current_area, current_volume, discipline, global_id, element_type, conditions, description, floor_below_ground, floor_above_ground, depth_below_ground, tile_id) FROM stdin;
\.


--
-- Data for Name: est_greennetworktype; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.est_greennetworktype (id, type) FROM stdin;
1	Corridor [Koridor]
2	CoreArea [Tugiala]
3	ConflictArea [Konfliktiala]
\.


--
-- Data for Name: est_master_plan; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.est_master_plan (geometry, master_plan_id, name, organizer_reference, seia_conducted, modifies_general_plan, planning_objective, strategic_principle_areas, hierarchy_level, label, land_use_type_id, begin_lifespan_version, begin_real_world_lifespan_version, end_lifespan_version, initiated_date, source_id, county_plan_id) FROM stdin;
\.


--
-- Data for Name: est_master_unit; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.est_master_unit (geometry, master_plan_unit_id, master_plan_id, plan_unit_group_name, land_use_symbol, begin_lifespan_version, begin_real_world_lifespan_version, end_lifespan_version, initiated_date) FROM stdin;
\.


--
-- Data for Name: est_national_plan; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.est_national_plan (geometry, national_plan_id, description, hierarchy_level, label, begin_lifespan_version, begin_real_world_lifespan_version, end_lifespan_version, initiated_date, source_id) FROM stdin;
\.


--
-- Data for Name: est_national_unit; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.est_national_unit (geometry, national_plan_unit_id, plan_unit_group_name, begin_lifespan_version, begin_real_world_lifespan_version, end_lifespan_version, initiated_date, national_plan_id) FROM stdin;
\.


--
-- Data for Name: est_transportinfrastructuretype; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.est_transportinfrastructuretype (id, type) FROM stdin;
1	Roads [Teed]
2	Railways [Raudteed]
3	PedestrianPaths [Jalakäijate teed]
4	CyclingPaths [Jalgrattateed]
\.


--
-- Data for Name: la_administrativesource; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.la_administrativesource (administrative_id, text, la_source_id) FROM stdin;
\.


--
-- Data for Name: la_mediatype; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.la_mediatype (id, type) FROM stdin;
1	jpeg
2	png
3	tiff
4	emf
5	wmf
6	adf
7	docx
8	pdf
\.


--
-- Data for Name: la_multimediatype; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.la_multimediatype (id, type) FROM stdin;
1	video
2	sketch
3	pointCloud
4	image
5	scannedMap
6	digitizedMap
7	DB
\.


--
-- Data for Name: la_source; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.la_source (la_source_id, acceptance, availability_status, ext_archivel_id, life_span_stamp, maintype, quality, recordation, submission, source, plan_id) FROM stdin;
\.


--
-- Data for Name: la_spatialsource; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.la_spatialsource (spatial_id, media, surveypurpose, type, plannername, draftsmanname, datamodel, coordinatesystem, correctionsystem, scale, contact, la_source_id) FROM stdin;
\.


--
-- Data for Name: la_spatialsourcetype; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.la_spatialsourcetype (id, type) FROM stdin;
1	aeriallmage
2	analogueMap
3	BIMDesign
4	CADFile
5	DB
6	GNSSSurveyFile
7	image
8	levellingSurvey File
9	lidar
10	other
11	pointcloud
12	RADAR
13	satellitelmage
14	scannedMap
15	totalStationSurveyFile
16	video
\.


--
-- Data for Name: la_surfacerelationtype; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.la_surfacerelationtype (id, type) FROM stdin;
1	mixed [Segatüüp]
2	below [Maa-alune]
3	above [Maapealne]
4	onSurface
\.


--
-- Data for Name: la_surveypurposetype; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.la_surveypurposetype (id, type) FROM stdin;
1	amalgamation
2	asMaidMeasurements
3	boundaryDelineation
4	boundaryReconstruction
5	constructionPermit
6	controlMeasurement
7	deedRegistration
8	demolitionPermit
9	landConsolidation
10	other
11	spatialplanning
12	subdivision
13	titleRegistration
\.


--
-- Data for Name: master_plan_la_source; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.master_plan_la_source (master_plan_id, la_source_id) FROM stdin;
\.


--
-- Data for Name: national_plan_la_source; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.national_plan_la_source (national_plan_id, la_source_id) FROM stdin;
\.


--
-- Data for Name: sp_higherlevelspacefunction; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sp_higherlevelspacefunction (id, type) FROM stdin;
1	industry
2	residential
3	nature
4	infrastructure
5	agriculture
6	commercial
\.


--
-- Data for Name: sp_permit; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sp_permit (pid, decision_date, description, duration, name, period, type_of_permit_id, detailed_unit_id) FROM stdin;
\.


--
-- Data for Name: sp_permittype; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sp_permittype (id, type) FROM stdin;
1	allowed
2	conditional
3	restricted
\.


--
-- Data for Name: sp_spacefunctiontype; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sp_spacefunctiontype (id, type) FROM stdin;
1	protectedLocal
2	protectedWaterCatchment
3	protectedForest
4	protectedOpenGreenSpace
5	protectedNaturalReserveAndCulturalHeritage
6	protectedNaturalDisaster
7	protectedOther
8	cultivationHousing
9	cultivationMixed
10	cultivationTradeAndCommerce
11	cultivationOfficeSpace
12	cultivationPublicFacility
13	cultivationIndustry
14	cultivationResidential
15	cultivationSpecific
16	cultivationOther
\.


--
-- Data for Name: sp_statustype; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sp_statustype (id, type) FROM stdin;
1	inUse
2	outOfUse
3	planned
\.


--
-- Data for Name: sp_subspacefunctiontype; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sp_subspacefunctiontype (id, type) FROM stdin;
1	apartment
2	serviceApartment
3	condominium
4	lowCostHousing
5	flat
6	shop
7	supermarket
8	retail
9	traditionalMarket
10	workshop
11	office
12	education
13	culture
14	factory
15	healthService
16	parking
\.


--
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- Data for Name: tile_sets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tile_sets (id, name, url, access_token) FROM stdin;
\.


--
-- Name: ci_responsibility_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.ci_responsibility_id_seq', 1, false);


--
-- Name: ci_rolecode_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.ci_rolecode_id_seq', 1, false);


--
-- Name: detailed_plan_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.detailed_plan_id_seq', 1, false);


--
-- Name: detailed_plan_unit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.detailed_plan_unit_id_seq', 1, false);


--
-- Name: est_county_plan_county_plan_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.est_county_plan_county_plan_id_seq', 1, false);


--
-- Name: est_county_unit_county_plan_unit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.est_county_unit_county_plan_unit_id_seq', 1, false);


--
-- Name: est_detailed_plan_detailed_plan_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.est_detailed_plan_detailed_plan_id_seq', 1, false);


--
-- Name: est_greennetworktype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.est_greennetworktype_id_seq', 1, false);


--
-- Name: est_master_plan_master_plan_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.est_master_plan_master_plan_id_seq', 1, false);


--
-- Name: est_master_unit_master_plan_unit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.est_master_unit_master_plan_unit_id_seq', 1, false);


--
-- Name: est_national_plan_national_plan_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.est_national_plan_national_plan_id_seq', 1, false);


--
-- Name: est_national_unit_national_plan_unit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.est_national_unit_national_plan_unit_id_seq', 1, false);


--
-- Name: est_transportinfrastructuretype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.est_transportinfrastructuretype_id_seq', 1, false);


--
-- Name: la_administrativesource_sid_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.la_administrativesource_sid_seq', 1, false);


--
-- Name: la_mediatype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.la_mediatype_id_seq', 1, false);


--
-- Name: la_multimediatype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.la_multimediatype_id_seq', 1, false);


--
-- Name: la_source_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.la_source_id_seq', 1, false);


--
-- Name: la_spatialsource_sid_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.la_spatialsource_sid_seq', 1, false);


--
-- Name: la_spatialsourcetype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.la_spatialsourcetype_id_seq', 1, false);


--
-- Name: la_surfacerelationtype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.la_surfacerelationtype_id_seq', 1, false);


--
-- Name: la_surveypurposetype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.la_surveypurposetype_id_seq', 1, false);


--
-- Name: noname_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.noname_seq', 1, false);


--
-- Name: sp_higherlevelspacefunction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sp_higherlevelspacefunction_id_seq', 1, false);


--
-- Name: sp_permit_pid_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sp_permit_pid_seq', 1, false);


--
-- Name: sp_permittype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sp_permittype_id_seq', 1, false);


--
-- Name: sp_spacefunctiontype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sp_spacefunctiontype_id_seq', 1, false);


--
-- Name: sp_statustype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sp_statustype_id_seq', 1, false);


--
-- Name: sp_subspacefunctiontype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sp_subspacefunctiontype_id_seq', 1, false);


--
-- Name: tile_sets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tile_sets_id_seq', 1, false);


--
-- Name: ci_responsibility ci_responsibility_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_responsibility
    ADD CONSTRAINT ci_responsibility_pkey PRIMARY KEY (id);


--
-- Name: ci_rolecode ci_rolecode_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_rolecode
    ADD CONSTRAINT ci_rolecode_pkey PRIMARY KEY (id);


--
-- Name: county_plan_la_source county_plan_la_source_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.county_plan_la_source
    ADD CONSTRAINT county_plan_la_source_pkey PRIMARY KEY (county_plan_id, la_source_id);


--
-- Name: detailed_plan_la_source detailed_plan_la_source_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detailed_plan_la_source
    ADD CONSTRAINT detailed_plan_la_source_pkey PRIMARY KEY (detailed_plan_id, la_source_id);


--
-- Name: est_county_plan est_county_plan_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_county_plan
    ADD CONSTRAINT est_county_plan_pkey PRIMARY KEY (county_plan_id);


--
-- Name: est_county_unit est_county_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_county_unit
    ADD CONSTRAINT est_county_unit_pkey PRIMARY KEY (county_plan_unit_id);


--
-- Name: est_detailed_plan est_detailed_plan_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_detailed_plan
    ADD CONSTRAINT est_detailed_plan_pkey PRIMARY KEY (detailed_plan_id);


--
-- Name: est_detailed_unit est_detailed_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_detailed_unit
    ADD CONSTRAINT est_detailed_unit_pkey PRIMARY KEY (detailed_plan_unit_id);


--
-- Name: est_greennetworktype est_greennetworktype_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_greennetworktype
    ADD CONSTRAINT est_greennetworktype_pkey PRIMARY KEY (id);


--
-- Name: est_master_plan est_master_plan_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_master_plan
    ADD CONSTRAINT est_master_plan_pkey PRIMARY KEY (master_plan_id);


--
-- Name: est_master_unit est_master_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_master_unit
    ADD CONSTRAINT est_master_unit_pkey PRIMARY KEY (master_plan_unit_id);


--
-- Name: est_national_plan est_national_plan_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_national_plan
    ADD CONSTRAINT est_national_plan_pkey PRIMARY KEY (national_plan_id);


--
-- Name: est_national_unit est_national_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_national_unit
    ADD CONSTRAINT est_national_unit_pkey PRIMARY KEY (national_plan_unit_id);


--
-- Name: est_transportinfrastructuretype est_transportinfrastructuretype_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_transportinfrastructuretype
    ADD CONSTRAINT est_transportinfrastructuretype_pkey PRIMARY KEY (id);


--
-- Name: la_administrativesource la_administrativesource_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.la_administrativesource
    ADD CONSTRAINT la_administrativesource_pkey PRIMARY KEY (administrative_id);


--
-- Name: la_mediatype la_mediatype_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.la_mediatype
    ADD CONSTRAINT la_mediatype_pkey PRIMARY KEY (id);


--
-- Name: la_multimediatype la_multimediatype_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.la_multimediatype
    ADD CONSTRAINT la_multimediatype_pkey PRIMARY KEY (id);


--
-- Name: la_source la_source_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.la_source
    ADD CONSTRAINT la_source_pkey PRIMARY KEY (la_source_id);


--
-- Name: la_spatialsource la_spatialsource_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.la_spatialsource
    ADD CONSTRAINT la_spatialsource_pkey PRIMARY KEY (spatial_id);


--
-- Name: la_spatialsourcetype la_spatialsourcetype_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.la_spatialsourcetype
    ADD CONSTRAINT la_spatialsourcetype_pkey PRIMARY KEY (id);


--
-- Name: la_surfacerelationtype la_surfacerelationtype_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.la_surfacerelationtype
    ADD CONSTRAINT la_surfacerelationtype_pkey PRIMARY KEY (id);


--
-- Name: la_surveypurposetype la_surveypurposetype_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.la_surveypurposetype
    ADD CONSTRAINT la_surveypurposetype_pkey PRIMARY KEY (id);


--
-- Name: master_plan_la_source master_plan_la_source_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_plan_la_source
    ADD CONSTRAINT master_plan_la_source_pkey PRIMARY KEY (master_plan_id, la_source_id);


--
-- Name: national_plan_la_source national_plan_la_source_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.national_plan_la_source
    ADD CONSTRAINT national_plan_la_source_pkey PRIMARY KEY (national_plan_id, la_source_id);


--
-- Name: sp_higherlevelspacefunction sp_higherlevelspacefunction_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sp_higherlevelspacefunction
    ADD CONSTRAINT sp_higherlevelspacefunction_pkey PRIMARY KEY (id);


--
-- Name: sp_permit sp_permit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sp_permit
    ADD CONSTRAINT sp_permit_pkey PRIMARY KEY (pid);


--
-- Name: sp_permittype sp_permittype_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sp_permittype
    ADD CONSTRAINT sp_permittype_pkey PRIMARY KEY (id);


--
-- Name: sp_spacefunctiontype sp_spacefunctiontype_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sp_spacefunctiontype
    ADD CONSTRAINT sp_spacefunctiontype_pkey PRIMARY KEY (id);


--
-- Name: sp_statustype sp_statustype_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sp_statustype
    ADD CONSTRAINT sp_statustype_pkey PRIMARY KEY (id);


--
-- Name: sp_subspacefunctiontype sp_subspacefunctiontype_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sp_subspacefunctiontype
    ADD CONSTRAINT sp_subspacefunctiontype_pkey PRIMARY KEY (id);


--
-- Name: tile_sets tile_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tile_sets
    ADD CONSTRAINT tile_sets_pkey PRIMARY KEY (id);


--
-- Name: idx_begin_lifespan_version; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_begin_lifespan_version ON public.est_detailed_unit USING btree (begin_lifespan_version);


--
-- Name: idx_detailed_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_detailed_plan_id ON public.est_detailed_unit USING btree (detailed_plan_id);


--
-- Name: idx_la_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_la_source_id ON public.la_source USING btree (la_source_id);


--
-- Name: est_county_plan_unit_count _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.est_county_plan_unit_count AS
 SELECT p.county_plan_id AS plan_id,
    p.name AS plan_name,
    p.initiated_date,
    count(u.county_plan_unit_id) AS unit_count
   FROM (public.est_county_plan p
     LEFT JOIN public.est_county_unit u ON ((p.county_plan_id = u.county_plan_id)))
  GROUP BY p.county_plan_id, p.name
  ORDER BY p.county_plan_id;


--
-- Name: est_detailed_plan_unit_count _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.est_detailed_plan_unit_count AS
 SELECT p.detailed_plan_id AS plan_id,
    p.name AS plan_name,
    p.initiated_date,
    count(u.detailed_plan_unit_id) AS unit_count
   FROM (public.est_detailed_plan p
     LEFT JOIN public.est_detailed_unit u ON (((p.detailed_plan_id)::text = (u.detailed_plan_id)::text)))
  GROUP BY p.detailed_plan_id, p.name
  ORDER BY p.detailed_plan_id;


--
-- Name: est_master_plan_unit_count _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.est_master_plan_unit_count AS
 SELECT p.master_plan_id AS plan_id,
    p.name AS plan_name,
    p.initiated_date,
    count(u.master_plan_unit_id) AS unit_count
   FROM (public.est_master_plan p
     LEFT JOIN public.est_master_unit u ON ((p.master_plan_id = u.master_plan_id)))
  GROUP BY p.master_plan_id, p.name
  ORDER BY p.master_plan_id;


--
-- Name: est_national_plan_unit_count _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.est_national_plan_unit_count AS
 SELECT p.national_plan_id AS plan_id,
    p.description AS plan_name,
    p.initiated_date,
    count(u.national_plan_unit_id) AS unit_count
   FROM (public.est_national_plan p
     LEFT JOIN public.est_national_unit u ON ((p.national_plan_id = u.national_plan_id)))
  GROUP BY p.national_plan_id, p.description
  ORDER BY p.national_plan_id;


--
-- Name: la_source insert_default_administrative_source_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER insert_default_administrative_source_trigger AFTER INSERT ON public.la_source FOR EACH ROW EXECUTE FUNCTION public.insert_default_administrative_source();


--
-- Name: la_source insert_default_spatial_source_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER insert_default_spatial_source_trigger AFTER INSERT ON public.la_source FOR EACH ROW EXECUTE FUNCTION public.insert_default_spatial_source();


--
-- Name: la_source set_la_source_id_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_la_source_id_trigger BEFORE INSERT ON public.la_source FOR EACH ROW EXECUTE FUNCTION public.set_la_source_id();


--
-- Name: est_detailed_plan set_noname_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_noname_trigger BEFORE INSERT OR UPDATE ON public.est_detailed_plan FOR EACH ROW EXECUTE FUNCTION public.set_noname();


--
-- Name: est_detailed_plan trg_update_d_plan_beginlifespanlastversion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_update_d_plan_beginlifespanlastversion AFTER INSERT OR UPDATE ON public.est_detailed_plan FOR EACH ROW EXECUTE FUNCTION public.update_d_plan_beginlifespanlastversion();


--
-- Name: est_detailed_plan trg_update_d_plan_lifespan; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_update_d_plan_lifespan AFTER INSERT OR UPDATE ON public.est_detailed_plan FOR EACH ROW EXECUTE FUNCTION public.update_d_plan_beginlifespanlastversion();


--
-- Name: est_detailed_unit trg_update_d_unit_beginlifespanlastversion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_update_d_unit_beginlifespanlastversion AFTER INSERT OR UPDATE ON public.est_detailed_unit FOR EACH ROW EXECUTE FUNCTION public.update_d_unit_beginlifespanlastversion();


--
-- Name: est_detailed_unit trg_update_d_unit_lifespan; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_update_d_unit_lifespan AFTER INSERT OR UPDATE ON public.est_detailed_unit FOR EACH ROW EXECUTE FUNCTION public.update_d_unit_beginlifespanlastversion();


--
-- Name: est_detailed_unit update_unit_name_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_unit_name_trigger BEFORE INSERT ON public.est_detailed_unit FOR EACH ROW EXECUTE FUNCTION public.set_no_name_for_unit();


--
-- Name: county_plan_la_source county_plan_la_source_la_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.county_plan_la_source
    ADD CONSTRAINT county_plan_la_source_la_source_id_fkey FOREIGN KEY (la_source_id) REFERENCES public.la_source(la_source_id);


--
-- Name: detailed_plan_la_source detailed_plan_la_source_la_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detailed_plan_la_source
    ADD CONSTRAINT detailed_plan_la_source_la_source_id_fkey FOREIGN KEY (la_source_id) REFERENCES public.la_source(la_source_id);


--
-- Name: est_county_plan est_county_plan_land_use_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_county_plan
    ADD CONSTRAINT est_county_plan_land_use_type_id_fkey FOREIGN KEY (land_use_type_id) REFERENCES public.sp_higherlevelspacefunction(id);


--
-- Name: est_county_plan est_county_plan_national_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_county_plan
    ADD CONSTRAINT est_county_plan_national_plan_id_fkey FOREIGN KEY (national_plan_id) REFERENCES public.est_national_plan(national_plan_id);


--
-- Name: est_county_plan est_county_plan_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_county_plan
    ADD CONSTRAINT est_county_plan_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.la_source(la_source_id);


--
-- Name: est_county_unit est_county_unit_county_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_county_unit
    ADD CONSTRAINT est_county_unit_county_plan_id_fkey FOREIGN KEY (county_plan_id) REFERENCES public.est_county_plan(county_plan_id);


--
-- Name: est_detailed_plan est_detailed_plan_function_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_detailed_plan
    ADD CONSTRAINT est_detailed_plan_function_type_id_fkey FOREIGN KEY (function_type_id) REFERENCES public.sp_spacefunctiontype(id);


--
-- Name: est_detailed_plan est_detailed_plan_master_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_detailed_plan
    ADD CONSTRAINT est_detailed_plan_master_plan_id_fkey FOREIGN KEY (master_plan_id) REFERENCES public.est_master_plan(master_plan_id);


--
-- Name: est_detailed_unit est_detailed_unit_status_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_detailed_unit
    ADD CONSTRAINT est_detailed_unit_status_type_id_fkey FOREIGN KEY (status_type) REFERENCES public.sp_statustype(id);


--
-- Name: est_detailed_unit est_detailed_unit_sub_function_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_detailed_unit
    ADD CONSTRAINT est_detailed_unit_sub_function_type_id_fkey FOREIGN KEY (sub_function_type) REFERENCES public.sp_subspacefunctiontype(id);


--
-- Name: est_detailed_unit est_detailed_unit_surface_relation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_detailed_unit
    ADD CONSTRAINT est_detailed_unit_surface_relation_id_fkey FOREIGN KEY (surface_relation) REFERENCES public.la_surfacerelationtype(id);


--
-- Name: est_master_plan est_master_plan_county_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_master_plan
    ADD CONSTRAINT est_master_plan_county_plan_id_fkey FOREIGN KEY (county_plan_id) REFERENCES public.est_county_plan(county_plan_id);


--
-- Name: est_master_plan est_master_plan_land_use_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_master_plan
    ADD CONSTRAINT est_master_plan_land_use_type_id_fkey FOREIGN KEY (land_use_type_id) REFERENCES public.sp_higherlevelspacefunction(id);


--
-- Name: est_master_plan est_master_plan_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_master_plan
    ADD CONSTRAINT est_master_plan_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.la_source(la_source_id);


--
-- Name: est_master_unit est_master_unit_master_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_master_unit
    ADD CONSTRAINT est_master_unit_master_plan_id_fkey FOREIGN KEY (master_plan_id) REFERENCES public.est_master_plan(master_plan_id);


--
-- Name: est_national_plan est_national_plan_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_national_plan
    ADD CONSTRAINT est_national_plan_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.la_source(la_source_id);


--
-- Name: est_national_unit est_national_unit_national_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_national_unit
    ADD CONSTRAINT est_national_unit_national_plan_id_fkey FOREIGN KEY (national_plan_id) REFERENCES public.est_national_plan(national_plan_id);


--
-- Name: ci_responsibility fk_role; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_responsibility
    ADD CONSTRAINT fk_role FOREIGN KEY (role_code_id) REFERENCES public.ci_rolecode(id);


--
-- Name: la_source fk_source_responsibility; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.la_source
    ADD CONSTRAINT fk_source_responsibility FOREIGN KEY (source) REFERENCES public.ci_responsibility(id);


--
-- Name: est_detailed_unit fk_tile_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.est_detailed_unit
    ADD CONSTRAINT fk_tile_id FOREIGN KEY (tile_id) REFERENCES public.tile_sets(id);


--
-- Name: master_plan_la_source master_plan_la_source_la_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_plan_la_source
    ADD CONSTRAINT master_plan_la_source_la_source_id_fkey FOREIGN KEY (la_source_id) REFERENCES public.la_source(la_source_id);


--
-- Name: master_plan_la_source master_plan_la_source_master_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_plan_la_source
    ADD CONSTRAINT master_plan_la_source_master_plan_id_fkey FOREIGN KEY (master_plan_id) REFERENCES public.est_master_plan(master_plan_id);


--
-- Name: national_plan_la_source national_plan_la_source_la_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.national_plan_la_source
    ADD CONSTRAINT national_plan_la_source_la_source_id_fkey FOREIGN KEY (la_source_id) REFERENCES public.la_source(la_source_id);


--
-- Name: national_plan_la_source national_plan_la_source_national_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.national_plan_la_source
    ADD CONSTRAINT national_plan_la_source_national_plan_id_fkey FOREIGN KEY (national_plan_id) REFERENCES public.est_national_plan(national_plan_id);


--
-- Name: sp_permit sp_permit_detailed_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sp_permit
    ADD CONSTRAINT sp_permit_detailed_unit_id_fkey FOREIGN KEY (detailed_unit_id) REFERENCES public.est_detailed_unit(detailed_plan_unit_id);


--
-- Name: sp_permit sp_permit_type_of_permit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sp_permit
    ADD CONSTRAINT sp_permit_type_of_permit_id_fkey FOREIGN KEY (type_of_permit_id) REFERENCES public.sp_permittype(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- Name: TABLE ci_responsibility; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.ci_responsibility TO PUBLIC;


--
-- Name: TABLE ci_rolecode; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.ci_rolecode TO PUBLIC;


--
-- Name: TABLE county_plan_la_source; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.county_plan_la_source TO PUBLIC;


--
-- Name: TABLE detailed_plan_la_source; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.detailed_plan_la_source TO PUBLIC;


--
-- Name: TABLE est_county_plan; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.est_county_plan TO PUBLIC;


--
-- Name: TABLE est_county_plan_unit_count; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.est_county_plan_unit_count TO PUBLIC;


--
-- Name: TABLE est_county_unit; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.est_county_unit TO PUBLIC;


--
-- Name: TABLE est_detailed_plan; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.est_detailed_plan TO PUBLIC;


--
-- Name: TABLE est_detailed_plan_unit_count; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.est_detailed_plan_unit_count TO PUBLIC;


--
-- Name: TABLE est_detailed_unit; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.est_detailed_unit TO PUBLIC;


--
-- Name: TABLE est_detailed_unit_view; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.est_detailed_unit_view TO PUBLIC;


--
-- Name: TABLE est_greennetworktype; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.est_greennetworktype TO PUBLIC;


--
-- Name: TABLE est_master_plan; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.est_master_plan TO PUBLIC;


--
-- Name: TABLE est_master_plan_unit_count; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.est_master_plan_unit_count TO PUBLIC;


--
-- Name: TABLE est_master_unit; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.est_master_unit TO PUBLIC;


--
-- Name: TABLE est_national_plan; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.est_national_plan TO PUBLIC;


--
-- Name: TABLE est_national_plan_unit_count; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.est_national_plan_unit_count TO PUBLIC;


--
-- Name: TABLE est_national_unit; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.est_national_unit TO PUBLIC;


--
-- Name: TABLE est_transportinfrastructuretype; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.est_transportinfrastructuretype TO PUBLIC;


--
-- Name: TABLE la_administrativesource; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.la_administrativesource TO PUBLIC;


--
-- Name: TABLE la_mediatype; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.la_mediatype TO PUBLIC;


--
-- Name: TABLE la_multimediatype; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.la_multimediatype TO PUBLIC;


--
-- Name: TABLE la_source; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.la_source TO PUBLIC;


--
-- Name: TABLE la_spatialsource; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.la_spatialsource TO PUBLIC;


--
-- Name: TABLE la_spatialsourcetype; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.la_spatialsourcetype TO PUBLIC;


--
-- Name: TABLE la_surfacerelationtype; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.la_surfacerelationtype TO PUBLIC;


--
-- Name: TABLE la_surveypurposetype; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.la_surveypurposetype TO PUBLIC;


--
-- Name: TABLE master_plan_la_source; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.master_plan_la_source TO PUBLIC;


--
-- Name: TABLE national_plan_la_source; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.national_plan_la_source TO PUBLIC;


--
-- Name: TABLE sp_higherlevelspacefunction; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.sp_higherlevelspacefunction TO PUBLIC;


--
-- Name: TABLE sp_permit; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.sp_permit TO PUBLIC;


--
-- Name: TABLE sp_permittype; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.sp_permittype TO PUBLIC;


--
-- Name: TABLE sp_spacefunctiontype; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.sp_spacefunctiontype TO PUBLIC;


--
-- Name: TABLE sp_statustype; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.sp_statustype TO PUBLIC;


--
-- Name: TABLE sp_subspacefunctiontype; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.sp_subspacefunctiontype TO PUBLIC;


--
-- Name: TABLE tile_sets; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.tile_sets TO PUBLIC;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: -; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT ALL ON TABLES TO PUBLIC;


--
-- PostgreSQL database dump complete
--

