SET search_path = utilisateurs, pg_catalog;

CREATE VIEW v_nomade_observateurs_all AS
    ((SELECT DISTINCT r.id_role, r.nom_role, r.prenom_role, 'fauna'::text AS mode FROM t_roles r WHERE ((r.id_role IN (SELECT DISTINCT cr.id_role_utilisateur FROM cor_roles cr WHERE (cr.id_role_groupe IN (SELECT crm.id_role FROM cor_role_menu crm WHERE (crm.id_menu = 9))) ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN (SELECT crm.id_role FROM (cor_role_menu crm JOIN t_roles r ON ((((r.id_role = crm.id_role) AND (crm.id_menu = 9)) AND (r.groupe = false))))))) ORDER BY r.nom_role, r.prenom_role, r.id_role) UNION (SELECT DISTINCT r.id_role, r.nom_role, r.prenom_role, 'flora'::text AS mode FROM t_roles r WHERE ((r.id_role IN (SELECT DISTINCT cr.id_role_utilisateur FROM cor_roles cr WHERE (cr.id_role_groupe IN (SELECT crm.id_role FROM cor_role_menu crm WHERE (crm.id_menu = 10))) ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN (SELECT crm.id_role FROM (cor_role_menu crm JOIN t_roles r ON ((((r.id_role = crm.id_role) AND (crm.id_menu = 10)) AND (r.groupe = false))))))) ORDER BY r.nom_role, r.prenom_role, r.id_role)) UNION (SELECT DISTINCT r.id_role, r.nom_role, r.prenom_role, 'inv'::text AS mode FROM t_roles r WHERE ((r.id_role IN (SELECT DISTINCT cr.id_role_utilisateur FROM cor_roles cr WHERE (cr.id_role_groupe IN (SELECT crm.id_role FROM cor_role_menu crm WHERE (crm.id_menu = 9))) ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN (SELECT crm.id_role FROM (cor_role_menu crm JOIN t_roles r ON ((((r.id_role = crm.id_role) AND (crm.id_menu = 9)) AND (r.groupe = false))))))) ORDER BY r.nom_role, r.prenom_role, r.id_role);


--
-- Name: v_observateurs; Type: VIEW; Schema: utilisateurs; Owner: -
--

CREATE VIEW v_observateurs AS
    SELECT DISTINCT r.id_role AS codeobs, (((r.nom_role)::text || ' '::text) || (r.prenom_role)::text) AS nomprenom FROM t_roles r WHERE ((r.id_role IN (SELECT DISTINCT cr.id_role_utilisateur FROM cor_roles cr WHERE (cr.id_role_groupe IN (SELECT crm.id_role FROM cor_role_menu crm WHERE (crm.id_menu = 9))) ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN (SELECT crm.id_role FROM (cor_role_menu crm JOIN t_roles r ON ((((r.id_role = crm.id_role) AND (crm.id_menu = 9)) AND (r.groupe = false))))))) ORDER BY (((r.nom_role)::text || ' '::text) || (r.prenom_role)::text), r.id_role;
  
   
--
-- Name: v_userslist_forall_applications; Type: VIEW; Schema: utilisateurs; Owner: -
--
    
CREATE OR REPLACE VIEW v_userslist_forall_menu AS
 SELECT a.groupe,
    a.id_role,
    a.uuid_role,
    a.identifiant,
    a.nom_role,
    a.prenom_role,
    (upper(a.nom_role::text) || ' '::text) || a.prenom_role::text AS nom_complet,
    a.desc_role,
    a.pass,
    a.email,
    a.id_organisme,
    a.organisme,
    a.id_unite,
    a.remarques,
    a.pn,
    a.session_appli,
    a.date_insert,
    a.date_update,
    a.id_menu
   FROM ( SELECT u.groupe,
            u.id_role,
            u.uuid_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.email,
            u.id_organisme,
            u.organisme,
            u.id_unite,
            u.remarques,
            u.pn,
            u.session_appli,
            u.date_insert,
            u.date_update,
            c.id_menu
           FROM utilisateurs.t_roles u
             JOIN utilisateurs.cor_role_menu c ON c.id_role = u.id_role
          WHERE u.groupe = false
        UNION
         SELECT u.groupe,
            u.id_role,
            u.uuid_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.email,
            u.id_organisme,
            u.organisme,
            u.id_unite,
            u.remarques,
            u.pn,
            u.session_appli,
            u.date_insert,
            u.date_update,
            c.id_menu
           FROM utilisateurs.t_roles u
             JOIN utilisateurs.cor_roles g ON g.id_role_utilisateur = u.id_role
             JOIN utilisateurs.cor_role_menu c ON c.id_role = g.id_role_groupe
          WHERE u.groupe = false) a;