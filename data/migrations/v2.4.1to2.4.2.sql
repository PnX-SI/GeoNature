-- Ajout d'une contrainte d'unicité sur la table gn_commons.t_parameters sur le duo de champs id_organism, parameter_name

ALTER TABLE gn_commons.t_parameters ADD CONSTRAINT unique_t_parameters_id_organism_parameter_name UNIQUE (id_organism, parameter_name);
CREATE UNIQUE INDEX i_unique_t_parameters_parameter_name_with_id_organism_null ON gn_commons.t_parameters (parameter_name) WHERE id_organism IS NULL;