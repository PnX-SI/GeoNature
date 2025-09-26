

CREATE VIEW utilisateurs.v_userslist_forall_menu AS
 SELECT a.groupe,
    a.id_role,
    a.uuid_role,
    a.identifiant,
    a.nom_role,
    a.prenom_role,
    ((upper((a.nom_role)::text) || ' '::text) || (a.prenom_role)::text) AS nom_complet,
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
    a.id_menu
   FROM ( SELECT u.groupe,
            u.id_role,
            u.uuid_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.pass_plus,
            u.email,
            u.id_organisme,
            o.nom_organisme AS organisme,
            0 AS id_unite,
            u.remarques,
            u.date_insert,
            u.date_update,
            c.id_liste AS id_menu
           FROM ((utilisateurs.t_roles u
             JOIN utilisateurs.cor_role_liste c ON ((c.id_role = u.id_role)))
             LEFT JOIN utilisateurs.bib_organismes o ON ((o.id_organisme = u.id_organisme)))
          WHERE ((u.groupe = false) AND (u.active = true))
        UNION
         SELECT u.groupe,
            u.id_role,
            u.uuid_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.pass_plus,
            u.email,
            u.id_organisme,
            o.nom_organisme AS organisme,
            0 AS id_unite,
            u.remarques,
            u.date_insert,
            u.date_update,
            c.id_liste AS id_menu
           FROM (((utilisateurs.t_roles u
             JOIN utilisateurs.cor_roles g ON ((g.id_role_utilisateur = u.id_role)))
             JOIN utilisateurs.cor_role_liste c ON ((c.id_role = g.id_role_groupe)))
             LEFT JOIN utilisateurs.bib_organismes o ON ((o.id_organisme = u.id_organisme)))
          WHERE ((u.groupe = false) AND (u.active = true))) a;


