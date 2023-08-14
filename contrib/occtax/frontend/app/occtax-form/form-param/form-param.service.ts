import { Injectable } from "@angular/core";
import { BehaviorSubject } from "rxjs";
import { OcctaxDataService } from "../../services/occtax-data.service";

interface OCCTAX_FORM_PARAM {
  geometry?: any;
  releve?: {
    place_name?: string;
    id_dataset?: number;
    id_digitiser?: number;
    date_min?: string;
    date_max?: string;
    hour_min?: string;
    hour_max?: string;
    altitude_min?: number;
    altitude_max?: number;
    depth_min?: number;
    depth_max?: number;
    meta_device_entry?: string;
    comment?: string;
    cd_hab?: number;
    id_nomenclature_tech_collect_campanule?: number;
    observers?: Array<any>;
    observers_txt?: string;
    id_nomenclature_grp_typ?: number;
    grp_method?: string;
    id_nomenclature_geo_object_nature?: number;
    precision?: number;
  };
  occurrence?: {
    id_nomenclature_obs_technique?: number;
    id_nomenclature_bio_condition?: number;
    id_nomenclature_bio_status?: number;
    id_nomenclature_naturalness?: number;
    id_nomenclature_exist_proof?: number;
    id_nomenclature_behaviour?: number;
    id_nomenclature_observation_status?: number;
    id_nomenclature_blurring?: number;
    id_nomenclature_source_status?: number;
    determiner?: string;
    id_nomenclature_determination_method?: number;
    sample_number_proof?: string;
    digital_proof?: string;
    non_digital_proof?: string;
    comment?: string;
  };
  counting?: {
    id_nomenclature_life_stage: number;
    id_nomenclature_sex: number;
    id_nomenclature_obj_count: number;
    id_nomenclature_type_count: number;
    count_min: number;
    count_max: number;
  };
}

@Injectable()
export class OcctaxFormParamService {
  parameters: OCCTAX_FORM_PARAM = {
    geometry: null,
    releve: {
      place_name: null,
      id_dataset: null,
      id_digitiser: null,
      date_min: null,
      date_max: null,
      hour_min: null,
      hour_max: null,
      altitude_min: null,
      altitude_max: null,
      depth_min: null,
      depth_max: null,
      meta_device_entry: null,
      comment: null,
      cd_hab: null,
      id_nomenclature_tech_collect_campanule: null,
      observers: null,
      observers_txt: null,
      id_nomenclature_grp_typ: null,
      grp_method: null,
      id_nomenclature_geo_object_nature: null,
      precision: null,
    },
    occurrence: {
      id_nomenclature_obs_technique: null,
      id_nomenclature_bio_condition: null,
      id_nomenclature_bio_status: null,
      id_nomenclature_naturalness: null,
      id_nomenclature_exist_proof: null,
      id_nomenclature_behaviour: null,
      id_nomenclature_observation_status: null,
      id_nomenclature_blurring: null,
      id_nomenclature_source_status: null,
      determiner: null,
      id_nomenclature_determination_method: null,
      sample_number_proof: null,
      digital_proof: null,
      non_digital_proof: null,
      comment: null,
    },
    counting: {
      id_nomenclature_life_stage: null,
      id_nomenclature_sex: null,
      id_nomenclature_obj_count: null,
      id_nomenclature_type_count: null,
      count_min: null,
      count_max: null,
    },
  };

  geometryState: BehaviorSubject<boolean> = new BehaviorSubject(false);
  releveState: BehaviorSubject<boolean> = new BehaviorSubject(false);
  occurrenceState: BehaviorSubject<boolean> = new BehaviorSubject(false);
  countingState: BehaviorSubject<boolean> = new BehaviorSubject(false);

  get geometry() {
    return this.geometryState.getValue() ? this.parameters.geometry : null;
  }
  get releve() {
    return this.releveState.getValue() ? this.parameters.releve : null;
  }
  get occurrence() {
    return this.occurrenceState.getValue() ? this.parameters.occurrence : null;
  }
  get counting() {
    return this.countingState.getValue() ? this.parameters.counting : null;
  }

  get numberOfActive() {
    return (
      (this.geometryState.getValue() ? 1 : 0) +
      (this.releveState.getValue() ? 1 : 0) +
      (this.occurrenceState.getValue() ? 1 : 0) +
      (this.countingState.getValue() ? 1 : 0)
    );
  }
  public moduleConfig;

  constructor(private _ds: OcctaxDataService) {}

  get(element: string) {
    let keys = element.split(".");
    let temp_value = this.parameters;
    let value = null;
    //vérification de l'activation du paramètre en config occtax
    if (this._ds.moduleConfig.ENABLE_SETTINGS_TOOLS) {
      for (let i = 0; i < keys.length; i++) {
        //si les changement de paramètre sont désactivé ou si la clé fournie n'existe pas
        if (temp_value === null || temp_value[keys[i]] === undefined) {
          break;
        }

        if (temp_value[keys[i]] !== undefined) {
          if (i == 0) {
            temp_value = this[keys[i]];
          } else {
            temp_value = temp_value[keys[i]];
          }

          if (keys.length == i + 1) {
            value = temp_value;
          }
        }
      }
    }

    return value;
  }
}
