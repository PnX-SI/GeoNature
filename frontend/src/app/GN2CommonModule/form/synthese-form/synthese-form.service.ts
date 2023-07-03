import { Injectable } from '@angular/core';
import {
  UntypedFormGroup,
  UntypedFormBuilder,
  UntypedFormControl,
  ValidatorFn,
} from '@angular/forms';
import { HttpParams } from '@angular/common/http';

import { stringify } from 'wellknown';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';

import { DYNAMIC_FORM_DEF } from '@geonature_common/form/synthese-form/dynamicFormConfig';
import { NgbDatePeriodParserFormatter } from '@geonature_common/form/date/ngb-date-custom-parser-formatter';
import { ConfigService } from '@geonature/services/config.service';
import { Observable, of } from 'rxjs';
import { tap, mergeMap } from 'rxjs/operators';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { CommonService } from '@geonature_common/service/common.service';

@Injectable()
export class SyntheseFormService {
  public searchForm: UntypedFormGroup;
  public selectors = new HttpParams();
  public formBuilded = false;
  public selectedtaxonFromComponent = [];
  public selectedCdRefFromTree = [];
  public selectedTaxonFromRankInput = [];
  public dynamycFormDef: Array<any>;
  public areasFilters;
  public statusFilters;
  public selectedStatus = [];
  public redListsFilters;
  public selectedRedLists = [];
  public selectedTaxRefAttributs = [];
  public processedDefaultFilters: any;

  public _nomenclatures: Array<any> = [];

  public syntheseNomenclatureTypes = {
    id_nomenclature_obs_technique: 'METH_OBS',
    id_nomenclature_geo_object_nature: 'NAT_OBJ_GEO',
    id_nomenclature_grp_typ: 'TYP_GRP',
    id_nomenclature_bio_status: 'STATUT_BIO',
    id_nomenclature_bio_condition: 'ETA_BIO',
    id_nomenclature_naturalness: 'NATURALITE',
    id_nomenclature_exist_proof: 'PREUVE_EXIST',
    id_nomenclature_valid_status: 'STATUT_VALID',
    id_nomenclature_diffusion_level: 'NIV_PRECIS',
    id_nomenclature_life_stage: 'STADE_VIE',
    id_nomenclature_sex: 'SEXE',
    id_nomenclature_obj_count: 'OBJ_DENBR',
    id_nomenclature_type_count: 'TYP_DENBR',
    id_nomenclature_sensitivity: 'SENSIBILITE',
    id_nomenclature_observation_status: 'STATUT_OBS',
    id_nomenclature_blurring: 'DEE_FLOU',
    id_nomenclature_source_status: 'STATUT_SOURCE',
    id_nomenclature_biogeo_status: 'STAT_BIOGEO',
  };

