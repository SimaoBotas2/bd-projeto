--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
-- Dumped by pg_dump version 17.2

-- Started on 2025-05-24 15:10:41

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 5030 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 244 (class 1255 OID 17382)
-- Name: add_financial_record_after_student_activity_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_financial_record_after_student_activity_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO financial_record (person_id, charge_value, date_to_pay, status)
    VALUES (NEW.student_id, 30, CURRENT_DATE + INTERVAL '30 days', 'pending');
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.add_financial_record_after_student_activity_insert() OWNER TO postgres;

--
-- TOC entry 243 (class 1255 OID 17380)
-- Name: add_financial_record_after_student_degree_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_financial_record_after_student_degree_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO financial_record (person_id, charge_value, date_to_pay, status)
    VALUES (NEW.student_id, 70, CURRENT_DATE + INTERVAL '30 days', 'pending');
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.add_financial_record_after_student_degree_insert() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 224 (class 1259 OID 16536)
-- Name: activity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activity (
    id integer NOT NULL,
    name text NOT NULL,
    type text,
    cost numeric DEFAULT 0
);


ALTER TABLE public.activity OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16493)
-- Name: class; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.class (
    nclass integer NOT NULL,
    name text NOT NULL,
    type text NOT NULL,
    ncourse integer NOT NULL,
    capacity bigint NOT NULL,
    classroom_name text NOT NULL
);


ALTER TABLE public.class OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16500)
-- Name: classroom; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.classroom (
    name text NOT NULL,
    location text NOT NULL,
    capacity integer NOT NULL,
    nclass integer NOT NULL
);


ALTER TABLE public.classroom OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16479)
-- Name: course; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course (
    ncourse integer NOT NULL,
    name text NOT NULL,
    ncoordinator integer NOT NULL,
    capacity integer NOT NULL,
    ndegree integer NOT NULL
);


ALTER TABLE public.course OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16592)
-- Name: course_class; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course_class (
    course_ncourse integer NOT NULL,
    class_nclass integer NOT NULL
);


ALTER TABLE public.course_class OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16587)
-- Name: course_course; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course_course (
    course_ncourse integer NOT NULL,
    course_ncourse1 integer NOT NULL
);


ALTER TABLE public.course_course OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16602)
-- Name: course_degree; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course_degree (
    course_ncourse integer NOT NULL,
    degree_ndegree integer NOT NULL
);


ALTER TABLE public.course_degree OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 16952)
-- Name: course_edition; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course_edition (
    id integer NOT NULL,
    course_ncourse integer NOT NULL,
    semester character varying(10) NOT NULL,
    year integer NOT NULL,
    start_date date,
    end_date date,
    capacity integer,
    coordinator_id integer
);


ALTER TABLE public.course_edition OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 16951)
-- Name: course_edition_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.course_edition_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.course_edition_id_seq OWNER TO postgres;

--
-- TOC entry 5042 (class 0 OID 0)
-- Dependencies: 239
-- Name: course_edition_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.course_edition_id_seq OWNED BY public.course_edition.id;


--
-- TOC entry 230 (class 1259 OID 16612)
-- Name: course_student_grade; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course_student_grade (
    course_ncourse integer NOT NULL,
    student_grade_person_id integer NOT NULL,
    course_edition_id integer NOT NULL,
    period character varying(50) DEFAULT 'N/A'::character varying NOT NULL,
    grade numeric(5,2)
);


ALTER TABLE public.course_student_grade OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16486)
-- Name: degree; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.degree (
    ndegree integer NOT NULL,
    name character varying(512) NOT NULL
);


ALTER TABLE public.degree OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16607)
-- Name: degree_student_grade; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.degree_student_grade (
    degree_ndegree integer NOT NULL,
    student_grade_person_id integer NOT NULL
);


ALTER TABLE public.degree_student_grade OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16529)
-- Name: financial_record; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.financial_record (
    charge_value real,
    date_to_pay date,
    status text,
    person_id integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE public.financial_record OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 17384)
-- Name: financial_record_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.financial_record_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.financial_record_id_seq OWNER TO postgres;

