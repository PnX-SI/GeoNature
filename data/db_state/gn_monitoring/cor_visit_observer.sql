
CREATE TABLE gn_monitoring.cor_visit_observer (
    id_base_visit integer NOT NULL,
    id_role integer NOT NULL,
    unique_id_core_visit_observer uuid DEFAULT public.uuid_generate_v4() NOT NULL
);

ALTER TABLE ONLY gn_monitoring.cor_visit_observer
    ADD CONSTRAINT pk_cor_visit_observer PRIMARY KEY (id_base_visit, id_role);

CREATE TRIGGER tri_log_changes_cor_visit_observer AFTER INSERT OR DELETE OR UPDATE ON gn_monitoring.cor_visit_observer FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

ALTER TABLE ONLY gn_monitoring.cor_visit_observer
    ADD CONSTRAINT fk_cor_visit_observer_id_base_visit FOREIGN KEY (id_base_visit) REFERENCES gn_monitoring.t_base_visits(id_base_visit) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_monitoring.cor_visit_observer
    ADD CONSTRAINT fk_cor_visit_observer_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

