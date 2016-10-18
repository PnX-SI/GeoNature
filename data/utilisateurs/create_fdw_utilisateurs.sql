--Lien entre taxhub et usersHub

CREATE EXTENSION IF NOT EXISTS postgres_fdw;
CREATE SCHEMA IF NOT EXISTS utilisateurs;

CREATE SERVER server_usershubdb FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '$usershub_host', dbname '$usershub_db', port '$usershub_port');

CREATE USER MAPPING FOR $user_pg SERVER server_usershubdb OPTIONS (user '$usershub_user', password '$usershub_pass');

CREATE FOREIGN TABLE utilisateurs.v_userslist_forall_applications (
	groupe boolean,
	id_role int,
	identifiant varchar(100),
	nom_role varchar(50),
	prenom_role varchar(50),
	desc_role text,
	pass varchar(100),
	email varchar(250),
	id_organisme int,
	organisme varchar(32),
	id_unite int,
	remarques text,
	pn boolean,
	session_appli varchar(50),
	date_insert timestamp without time zone,
	date_update timestamp without time zone,
	id_droit_max integer,
	id_application integer
)
SERVER server_usershubdb;

CREATE FOREIGN TABLE utilisateurs.t_roles (
	groupe boolean NOT NULL DEFAULT false,
	id_role integer,
	identifiant character varying(100),
	nom_role character varying(50),
	prenom_role character varying(50),
	desc_role text,
	pass character varying(100),
	email character varying(250),
	id_organisme integer,
	organisme character(32),
	id_unite integer,
	remarques text,
	pn boolean,
	session_appli character varying(50),
	date_insert timestamp without time zone,
	date_update timestamp without time zone
)
SERVER server_usershubdb;


CREATE FOREIGN TABLE utilisateurs.t_applications (
	id_application int,
	nom_application character varying(50) NOT NULL,
	desc_application text
)
SERVER server_usershubdb;

CREATE FOREIGN TABLE utilisateurs.v_userslist_forall_menu (
	groupe boolean,
	id_role int,
	identifiant varchar(100),
	nom_role varchar(50),
	prenom_role varchar(50),
	nom_complet text,
	desc_role text,
	pass varchar(100),
	email varchar(250),
	id_organisme int,
	organisme varchar(32),
	id_unite int,
	remarques text,
	pn boolean,
	session_appli varchar(50),
	date_insert timestamp without time zone,
	date_update timestamp without time zone,
	id_droit_max integer,
	id_application integer
)
SERVER server_usershubdb;