--
-- TOC entry 5048 (class 0 OID 0)
-- Dependencies: 242
-- Name: financial_record_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.financial_record_id_seq OWNED BY public.financial_record.id;


--
-- TOC entry 235 (class 1259 OID 16908)
-- Name: instructor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instructor (
    person_id integer NOT NULL
);


ALTER TABLE public.instructor OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 16973)
-- Name: instructor_course; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instructor_course (
    instructor_person_id integer NOT NULL,
    course_edition_id integer NOT NULL
);


ALTER TABLE public.instructor_course OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16821)
-- Name: person_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.person_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.person_id_seq OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16512)
-- Name: person; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.person (
    id integer DEFAULT nextval('public.person_id_seq'::regclass) NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
    password text
);


ALTER TABLE public.person OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 16898)
-- Name: staff; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff (
    person_id integer NOT NULL
);


ALTER TABLE public.staff OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 16874)
-- Name: student; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student (
    person_id integer NOT NULL,
    district text NOT NULL
);


ALTER TABLE public.student OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 16921)
-- Name: student_activity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_activity (
    id integer NOT NULL,
    student_id integer NOT NULL,
    activity_id integer NOT NULL,
    enrollment_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.student_activity OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 16920)
-- Name: student_activity_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_activity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_activity_id_seq OWNER TO postgres;

--
-- TOC entry 5057 (class 0 OID 0)
-- Dependencies: 236
-- Name: student_activity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_activity_id_seq OWNED BY public.student_activity.id;


--
-- TOC entry 238 (class 1259 OID 16940)
-- Name: student_course; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_course (
    student_id integer NOT NULL,
    course_edition_id integer NOT NULL,
    class_id integer NOT NULL,
    enrollment_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.student_course OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16840)
-- Name: student_degree; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_degree (
    student_id integer NOT NULL,
    degree_ndegree integer NOT NULL,
    start_date date DEFAULT CURRENT_DATE NOT NULL,
    end_date date
);


ALTER TABLE public.student_degree OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16472)
-- Name: student_grade; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_grade (
    ndegree integer NOT NULL,
    grade_season text NOT NULL,
    grade real,
    class_nclass integer NOT NULL,
    person_id integer NOT NULL,
    course_ncourse integer NOT NULL
);


ALTER TABLE public.student_grade OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16597)
-- Name: student_grade_class; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_grade_class (
    student_grade_person_id integer NOT NULL,
    class_nclass integer NOT NULL
);


ALTER TABLE public.student_grade_class OWNER TO postgres;

--
-- TOC entry 4792 (class 2604 OID 16955)
-- Name: course_edition id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_edition ALTER COLUMN id SET DEFAULT nextval('public.course_edition_id_seq'::regclass);


--
-- TOC entry 4785 (class 2604 OID 17385)
-- Name: financial_record id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.financial_record ALTER COLUMN id SET DEFAULT nextval('public.financial_record_id_seq'::regclass);


--
-- TOC entry 4789 (class 2604 OID 16924)
-- Name: student_activity id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_activity ALTER COLUMN id SET DEFAULT nextval('public.student_activity_id_seq'::regclass);


--
-- TOC entry 4816 (class 2606 OID 16542)
-- Name: activity activity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_pkey PRIMARY KEY (id);


--
-- TOC entry 4804 (class 2606 OID 16499)
-- Name: class class_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class
    ADD CONSTRAINT class_pkey PRIMARY KEY (nclass);


--
-- TOC entry 4806 (class 2606 OID 16637)
-- Name: classroom classroom_nclass_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classroom
    ADD CONSTRAINT classroom_nclass_key UNIQUE (nclass);


--
-- TOC entry 4808 (class 2606 OID 16506)
-- Name: classroom classroom_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classroom
    ADD CONSTRAINT classroom_pkey PRIMARY KEY (name);


--
-- TOC entry 4820 (class 2606 OID 16596)
-- Name: course_class course_class_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_class
    ADD CONSTRAINT course_class_pkey PRIMARY KEY (course_ncourse);


