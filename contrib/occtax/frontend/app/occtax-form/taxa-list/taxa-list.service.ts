import { Injectable } from "@angular/core";
import { map } from "rxjs/operators";
import { BehaviorSubject } from "rxjs";
import { DataFormService } from "@geonature_common/form/data-form.service";

const NOMENCLATURES = [
  "METH_DETERMIN",
  "STATUT_OBS",
  "METH_OBS",
  "ETA_BIO",
  "NATURALITE",
  "STATUT_BIO",
  "STATUT_SOURCE",
  "NIV_PRECIS",
  "DEE_FLOU",
  "PREUVE_EXIST",
  "STADE_VIE",
  "SEXE",
  "OBJ_DENBR",
  "TYP_DENBR",
  "OCC_COMPORTEMENT"
];

@Injectable()
export class OcctaxTaxaListService {
  nomenclatures: Array<any> = [];
  rec_occurrences_in_progress: Array<any> = [];
  public occurrences$: BehaviorSubject<Array<any>> = new BehaviorSubject([]);

  constructor(private dataFormS: DataFormService) {
    this.getNomenclatures();
  }

  getNomenclatures() {
    this.dataFormS
      .getNomenclatures(NOMENCLATURES)
      .pipe(
        map((data) => {
          let values = [];
          for (let i = 0; i < data.length; i++) {
            data[i].values.forEach((element) => {
              values[element.id_nomenclature] = element;
            });
          }
          return values;
        })
      )
      .subscribe((nomenclatures) => (this.nomenclatures = nomenclatures));
  }

  getLibelleByID(ID: number, lang: string = "default") {
    return this.nomenclatures[ID]
      ? this.nomenclatures[ID][`label_${lang}`]
      : null;
  }

  getCdNomenclatureByID(ID: number) {
    return this.nomenclatures[ID]
      ? this.nomenclatures[ID]["cd_nomenclature"]
      : null;
  }

  addOccurrenceInProgress(temp_id, occurrence) {
    let data = {
      id: temp_id,
      data: occurrence,
      state: "in_progress",
    };
    this.rec_occurrences_in_progress.push(data);
  }

  removeOccurrenceInProgress(temp_id) {
    for (let i = 0; i < this.rec_occurrences_in_progress.length; i++) {
      if (this.rec_occurrences_in_progress[i].id === temp_id) {
        this.rec_occurrences_in_progress.splice(i, 1);
        break;
      }
    }
  }

  errorOccurrenceInProgress(temp_id) {
    for (let i = 0; i < this.rec_occurrences_in_progress.length; i++) {
      if (this.rec_occurrences_in_progress[i].id === temp_id) {
        this.rec_occurrences_in_progress[i].state = "error";
        break;
      }
    }
  }

  cleanOccurrenceInProgress() {
    this.rec_occurrences_in_progress = [];
  }
}
