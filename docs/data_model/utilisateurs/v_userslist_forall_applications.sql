

CREATE VIEW utilisateurs.v_userslist_forall_applications AS
 SELECT d.groupe,
    d.active,
    d.id_role,
    d.identifiant,
    d.nom_role,
    d.prenom_role,
    d.desc_role,
    d.pass,
    d.pass_plus,
    d.email,
    d.id_organisme,
    d.organisme,
    d.id_unite,
    d.remarques,
    d.date_insert,
    d.date_update,
    d.id_droit_max,
    d.id_application
   FROM utilisateurs.v_roleslist_forall_applications d
  WHERE (d.groupe = false);