--
-- TOC entry 4818 (class 2606 OID 16591)
-- Name: course_course course_course_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_course
    ADD CONSTRAINT course_course_pkey PRIMARY KEY (course_ncourse, course_ncourse1);


--
-- TOC entry 4824 (class 2606 OID 16606)
-- Name: course_degree course_degree_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_degree
    ADD CONSTRAINT course_degree_pkey PRIMARY KEY (course_ncourse, degree_ndegree);


--
-- TOC entry 4844 (class 2606 OID 16959)
-- Name: course_edition course_edition_course_ncourse_semester_year_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_edition
    ADD CONSTRAINT course_edition_course_ncourse_semester_year_key UNIQUE (course_ncourse, semester, year);


--
-- TOC entry 4846 (class 2606 OID 16957)
-- Name: course_edition course_edition_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_edition
    ADD CONSTRAINT course_edition_pkey PRIMARY KEY (id);


--
-- TOC entry 4798 (class 2606 OID 16630)
-- Name: course course_name_ncoordinator_ndegree_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course
    ADD CONSTRAINT course_name_ncoordinator_ndegree_key UNIQUE (name, ncoordinator, ndegree);


--
-- TOC entry 4800 (class 2606 OID 16485)
-- Name: course course_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course
    ADD CONSTRAINT course_pkey PRIMARY KEY (ncourse);


--
-- TOC entry 4828 (class 2606 OID 16972)
-- Name: course_student_grade course_student_grade_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_student_grade
    ADD CONSTRAINT course_student_grade_pkey PRIMARY KEY (course_edition_id, student_grade_person_id, period);


--
-- TOC entry 4802 (class 2606 OID 16492)
-- Name: degree degree_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.degree
    ADD CONSTRAINT degree_pkey PRIMARY KEY (ndegree);


--
-- TOC entry 4826 (class 2606 OID 16611)
-- Name: degree_student_grade degree_student_grade_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.degree_student_grade
    ADD CONSTRAINT degree_student_grade_pkey PRIMARY KEY (degree_ndegree, student_grade_person_id);


--
-- TOC entry 4814 (class 2606 OID 17387)
-- Name: financial_record financial_record_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.financial_record
    ADD CONSTRAINT financial_record_pkey PRIMARY KEY (id);


--
-- TOC entry 4848 (class 2606 OID 16977)
-- Name: instructor_course instructor_course_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instructor_course
    ADD CONSTRAINT instructor_course_pkey PRIMARY KEY (instructor_person_id, course_edition_id);


--
-- TOC entry 4836 (class 2606 OID 16912)
-- Name: instructor instructor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instructor
    ADD CONSTRAINT instructor_pkey PRIMARY KEY (person_id);


--
-- TOC entry 4810 (class 2606 OID 16518)
-- Name: person person_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.person
    ADD CONSTRAINT person_pkey PRIMARY KEY (id);


--
-- TOC entry 4834 (class 2606 OID 16902)
-- Name: staff staff_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (person_id);


--
-- TOC entry 4838 (class 2606 OID 16927)
-- Name: student_activity student_activity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_activity
    ADD CONSTRAINT student_activity_pkey PRIMARY KEY (id);


--
-- TOC entry 4842 (class 2606 OID 16945)
-- Name: student_course student_course_student_id_course_edition_id_class_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_course
    ADD CONSTRAINT student_course_student_id_course_edition_id_class_id_key UNIQUE (student_id, course_edition_id, class_id);


--
-- TOC entry 4830 (class 2606 OID 16845)
-- Name: student_degree student_degree_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_degree
    ADD CONSTRAINT student_degree_pkey PRIMARY KEY (student_id, degree_ndegree, start_date);


--
-- TOC entry 4822 (class 2606 OID 16601)
-- Name: student_grade_class student_grade_class_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade_class
    ADD CONSTRAINT student_grade_class_pkey PRIMARY KEY (student_grade_person_id, class_nclass);


--
-- TOC entry 4794 (class 2606 OID 16618)
-- Name: student_grade student_grade_ndegree_class_nclass_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade
    ADD CONSTRAINT student_grade_ndegree_class_nclass_key UNIQUE (ndegree, class_nclass);


