"""Update nomenclature_dataset_objectifs

Revision ID: 05960b6c6292
Revises: ae0b6362fb22
Create Date: 2026-07-02 09:54:00

"""

from typing import Tuple

from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import column

# revision identifiers, used by Alembic.
revision = "05960b6c6292"
down_revision = "ae0b6362fb22"
branch_labels = None
depends_on = None


class NomenclatureObjectifsMigration:
    """
    Encapsulate migration logic for NomenclatureDatasetObjectifs
    (MTDv1 -> MTDv2), see ticket #4102.
    """

    mnemonique = "JDD_OBJECTIFS"

    # new nomenclature for MTDv2
    new_nomenclatures = [
        ("1", "Observations naturalistes opportunistes"),
        ("2", "Observations protocolées"),
        ("3", "Inventaire"),
        ("4", "Inventaire de répartition"),
        ("5", "Inventaire de zonages d'intérêt"),
        ("6", "Inventaire pour étude d'espèces ou de communautés"),
        ("7", "Inventaire pour étude d'impact"),
        ("8", "Inventaire / évaluation pour plans de gestion"),
        ("9", "Numérisation"),
        ("10", "Numérisation de bibliographie"),
        ("11", "Numérisation de collections"),
        ("12", "Cartographie"),
        ("13", "Suivi"),
        ("14", "Suivi de gestion ou expérimental"),
        ("15", "Suivi individu centré"),
        ("16", "Suivi réglementaire"),
        ("17", "Surveillance"),
        ("18", "Surveillance communauté d'espèces"),
        ("19", "Surveillance de pathogène et EEE"),
        ("20", "Étude effet gestion"),
        ("21", "Évaluation"),
        ("22", "Évaluation de la ressource / prélèvements"),
        ("23", "Évaluation des collisions / échouages"),
        ("24", "Modélisation de données"),
        ("25", "Regroupement de données"),
        ("26", "Autres études et programmes"),
    ]

    # correspondance between old and new nomenclature for MTDv2  see ticket #4102
    old_to_new_nomenclatures = {
        "1.1": "1",
        "1.2": "4",
        "1.3": "6",
        "1.4": "11",
        "1.5": "10",
        "2.1": "12",
        "2.2": "3",
        "2.3": "1",
        "2.4": "3",
        "2.5": "9",
        "3.1": "3",
        "3.2": "5",
        "3.3": "8",
        "3.4": "1",
        "3.5": "3",
        "3.6": "7",
        "3.7": "12",
        "4.1": "22",
        "4.2": "23",
        "5.1": "15",
        "5.2": "17",
        "5.3": "18",
        "5.4": "17",
        "5.5": "19",
        "6.1": "17",
        "6.2": "14",
        "6.3": "20",
        "6.4": "16",
        "7.1": "25",
        "7.2": "26",
    }

    def __init__(self):
        self.conn = op.get_bind()
        self.ambiguous_new_objectives = self.get_ambiguous_new_objectives()
        # the reverse map cannot guarantee to be exact as there can be multiple valid old_cd for a new_cd
        self.reverse_map = {}
        for old_cd, new_cd in self.old_to_new_nomenclatures.items():
            self.reverse_map.setdefault(new_cd, old_cd)

    def get_ambiguous_new_objectives(self) -> list[str]:
        """

        Returns
        -------
        a dict containing new cd_nomenclature that can be matched against
        multiple old ones. This means we can't downgrade without risking
        losing data on those cd
        """
        new_cd_counts = {}
        for new_cd in self.old_to_new_nomenclatures.values():
            new_cd_counts[new_cd] = new_cd_counts.get(new_cd, 0) + 1
        new_cd_counts = new_cd_counts
        ambiguous_new_objectives = sorted(cd for cd, count in new_cd_counts.items() if count > 1)
        return ambiguous_new_objectives

    @staticmethod
    def _values_clause(
        rows: list[Tuple[str, str]], param_names: list[str], prefix: str
    ) -> Tuple[str, dict[str, str]]:
        """
        Build an sql clause with binded parameters.

        Example:
            rows = [("1", "1.1"), ("2", "1.2")]
            param_names = ["old_cd", "new_cd"]
            prefix = "map"
            ->
            generated sql
            (:map_old_cd_0, :map_new_cd_0), (:map_old_cd_1, :map_new_cd_1)

            bind params
            {
                "map_old_cd_0": "1",
                "map_new_cd_0": "1.1",
                "map_old_cd_1": "2",
                "map_new_cd_1": "1.2"
            }

        Returns a tuple containing the sql clause and the bind params.
        """
        placeholders = []
        params = {}
        for i, row in enumerate(rows):
            row_keys = [f"{prefix}_{name}_{i}" for name in param_names]
            placeholders.append("(" + ", ".join(f":{k}" for k in row_keys) + ")")
            params.update(dict(zip(row_keys, row)))
        return ", ".join(placeholders), params

    def insert_new_nomenclatures(self) -> None:
        """
        Insert new nomenclature items for MTDv2.
        """
        values_sql, values_params = self._values_clause(
            self.new_nomenclatures, ["cd", "label"], "new"
        )
        self.conn.execute(
            sa.text(f"""
                INSERT INTO ref_nomenclatures.t_nomenclatures
                    (id_type, cd_nomenclature, mnemonique,
                     label_default, definition_default,
                     label_fr, definition_fr, active)
                SELECT t.id_type, v.cd, v.cd, v.label, v.label, v.label, v.label, true
                FROM ref_nomenclatures.bib_nomenclatures_types t,
                     (VALUES {values_sql}) AS v(cd, label)
                WHERE t.mnemonique = '{self.mnemonique}'
                ON CONFLICT (id_type, cd_nomenclature) DO NOTHING
            """),
            values_params,
        )

    def delete_new_nomenclatures(self) -> None:
        """
        delete new nomenclature items for MTDv2.
        """
        new_cds = [cd for cd, _ in self.new_nomenclatures]
        self.conn.execute(
            sa.text(f"""
                    DELETE
                    FROM ref_nomenclatures.t_nomenclatures USING ref_nomenclatures.bib_nomenclatures_types t
                    WHERE t_nomenclatures.id_type = t.id_type
                      AND t.mnemonique = '{self.mnemonique}'
                      AND t_nomenclatures.cd_nomenclature = ANY (:new_cds)
                    """),
            {"new_cds": new_cds},
        )

    def map_old_nomenclatures_to_new(self):
        """
        Map old nomenclature items to new ones.
        """
        map_sql, map_params = self._values_clause(
            list(self.old_to_new_nomenclatures.items()), ["old_cd", "new_cd"], "map"
        )
        self.conn.execute(
            sa.text(f"""
                UPDATE gn_meta.cor_dataset_objectif cdo
                SET id_nomenclature_objectif = new_nom.id_nomenclature
                FROM (VALUES {map_sql}) AS map(old_cd, new_cd)
                JOIN ref_nomenclatures.bib_nomenclatures_types t
                    ON t.mnemonique = '{self.mnemonique}'
                JOIN ref_nomenclatures.t_nomenclatures old_nom
                    ON old_nom.id_type = t.id_type AND old_nom.cd_nomenclature = map.old_cd
                JOIN ref_nomenclatures.t_nomenclatures new_nom
                    ON new_nom.id_type = t.id_type AND new_nom.cd_nomenclature = map.new_cd
                WHERE cdo.id_nomenclature_objectif = old_nom.id_nomenclature
            """),
            map_params,
        )

    def map_new_nomenclature_to_old(self):
        """
        Map new nomenclature items to old ones. If multiple old nomenclature is possible, we choose one arbitrarily.
        """
        reverse_sql, reverse_params = self._values_clause(
            list(self.reverse_map.items()), ["new_cd", "old_cd"], "rev"
        )
        self.conn.execute(
            sa.text(f"""
                UPDATE gn_meta.cor_dataset_objectif cdo
                SET id_nomenclature_objectif = old_nom.id_nomenclature
                FROM (VALUES {reverse_sql}) AS map(new_cd, old_cd)
                JOIN ref_nomenclatures.bib_nomenclatures_types t
                    ON t.mnemonique = '{self.mnemonique}'
                JOIN ref_nomenclatures.t_nomenclatures new_nom
                    ON new_nom.id_type = t.id_type AND new_nom.cd_nomenclature = map.new_cd
                JOIN ref_nomenclatures.t_nomenclatures old_nom
                    ON old_nom.id_type = t.id_type AND old_nom.cd_nomenclature = map.old_cd
                WHERE cdo.id_nomenclature_objectif = new_nom.id_nomenclature
            """),
            reverse_params,
        )

    def change_default_nomenclature_to_new(self):
        """
        Transfer old default nomenclature to new ones.
        """
        map_sql, map_params = self._values_clause(
            list(self.old_to_new_nomenclatures.items()), ["old_cd", "new_cd"], "map"
        )
        self.conn.execute(
            sa.text(f"""
                UPDATE ref_nomenclatures.defaults_nomenclatures_value dv
                SET id_nomenclature = new_nom.id_nomenclature
                FROM (VALUES {map_sql}) AS map(old_cd, new_cd)
                JOIN ref_nomenclatures.bib_nomenclatures_types t
                    ON t.mnemonique = '{self.mnemonique}'
                JOIN ref_nomenclatures.t_nomenclatures old_nom
                    ON old_nom.id_type = t.id_type AND old_nom.cd_nomenclature = map.old_cd
                JOIN ref_nomenclatures.t_nomenclatures new_nom
                    ON new_nom.id_type = t.id_type AND new_nom.cd_nomenclature = map.new_cd
                WHERE dv.id_nomenclature = old_nom.id_nomenclature
            """),
            map_params,
        )

    def change_default_nomenclature_to_old(self):
        """
        Transfer new default nomenclature to old ones. If multiple old nomenclature is possible, we choose one arbitrarily.
        """
        reverse_sql, reverse_params = self._values_clause(
            list(self.reverse_map.items()), ["new_cd", "old_cd"], "rev"
        )
        self.conn.execute(
            sa.text(f"""
                UPDATE ref_nomenclatures.defaults_nomenclatures_value dv
                SET id_nomenclature = old_nom.id_nomenclature
                FROM (VALUES {reverse_sql}) AS map(new_cd, old_cd)
                JOIN ref_nomenclatures.bib_nomenclatures_types t
                    ON t.mnemonique = '{self.mnemonique}'
                JOIN ref_nomenclatures.t_nomenclatures new_nom
                    ON new_nom.id_type = t.id_type AND new_nom.cd_nomenclature = map.new_cd
                JOIN ref_nomenclatures.t_nomenclatures old_nom
                    ON old_nom.id_type = t.id_type AND old_nom.cd_nomenclature = map.old_cd
                WHERE dv.id_nomenclature = new_nom.id_nomenclature
            """),
            reverse_params,
        )

    def deactivate_old_nomenclatures(self):
        self.set_state_old_nomenclatures(False)

    def activate_old_nomenclatures(self):
        self.set_state_old_nomenclatures(True)

    def set_state_old_nomenclatures(self, state: bool):
        old_cds = list(self.old_to_new_nomenclatures.keys())
        self.conn.execute(
            sa.text(f"""
                    UPDATE ref_nomenclatures.t_nomenclatures
                    SET active = :state FROM ref_nomenclatures.bib_nomenclatures_types t
                    WHERE t_nomenclatures.id_type = t.id_type
                      AND t.mnemonique = '{self.mnemonique}'
                      AND t_nomenclatures.cd_nomenclature = ANY (:old_cds)
                    """),
            {"state": state, "old_cds": old_cds},
        )

    def get_ambiguous_row(self):
        """
        Get list of rows we can't downgrade automatically without risking losing data.
        Happens when one new cd_nomenclature is linked to multiple old ones (ex: "1" <- 1.1, 2.3, 3.4)
        """
        return self.conn.execute(
            sa.text(f"""
                    SELECT cdo.id_dataset,
                           new_nom.cd_nomenclature,
                           new_nom.label_default
                    FROM gn_meta.cor_dataset_objectif cdo
                             JOIN ref_nomenclatures.t_nomenclatures new_nom
                                  ON new_nom.id_nomenclature = cdo.id_nomenclature_objectif
                             JOIN ref_nomenclatures.bib_nomenclatures_types t
                                  ON t.id_type = new_nom.id_type AND t.mnemonique = '{self.mnemonique}'
                    WHERE new_nom.cd_nomenclature = ANY (:ambiguous_cds)
                    ORDER BY cdo.id_dataset
                    """),
            {"ambiguous_cds": self.ambiguous_new_objectives},
        ).all()

    def ask_user_for_ambiguous_row(self, ambiguous_rows):
        """
        Ask user for confirmation when we can't downgrade automatically without risking losing data.
        """
        if ambiguous_rows:
            target_nomenclatures = self.conn.execute(
                sa.text(f"""
                        SELECT cd_nomenclature, t_nomenclatures.label_default
                        FROM ref_nomenclatures.t_nomenclatures t_nomenclatures
                                 JOIN ref_nomenclatures.bib_nomenclatures_types t
                                      ON t.id_type = t_nomenclatures.id_type
                        WHERE cd_nomenclature = ANY (:new_cds)
                          AND t.mnemonique = '{self.mnemonique}'
                        """),
                {"new_cds": list(self.reverse_map.keys())},
            ).all()

            target_labels = {row.cd_nomenclature: row.label_default for row in target_nomenclatures}
            formatted = "\n            - ".join(
                f"id_dataset={row.id_dataset} "
                f"cd_nomenclature actuel {row.cd_nomenclature} - ({row.label_default})"
                f", serait remappé vers {self.reverse_map[row.cd_nomenclature]} "
                f"({target_labels.get(row.cd_nomenclature)})"
                for row in ambiguous_rows
            )
            print(f"""
                /!\\ ATTENTION - CORRESPONDANCE AMBIGUË /!\\
                Les jeux de données suivants ont un objectif qui résulte de la
                fusion de plusieurs anciennes valeurs (standard v2 -> v1). Le
                mappage automatique choisira une valeur arbitraire, SANS
                garantie que ce soit la bonne :\n
                - {formatted}\n
                """)
            answer = (
                input("Continuer le downgrade avec ce mappage arbitraire ? [y/N] ").strip().lower()
            )
            if answer != "y":
                raise Exception(
                    "Downgrade annulé par l'utilisateur : validation manuelle requise "
                    "sur les jeux de données listés ci-dessus avant de relancer."
                )


def upgrade():
    migration = NomenclatureObjectifsMigration()
    migration.insert_new_nomenclatures()
    migration.map_old_nomenclatures_to_new()
    migration.change_default_nomenclature_to_new()
    migration.deactivate_old_nomenclatures()


def downgrade():
    migration = NomenclatureObjectifsMigration()
    ambiguous_rows = migration.get_ambiguous_row()
    migration.ask_user_for_ambiguous_row(ambiguous_rows)
    migration.map_new_nomenclature_to_old()
    migration.change_default_nomenclature_to_old()
    migration.activate_old_nomenclatures()
    migration.delete_new_nomenclatures()
