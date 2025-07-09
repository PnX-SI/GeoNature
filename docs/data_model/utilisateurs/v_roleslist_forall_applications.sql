
CREATE VIEW utilisateurs.v_roleslist_forall_applications AS
 SELECT a.groupe,
    a.active,
    a.id_role,
    a.identifiant,
    a.nom_role,
    a.prenom_role,
    a.desc_role,
    a.pass,
    a.pass_plus,
    a.email,
    a.id_organisme,
    a.organisme,
    a.id_unite,
    a.remarques,
    a.date_insert,
    a.date_update,
    max(a.id_droit) AS id_droit_max,
    a.id_application
   FROM ( SELECT u.groupe,
            u.id_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.pass_plus,
            u.email,
            u.id_organisme,
            u.active,
            o.nom_organisme AS organisme,
            0 AS id_unite,
            u.remarques,
            u.date_insert,
            u.date_update,
            c.id_profil AS id_droit,
            c.id_application
           FROM ((utilisateurs.t_roles u
             JOIN utilisateurs.cor_role_app_profil c ON ((c.id_role = u.id_role)))
             LEFT JOIN utilisateurs.bib_organismes o ON ((o.id_organisme = u.id_organisme)))
        UNION
         SELECT u.groupe,
            u.id_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.pass_plus,
            u.email,
            u.id_organisme,
            u.active,
            o.nom_organisme AS organisme,
            0 AS id_unite,
            u.remarques,
            u.date_insert,
            u.date_update,
            c.id_profil AS id_droit,
            c.id_application
           FROM (((utilisateurs.t_roles u
             JOIN utilisateurs.cor_roles g ON (((g.id_role_utilisateur = u.id_role) OR (g.id_role_groupe = u.id_role))))
             JOIN utilisateurs.cor_role_app_profil c ON ((c.id_role = g.id_role_groupe)))
             LEFT JOIN utilisateurs.bib_organismes o ON ((o.id_organisme = u.id_organisme)))) a
  WHERE (a.active = true)
  GROUP BY a.groupe, a.active, a.id_role, a.identifiant, a.nom_role, a.prenom_role, a.desc_role, a.pass, a.pass_plus, a.email, a.id_organisme, a.organisme, a.id_unite, a.remarques, a.date_insert, a.date_update, a.id_application;