--
-- TOC entry 4796 (class 2606 OID 16478)
-- Name: student_grade student_grade_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade
    ADD CONSTRAINT student_grade_pkey PRIMARY KEY (person_id);


--
-- TOC entry 4832 (class 2606 OID 16880)
-- Name: student student_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_pkey PRIMARY KEY (person_id);


--
-- TOC entry 4812 (class 2606 OID 16857)
-- Name: person unique_email; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.person
    ADD CONSTRAINT unique_email UNIQUE (email);


--
-- TOC entry 4840 (class 2606 OID 16929)
-- Name: student_activity unique_student_activity; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_activity
    ADD CONSTRAINT unique_student_activity UNIQUE (student_id, activity_id);


--
-- TOC entry 4879 (class 2620 OID 17383)
-- Name: student_activity trg_after_student_activity_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_after_student_activity_insert AFTER INSERT ON public.student_activity FOR EACH ROW EXECUTE FUNCTION public.add_financial_record_after_student_activity_insert();


--
-- TOC entry 4878 (class 2620 OID 17381)
-- Name: student_degree trg_after_student_degree_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_after_student_degree_insert AFTER INSERT ON public.student_degree FOR EACH ROW EXECUTE FUNCTION public.add_financial_record_after_student_degree_insert();


--
-- TOC entry 4851 (class 2606 OID 16631)
-- Name: class class_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class
    ADD CONSTRAINT class_fk1 FOREIGN KEY (classroom_name) REFERENCES public.classroom(name);


--
-- TOC entry 4855 (class 2606 OID 16748)
-- Name: course_class course_class_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_class
    ADD CONSTRAINT course_class_fk1 FOREIGN KEY (course_ncourse) REFERENCES public.course(ncourse);


--
-- TOC entry 4856 (class 2606 OID 16753)
-- Name: course_class course_class_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_class
    ADD CONSTRAINT course_class_fk2 FOREIGN KEY (class_nclass) REFERENCES public.class(nclass);


--
-- TOC entry 4853 (class 2606 OID 16738)
-- Name: course_course course_course_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_course
    ADD CONSTRAINT course_course_fk1 FOREIGN KEY (course_ncourse) REFERENCES public.course(ncourse);


--
-- TOC entry 4854 (class 2606 OID 16743)
-- Name: course_course course_course_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_course
    ADD CONSTRAINT course_course_fk2 FOREIGN KEY (course_ncourse1) REFERENCES public.course(ncourse);


--
-- TOC entry 4859 (class 2606 OID 16768)
-- Name: course_degree course_degree_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_degree
    ADD CONSTRAINT course_degree_fk1 FOREIGN KEY (course_ncourse) REFERENCES public.course(ncourse);


--
-- TOC entry 4860 (class 2606 OID 16773)
-- Name: course_degree course_degree_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_degree
    ADD CONSTRAINT course_degree_fk2 FOREIGN KEY (degree_ndegree) REFERENCES public.degree(ndegree);


--
-- TOC entry 4874 (class 2606 OID 16960)
-- Name: course_edition course_edition_course_ncourse_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_edition
    ADD CONSTRAINT course_edition_course_ncourse_fkey FOREIGN KEY (course_ncourse) REFERENCES public.course(ncourse) ON DELETE CASCADE;


--
-- TOC entry 4863 (class 2606 OID 16965)
-- Name: course_student_grade course_student_grade_course_edition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_student_grade
    ADD CONSTRAINT course_student_grade_course_edition_id_fkey FOREIGN KEY (course_edition_id) REFERENCES public.course_edition(id) ON DELETE CASCADE;


--
-- TOC entry 4864 (class 2606 OID 16788)
-- Name: course_student_grade course_student_grade_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_student_grade
    ADD CONSTRAINT course_student_grade_fk1 FOREIGN KEY (course_ncourse) REFERENCES public.course(ncourse);


--
-- TOC entry 4865 (class 2606 OID 16793)
-- Name: course_student_grade course_student_grade_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_student_grade
    ADD CONSTRAINT course_student_grade_fk2 FOREIGN KEY (student_grade_person_id) REFERENCES public.student_grade(person_id);


