import { Inject, Injectable } from '@angular/core';
import { FormGroup, FormBuilder, FormControl, ValidatorFn } from '@angular/forms';

import { stringify } from 'wellknown';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';

import { APP_CONFIG_TOKEN } from '@geonature_config/app.config';
import { DYNAMIC_FORM_DEF } from '@geonature_common/form/synthese-form/dynamicFormConfig';
import { NgbDatePeriodParserFormatter } from '@geonature_common/form/date/ngb-date-custom-parser-formatter';

@Injectable()
export class SyntheseFormService {
  public searchForm: FormGroup;
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

  constructor(
    @Inject(APP_CONFIG_TOKEN) private cfg,
    private _fb: FormBuilder,
    private _dateParser: NgbDateParserFormatter,
    private _periodFormatter: NgbDatePeriodParserFormatter
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
      radius: null,
      taxonomy_lr: null,
      taxonomy_id_hab: null,
      taxonomy_group2_inpn: null,
      taxon_rank: null,
    });

    this.searchForm.setValidators([this.periodValidator()]);

    // Add protection status filters defined in configuration parameters
    this.statusFilters = Object.assign([], this.cfg.SYNTHESE.STATUS_FILTERS);
    this.statusFilters.forEach((status) => {
      const control_name = `${status.id}_status`;
      this.searchForm.addControl(control_name, new FormControl(new Array()));
      status['control_name'] = control_name;
      status['control'] = this.searchForm.controls[control_name];
    });

    // Add red lists filters defined in configuration parameters
    this.redListsFilters = Object.assign([], this.cfg.SYNTHESE.RED_LISTS_FILTERS);
    this.redListsFilters.forEach((redList) => {
      const control_name = `${redList.id}_red_lists`;
      this.searchForm.addControl(control_name, new FormControl(new Array()));
      redList['control'] = this.searchForm.controls[control_name];
    });

    // Add areas filters defined in configuration parameters
    this.areasFilters = Object.assign([], this.cfg.SYNTHESE.AREA_FILTERS);
    this.cfg.SYNTHESE.AREA_FILTERS.forEach((area) => {
      const control_name = 'area_' + area['type_code'];
      this.searchForm.addControl(control_name, new FormControl(new Array()));
      area['control'] = this.searchForm.controls[control_name];
    });

    // Init the dynamic form with the user parameters
    // remove the filters which are in AppConfig.SYNTHESE.EXCLUDED_COLUMNS
    this.dynamycFormDef = DYNAMIC_FORM_DEF.filter((formDef) => {
      return this.cfg.SYNTHESE.EXCLUDED_COLUMNS.indexOf(formDef.attribut_name) === -1;
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
          updatedParams['geoIntersection'] = params['geoIntersection'].map((geojson) => {
            return stringify(geojson);
          });
        } else {
          updatedParams['geoIntersection'] = stringify(params['geoIntersection']);
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
    return (formGroup: FormGroup): { [key: string]: boolean } => {
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
}
