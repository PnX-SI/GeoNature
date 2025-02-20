
CREATE TABLE pr_occtax.cor_role_releves_occtax (
    unique_id_cor_role_releve uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_releve_occtax bigint NOT NULL,
    id_role integer NOT NULL
);

ALTER TABLE ONLY pr_occtax.cor_role_releves_occtax
    ADD CONSTRAINT pk_cor_role_releves_occtax PRIMARY KEY (id_releve_occtax, id_role);

CREATE INDEX i_cor_role_releves_occtax_id_releve_occtax ON pr_occtax.cor_role_releves_occtax USING btree (id_releve_occtax);

CREATE INDEX i_cor_role_releves_occtax_id_role ON pr_occtax.cor_role_releves_occtax USING btree (id_role);

CREATE UNIQUE INDEX i_cor_role_releves_occtax_id_role_id_releve_occtax ON pr_occtax.cor_role_releves_occtax USING btree (id_role, id_releve_occtax);

CREATE TRIGGER tri_delete_synthese_cor_role_releves_occtax AFTER DELETE ON pr_occtax.cor_role_releves_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_delete_cor_role_releve();

CREATE TRIGGER tri_log_changes_cor_role_releves_occtax AFTER INSERT OR DELETE OR UPDATE ON pr_occtax.cor_role_releves_occtax FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_synthese_insert_cor_role_releve AFTER INSERT ON pr_occtax.cor_role_releves_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_insert_cor_role_releve();

CREATE TRIGGER tri_update_synthese_cor_role_releves_occtax AFTER UPDATE ON pr_occtax.cor_role_releves_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_update_cor_role_releve();

ALTER TABLE ONLY pr_occtax.cor_role_releves_occtax
    ADD CONSTRAINT fk_cor_role_releves_occtax_t_releves_occtax FOREIGN KEY (id_releve_occtax) REFERENCES pr_occtax.t_releves_occtax(id_releve_occtax) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY pr_occtax.cor_role_releves_occtax
    ADD CONSTRAINT fk_cor_role_releves_occtax_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