--
-- TOC entry 4861 (class 2606 OID 16778)
-- Name: degree_student_grade degree_student_grade_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.degree_student_grade
    ADD CONSTRAINT degree_student_grade_fk1 FOREIGN KEY (degree_ndegree) REFERENCES public.degree(ndegree);


--
-- TOC entry 4862 (class 2606 OID 16783)
-- Name: degree_student_grade degree_student_grade_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.degree_student_grade
    ADD CONSTRAINT degree_student_grade_fk2 FOREIGN KEY (student_grade_person_id) REFERENCES public.student_grade(person_id);


--
-- TOC entry 4852 (class 2606 OID 17373)
-- Name: financial_record financial_record_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.financial_record
    ADD CONSTRAINT financial_record_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(id) ON DELETE CASCADE;


--
-- TOC entry 4875 (class 2606 OID 16988)
-- Name: course_edition fk_coordinator; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_edition
    ADD CONSTRAINT fk_coordinator FOREIGN KEY (coordinator_id) REFERENCES public.person(id) ON DELETE SET NULL;


--
-- TOC entry 4876 (class 2606 OID 16983)
-- Name: instructor_course instructor_course_course_edition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instructor_course
    ADD CONSTRAINT instructor_course_course_edition_id_fkey FOREIGN KEY (course_edition_id) REFERENCES public.course_edition(id);


--
-- TOC entry 4877 (class 2606 OID 16978)
-- Name: instructor_course instructor_course_instructor_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instructor_course
    ADD CONSTRAINT instructor_course_instructor_person_id_fkey FOREIGN KEY (instructor_person_id) REFERENCES public.person(id);


--
-- TOC entry 4870 (class 2606 OID 16913)
-- Name: instructor instructor_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instructor
    ADD CONSTRAINT instructor_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(id) ON DELETE CASCADE;


--
-- TOC entry 4869 (class 2606 OID 16903)
-- Name: staff staff_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(id) ON DELETE CASCADE;


--
-- TOC entry 4871 (class 2606 OID 16935)
-- Name: student_activity student_activity_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_activity
    ADD CONSTRAINT student_activity_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- TOC entry 4872 (class 2606 OID 16930)
-- Name: student_activity student_activity_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_activity
    ADD CONSTRAINT student_activity_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.student(person_id) ON DELETE CASCADE;


--
-- TOC entry 4873 (class 2606 OID 16946)
-- Name: student_course student_course_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_course
    ADD CONSTRAINT student_course_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.person(id);


--
-- TOC entry 4866 (class 2606 OID 16851)
-- Name: student_degree student_degree_degree_ndegree_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_degree
    ADD CONSTRAINT student_degree_degree_ndegree_fkey FOREIGN KEY (degree_ndegree) REFERENCES public.degree(ndegree);


--
-- TOC entry 4867 (class 2606 OID 16846)
-- Name: student_degree student_degree_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_degree
    ADD CONSTRAINT student_degree_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.person(id);


--
-- TOC entry 4857 (class 2606 OID 16758)
-- Name: student_grade_class student_grade_class_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade_class
    ADD CONSTRAINT student_grade_class_fk1 FOREIGN KEY (student_grade_person_id) REFERENCES public.student_grade(person_id);


--
-- TOC entry 4858 (class 2606 OID 16763)
-- Name: student_grade_class student_grade_class_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade_class
    ADD CONSTRAINT student_grade_class_fk2 FOREIGN KEY (class_nclass) REFERENCES public.class(nclass);


--
-- TOC entry 4849 (class 2606 OID 16619)
-- Name: student_grade student_grade_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade
    ADD CONSTRAINT student_grade_fk1 FOREIGN KEY (class_nclass) REFERENCES public.class(nclass);


--
-- TOC entry 4850 (class 2606 OID 16624)
-- Name: student_grade student_grade_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade
    ADD CONSTRAINT student_grade_fk2 FOREIGN KEY (person_id) REFERENCES public.person(id);


--
-- TOC entry 4868 (class 2606 OID 16881)
-- Name: student student_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(id) ON DELETE CASCADE;