  constructor(
    private _fb: UntypedFormBuilder,
    private _dateParser: NgbDateParserFormatter,
    private _periodFormatter: NgbDatePeriodParserFormatter,
    public config: ConfigService,
    private _api: DataFormService,
    private _common: CommonService
  ) {
    this.searchForm = this._fb.group({
      cd_nom: null,
      observers: null,
      observers_list: null,
      id_organism: null,
      id_dataset: null,
      id_acquisition_framework: null,
      id_nomenclature_valid_status: null,
      modif_since_validation: [false, null],
      score: null,
      valid_distribution: null,
      valid_altitude: null,
      valid_phenology: null,
      date_min: null,
      date_max: null,
      period_start: null,
      period_end: null,
      municipalities: null,
      geoIntersection: null,
      taxonomy_lr: null,
      taxonomy_id_hab: null,
      taxonomy_group2_inpn: null,
      taxonomy_group3_inpn: null,
      taxon_rank: null,
    });

    this.searchForm.setValidators([this.periodValidator()]);

    // Add protection status filters defined in configuration parameters
    this.statusFilters = Object.assign([], this.config.SYNTHESE.STATUS_FILTERS);
    this.statusFilters.forEach((status) => {
      const control_name = `${status.id}_protection_status`;
      this.searchForm.addControl(control_name, new UntypedFormControl(new Array()));
      status['control_name'] = control_name;
      status['control'] = this.searchForm.controls[control_name];
    });

    // Add red lists filters defined in configuration parameters
    this.redListsFilters = Object.assign([], this.config.SYNTHESE.RED_LISTS_FILTERS);
    this.redListsFilters.forEach((redList) => {
      const control_name = `${redList.id}_red_lists`;
      this.searchForm.addControl(control_name, new UntypedFormControl(new Array()));
      redList['control'] = this.searchForm.controls[control_name];
    });

    // Add areas filters defined in configuration parameters
    this.areasFilters = Object.assign([], this.config.SYNTHESE.AREA_FILTERS);
    this.config.SYNTHESE.AREA_FILTERS.forEach((area) => {
      const control_name = 'area_' + area['type_code'];
      this.searchForm.addControl(control_name, new UntypedFormControl(new Array()));
      area['control'] = this.searchForm.controls[control_name];
    });

    // Init the dynamic form with the user parameters
    // remove the filters which are in config.SYNTHESE.EXCLUDED_COLUMNS
    this.dynamycFormDef = DYNAMIC_FORM_DEF.filter((formDef) => {
      return this.config.SYNTHESE.EXCLUDED_COLUMNS.indexOf(formDef.attribut_name) === -1;
    });
    this.formBuilded = true;
  }

  getCurrentTaxon($event) {
    this.selectedtaxonFromComponent.push($event.item);
    $event.preventDefault();
    this.searchForm.controls.cd_nom.reset();
  }

  removeTaxon(index, tab) {
    tab.splice(index, 1);
  }

  formatParams() {
    const params = Object.assign({}, this.searchForm.value);
    const updatedParams = {};
    // eslint-disable-next-line guard-for-in

    for (const key in params) {
      if (key === 'cd_nom') {
        // Test if cd_nom is an integer
        if (Number.isInteger(parseInt(params[key], 10))) {
          updatedParams[key] = parseInt(params[key], 10);
        }
      } else if (
        (key === 'date_min' && params.date_min) ||
        (key === 'date_max' && params.date_max)
      ) {
        updatedParams[key] = this._dateParser.format(params[key]);
      } else if (
        (key === 'period_end' && params.period_end) ||
        (key === 'period_start' && params.period_start)
      ) {
        updatedParams[key] = this._periodFormatter.format(params[key]);
      } else if (key === 'geoIntersection' && params['geoIntersection']) {
        // stringify accepte uniquement les geojson simple (pas les feature collection)
        // on boucle sur les feature pour les transformer en WKT
        if (Array.isArray(params['geoIntersection'])) {
          updatedParams['geoIntersection'] = {
            type: 'FeatureCollection',
            features: params['geoIntersection'],
          };
        } else {
          updatedParams['geoIntersection'] = params['geoIntersection'];
        }
        // remove null/undefined but not zero (use for boolean)
      } else if (params[key] != null || params[key] != undefined) {
        // if its an Array push only if > 0
        if (Array.isArray(params[key]) && params[key].length > 0) {
          updatedParams[key] = params[key];
          // else if its not an array, alway send the parameter
        } else if (!Array.isArray(params[key])) {
          updatedParams[key] = params[key];
        }
      }
    }

    if (this.selectedtaxonFromComponent.length > 0) {
      updatedParams['cd_ref'] = this.selectedtaxonFromComponent.map((taxon) => taxon.cd_ref);
    }
    if (this.selectedCdRefFromTree.length > 0 || this.selectedTaxonFromRankInput.length > 0) {
      updatedParams['cd_ref_parent'] = [
        ...this.selectedTaxonFromRankInput.map((el) => el.cd_ref),
        ...this.selectedCdRefFromTree,
      ];
    }
    return updatedParams;
  }

