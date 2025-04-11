
CREATE TABLE gn_synthese.cor_observer_synthese (
    id_synthese integer NOT NULL,
    id_role integer NOT NULL
);

ALTER TABLE ONLY gn_synthese.cor_observer_synthese
    ADD CONSTRAINT pk_cor_observer_synthese PRIMARY KEY (id_synthese, id_role);

CREATE TRIGGER trg_maj_synthese_observers_txt AFTER INSERT OR DELETE OR UPDATE ON gn_synthese.cor_observer_synthese FOR EACH ROW EXECUTE FUNCTION gn_synthese.fct_tri_maj_observers_txt();

ALTER TABLE ONLY gn_synthese.cor_observer_synthese
    ADD CONSTRAINT fk_gn_synthese_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.cor_observer_synthese
    ADD CONSTRAINT fk_gn_synthese_id_synthese FOREIGN KEY (id_synthese) REFERENCES gn_synthese.synthese(id_synthese) ON UPDATE CASCADE ON DELETE CASCADE;

