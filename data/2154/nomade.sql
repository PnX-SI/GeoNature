--
-- Name: synchronomade; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA synchronomade;


SET search_path = synchronomade, pg_catalog;

--
-- Name: erreurs_cf; Type: TABLE; Schema: synchronomade; Owner: -; Tablespace: 
--

CREATE TABLE erreurs_cf (
    id integer NOT NULL,
    json text,
    date_import date
);


--
-- Name: erreurs_cf_id_seq; Type: SEQUENCE; Schema: synchronomade; Owner: -
--

CREATE SEQUENCE erreurs_cf_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erreurs_cf_id_seq; Type: SEQUENCE OWNED BY; Schema: synchronomade; Owner: -
--

ALTER SEQUENCE erreurs_cf_id_seq OWNED BY erreurs_cf.id;


--
-- Name: erreurs_inv; Type: TABLE; Schema: synchronomade; Owner: -; Tablespace: 
--

CREATE TABLE erreurs_inv (
    id integer NOT NULL,
    json text,
    date_import date
);


--
-- Name: erreurs_inv_id_seq; Type: SEQUENCE; Schema: synchronomade; Owner: -
--

CREATE SEQUENCE erreurs_inv_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erreurs_inv_id_seq; Type: SEQUENCE OWNED BY; Schema: synchronomade; Owner: -
--

ALTER SEQUENCE erreurs_inv_id_seq OWNED BY erreurs_inv.id;


--
-- Name: erreurs_mortalite; Type: TABLE; Schema: synchronomade; Owner: -; Tablespace: 
--

CREATE TABLE erreurs_mortalite (
    id integer NOT NULL,
    json text,
    date_import date
);


--
-- Name: erreurs_mortalite_id_seq; Type: SEQUENCE; Schema: synchronomade; Owner: -
--

CREATE SEQUENCE erreurs_mortalite_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erreurs_mortalite_id_seq; Type: SEQUENCE OWNED BY; Schema: synchronomade; Owner: -
--

ALTER SEQUENCE erreurs_mortalite_id_seq OWNED BY erreurs_mortalite.id;


--
-- TOC entry 329 (class 1259 OID 166465)
-- Name: erreurs_flora; Type: TABLE; Schema: synchronomade; Owner: -; Tablespace: 
--

CREATE TABLE erreurs_flora (
    id integer NOT NULL,
    json text,
    date_import date
);

--
-- TOC entry 328 (class 1259 OID 166463)
-- Name: erreurs_flora_id_seq; Type: SEQUENCE; Schema: synchronomade; Owner: -
--

CREATE SEQUENCE erreurs_flora_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- TOC entry 3711 (class 0 OID 0)
-- Dependencies: 328
-- Name: erreurs_flora_id_seq; Type: SEQUENCE OWNED BY; Schema: synchronomade; Owner: -
--

ALTER SEQUENCE erreurs_flora_id_seq OWNED BY erreurs_flora.id;

--
-- Name: id; Type: DEFAULT; Schema: synchronomade; Owner: -
--

ALTER TABLE ONLY erreurs_cf ALTER COLUMN id SET DEFAULT nextval('erreurs_cf_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: synchronomade; Owner: -
--

ALTER TABLE ONLY erreurs_inv ALTER COLUMN id SET DEFAULT nextval('erreurs_inv_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: synchronomade; Owner: -
--

ALTER TABLE ONLY erreurs_mortalite ALTER COLUMN id SET DEFAULT nextval('erreurs_mortalite_id_seq'::regclass);


--
-- TOC entry 3363 (class 2604 OID 166468)
-- Name: id; Type: DEFAULT; Schema: synchronomade; Owner: -
--

ALTER TABLE ONLY erreurs_flora ALTER COLUMN id SET DEFAULT nextval('erreurs_flora_id_seq'::regclass);


--
-- Name: erreurs_cf_pkey; Type: CONSTRAINT; Schema: synchronomade; Owner: -; Tablespace: 
--

ALTER TABLE ONLY erreurs_cf
    ADD CONSTRAINT erreurs_cf_pkey PRIMARY KEY (id);


--
-- Name: erreurs_inv_pkey; Type: CONSTRAINT; Schema: synchronomade; Owner: -; Tablespace: 
--

ALTER TABLE ONLY erreurs_inv
    ADD CONSTRAINT erreurs_inv_pkey PRIMARY KEY (id);


--
-- Name: erreurs_mortalite_pkey; Type: CONSTRAINT; Schema: synchronomade; Owner: -; Tablespace: 
--

ALTER TABLE ONLY erreurs_mortalite
    ADD CONSTRAINT erreurs_mortalite_pkey PRIMARY KEY (id);
    
--
-- TOC entry 3445 (class 2606 OID 166473)
-- Name: erreurs_flora_pkey; Type: CONSTRAINT; Schema: synchronomade; Owner: -; Tablespace: 
--

ALTER TABLE ONLY erreurs_flora
    ADD CONSTRAINT erreurs_flora_pkey PRIMARY KEY (id);




SET search_path = public, pg_catalog;

CREATE OR REPLACE VIEW v_mobile_recherche AS 
( SELECT ap.indexap AS gid,
    zp.dateobs,
    t.latin AS taxon,
    o.observateurs,
    public.st_asgeojson(public.st_transform(ap.the_geom_2154, 4326)) AS geom_4326,
    public.st_x(public.st_transform(public.st_centroid(ap.the_geom_2154), 4326)) AS centroid_x,
    public.st_y(public.st_transform(public.st_centroid(ap.the_geom_2154), 4326)) AS centroid_y
   FROM florepatri.t_apresence ap
     JOIN florepatri.t_zprospection zp ON ap.indexzp = zp.indexzp
     JOIN florepatri.bib_taxons_fp t ON t.cd_nom = zp.cd_nom
     JOIN ( SELECT c.indexzp,
            array_to_string(array_agg((r.prenom_role::text || ' '::text) || r.nom_role::text), ', '::text) AS observateurs
           FROM florepatri.cor_zp_obs c
             JOIN utilisateurs.t_roles r ON r.id_role = c.codeobs
          GROUP BY c.indexzp) o ON o.indexzp = ap.indexzp
  WHERE ap.supprime = false AND st_isvalid(ap.the_geom_2154) AND ap.topo_valid = true
  ORDER BY zp.dateobs DESC)
UNION
( SELECT cft.id_station AS gid,
    s.dateobs,
    t.latin AS taxon,
    o.observateurs,
    public.st_asgeojson(public.st_transform(s.the_geom_3857, 4326)) AS geom_4326,
    public.st_x(public.st_transform(public.st_centroid(s.the_geom_3857), 4326)) AS centroid_x,
    public.st_y(public.st_transform(public.st_centroid(s.the_geom_3857), 4326)) AS centroid_y
   FROM florestation.cor_fs_taxon cft
     JOIN florestation.t_stations_fs s ON s.id_station = cft.id_station
     JOIN florepatri.bib_taxons_fp t ON t.cd_nom = cft.cd_nom
     JOIN ( SELECT c.id_station,
            array_to_string(array_agg((r.prenom_role::text || ' '::text) || r.nom_role::text), ', '::text) AS observateurs
           FROM florestation.cor_fs_observateur c
             JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
          GROUP BY c.id_station) o ON o.id_station = cft.id_station
  WHERE cft.supprime = false AND st_isvalid(s.the_geom_3857)
  ORDER BY s.dateobs DESC);