  periodValidator(): ValidatorFn {
    return (formGroup: UntypedFormGroup): { [key: string]: boolean } => {
      const perioStart = formGroup.controls.period_start.value;
      const periodEnd = formGroup.controls.period_end.value;
      if ((perioStart && !periodEnd) || (!perioStart && periodEnd)) {
        return {
          invalidPeriod: true,
        };
      }
      return null;
    };
  }

  haveAdvancedFormValues(): Boolean {
    if (this.selectedTaxonFromRankInput.length > 0) {
      return true;
    } else if (this.selectedCdRefFromTree.length > 0) {
      return true;
    } else if (this.selectedStatus.length > 0) {
      return true;
    } else if (this.selectedRedLists.length > 0) {
      return true;
    } else if (this.selectedTaxRefAttributs.length > 0) {
      return true;
    } else {
      return false;
    }
  }

  getSelectedTaxonsSummary(): String {
    let summary = [];
    if (this.selectedTaxonFromRankInput.length > 0) {
      summary.push(
        'Rangs : ' + this.selectedTaxonFromRankInput.map((e) => e.lb_nom).join(', ') + '.'
      );
    }
    if (this.selectedCdRefFromTree.length > 0) {
      summary.push('Arbre taxo : ' + this.selectedCdRefFromTree.length + ' taxons.');
    }
    return summary.join(' ');
  }

  initNomenclatures(): Observable<Array<any>> {
    if (this._nomenclatures.length) {
      return of(this._nomenclatures);
    }
    return this._api.getNomenclatures(Object.values(this.syntheseNomenclatureTypes)).pipe(
      tap((nomenclatures) => {
        for (const nomenclatureType of nomenclatures) {
          for (const nomenclature of nomenclatureType.values) {
            this._nomenclatures.push({ ...nomenclature, type: nomenclatureType.mnemonique });
          }
        }
      })
    );
  }

  processDefaultFilters(filters): Observable<any> {
    return this.initNomenclatures().pipe(
      mergeMap(() => {
        const defaultFilters = {};
        for (const [key, value] of Object.entries(filters)) {
          // on ne prend pas en compte les filtres à 'null'
          if ([null, undefined, []].includes(value as any)) {
            continue;
          }

          defaultFilters[key] = value;
          // traitement des dates
          if (['date_min', 'date_max'].includes(key) && value) {
            const d = new Date(defaultFilters[key]);
            defaultFilters[key] = {
              year: d.getUTCFullYear(),
              month: d.getUTCMonth() + 1,
              day: d.getUTCDate(),
            };
          }

          // traitement des nomenclatures
          if (key.startsWith('cd_nomenclature_')) {
            const targetKey = key.replace('cd_nomenclature_', 'id_nomenclature_');
            const nomenclatureType = this.syntheseNomenclatureTypes[targetKey];
            if (!nomenclatureType) {
              const errorMsg = `Filtres par défaut: le type de nomenclature n'a pas été trouvé pour la clé ${key}`;
              console.error(errorMsg);
              this._common.regularToaster('error', errorMsg);
            }
            if (!Array.isArray(value)) {
              const errorMsg = `Filtres par défaut: la valeur du filtre par défaut pour ${key} doit être une liste de codes`;
              console.error(errorMsg);
              this._common.regularToaster('error', errorMsg);
            }
            const nomenclatureIds = (value as Array<string>)
              .map((cdNomenclature) => {
                const nomenclature = this._nomenclatures.find(
                  (n) => n['type'] == nomenclatureType && n['cd_nomenclature'] == cdNomenclature
                );
                if (!nomenclature) {
                  const errorMsg = `Filtres par défaut: pas de nomenclature trouvée pour <type.cd_nomenclature> = ${nomenclatureType}.${cdNomenclature}`;
                  console.error(errorMsg);
                  this._common.regularToaster('error', errorMsg);
                  return;
                }
                return nomenclature['id_nomenclature'];
              })
              .filter((idNomenclature) => !!idNomenclature);

            delete defaultFilters[key];
            defaultFilters[targetKey] = nomenclatureIds;
          }
        }

        return of(defaultFilters);
      })
    );
  }
}