--
-- TOC entry 5031 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO projeto;
GRANT ALL ON SCHEMA public TO aulaspl;


--
-- TOC entry 5032 (class 0 OID 0)
-- Dependencies: 244
-- Name: FUNCTION add_financial_record_after_student_activity_insert(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.add_financial_record_after_student_activity_insert() TO aulaspl;


--
-- TOC entry 5033 (class 0 OID 0)
-- Dependencies: 243
-- Name: FUNCTION add_financial_record_after_student_degree_insert(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.add_financial_record_after_student_degree_insert() TO aulaspl;


--
-- TOC entry 5034 (class 0 OID 0)
-- Dependencies: 224
-- Name: TABLE activity; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.activity TO aulaspl;


--
-- TOC entry 5035 (class 0 OID 0)
-- Dependencies: 220
-- Name: TABLE class; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.class TO aulaspl;


--
-- TOC entry 5036 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE classroom; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.classroom TO aulaspl;


--
-- TOC entry 5037 (class 0 OID 0)
-- Dependencies: 218
-- Name: TABLE course; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.course TO aulaspl;


--
-- TOC entry 5038 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE course_class; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.course_class TO aulaspl;


--
-- TOC entry 5039 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE course_course; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.course_course TO aulaspl;


--
-- TOC entry 5040 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE course_degree; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.course_degree TO aulaspl;


--
-- TOC entry 5041 (class 0 OID 0)
-- Dependencies: 240
-- Name: TABLE course_edition; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.course_edition TO aulaspl;


--
-- TOC entry 5043 (class 0 OID 0)
-- Dependencies: 239
-- Name: SEQUENCE course_edition_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.course_edition_id_seq TO aulaspl;


--
-- TOC entry 5044 (class 0 OID 0)
-- Dependencies: 230
-- Name: TABLE course_student_grade; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.course_student_grade TO aulaspl;


--
-- TOC entry 5045 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE degree; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.degree TO aulaspl;


--
-- TOC entry 5046 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE degree_student_grade; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.degree_student_grade TO aulaspl;


--
-- TOC entry 5047 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE financial_record; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.financial_record TO aulaspl;


--
-- TOC entry 5049 (class 0 OID 0)
-- Dependencies: 242
-- Name: SEQUENCE financial_record_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.financial_record_id_seq TO aulaspl;


--
-- TOC entry 5050 (class 0 OID 0)
-- Dependencies: 235
-- Name: TABLE instructor; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.instructor TO aulaspl;


--
-- TOC entry 5051 (class 0 OID 0)
-- Dependencies: 241
-- Name: TABLE instructor_course; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.instructor_course TO aulaspl;


--
-- TOC entry 5052 (class 0 OID 0)
-- Dependencies: 231
-- Name: SEQUENCE person_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.person_id_seq TO aulaspl;


--
-- TOC entry 5053 (class 0 OID 0)
-- Dependencies: 222
-- Name: TABLE person; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.person TO aulaspl;


--
-- TOC entry 5054 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE staff; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.staff TO aulaspl;


--
-- TOC entry 5055 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE student; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.student TO aulaspl;


--
-- TOC entry 5056 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE student_activity; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.student_activity TO aulaspl;


--
-- TOC entry 5058 (class 0 OID 0)
-- Dependencies: 236
-- Name: SEQUENCE student_activity_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.student_activity_id_seq TO aulaspl;


--
-- TOC entry 5059 (class 0 OID 0)
-- Dependencies: 238
-- Name: TABLE student_course; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.student_course TO aulaspl;


--
-- TOC entry 5060 (class 0 OID 0)
-- Dependencies: 232
-- Name: TABLE student_degree; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.student_degree TO aulaspl;


--
-- TOC entry 5061 (class 0 OID 0)
-- Dependencies: 217
-- Name: TABLE student_grade; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.student_grade TO aulaspl;


--
-- TOC entry 5062 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE student_grade_class; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.student_grade_class TO aulaspl;


-- Completed on 2025-05-24 15:10:41

--
-- PostgreSQL database dump complete
--

