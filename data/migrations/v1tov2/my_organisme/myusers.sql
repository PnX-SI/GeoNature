-- Droit d'accès à GeoNature pour le groupe en poste PNE

CREATE OR REPLACE VIEW utilisateurs.v_droit_appli_cbna AS 
 SELECT DISTINCT r.groupe,
    r.id_role,
    r.identifiant,
    r.nom_role,
    r.prenom_role,
    r.desc_role,
    r.pass,
    r.email,
    bib.nom_organisme AS organisme,
    r.id_unite,
    r.pn,
    r.session_appli,
    r.date_insert,
    r.date_update,
    r.id_organisme
   FROM utilisateurs.t_roles r
     JOIN utilisateurs.bib_organismes bib ON bib.id_organisme = r.id_organisme
  WHERE (r.id_role IN ( SELECT DISTINCT cr.id_role_utilisateur
           FROM utilisateurs.cor_roles cr
          WHERE (cr.id_role_groupe IN ( SELECT da.id_role
                   FROM utilisateurs.cor_role_droit_application da
                     JOIN utilisateurs.t_roles r_1 ON r_1.id_role = da.id_role
                  WHERE da.id_droit = 2 AND da.id_application = 23 AND r_1.groupe = true))
          ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN ( SELECT da.id_role
           FROM utilisateurs.cor_role_droit_application da
             JOIN utilisateurs.t_roles r_1 ON r_1.id_role = da.id_role
          WHERE da.id_droit = 2 AND da.id_application = 23 AND r_1.groupe = false))
  ORDER BY r.groupe, r.id_role, r.identifiant, r.nom_role, r.prenom_role, r.desc_role, r.pass, r.email, r.pn, r.session_appli, r.date_insert, r.date_update, r.id_organisme;


CREATE OR REPLACE VIEW utilisateurs.v_droits_sentiers AS 
 SELECT a.id_role,
    a.identifiant AS username,
    a.pass AS password,
    a.email,
    a.structure,
    a.lang,
    a.nom_role AS last_name,
    a.prenom_role AS first_name,
    max(a.id_droit) AS level,
    a.id_application,
    a.id_unite
   FROM ( SELECT u.id_role,
            u.identifiant,
            u.pass,
            u.email,
                CASE
                    WHEN u.id_role = ANY (ARRAY[1255, 1256]) THEN 'Maison-Tourisme-CHP-VLG'::text
                    WHEN u.id_organisme = 111 THEN 'Pays des Ecrins (ComCom)'::text
                    ELSE 'PNE'::text
                END AS structure,
            'fr'::text AS lang,
            u.nom_role,
            u.prenom_role,
            c.id_droit,
            c.id_application,
            u.id_unite
           FROM utilisateurs.t_roles u
             JOIN utilisateurs.cor_role_droit_application c ON c.id_role = u.id_role
          WHERE c.id_application = 21 AND u.groupe = false
        UNION
         SELECT g.id_role_utilisateur,
            u.identifiant,
            u.pass,
            u.email,
                CASE
                    WHEN u.id_role = ANY (ARRAY[1255, 1256]) THEN 'Maison-Tourisme-CHP-VLG'::text
                    WHEN u.id_organisme = 111 THEN 'Pays des Ecrins (ComCom)'::text
                    ELSE 'PNE'::text
                END AS structure,
            'fr'::text AS lang,
            u.nom_role,
            u.prenom_role,
            c.id_droit,
            c.id_application,
            u.id_unite
           FROM utilisateurs.t_roles u
             JOIN utilisateurs.cor_roles g ON g.id_role_utilisateur = u.id_role
             JOIN utilisateurs.cor_role_droit_application c ON c.id_role = g.id_role_groupe
          WHERE c.id_application = 21 AND u.groupe = false) a
  GROUP BY a.id_role, a.identifiant, a.email, a.pass, a.structure, a.lang, a.nom_role, a.prenom_role, a.id_application, a.id_unite;
