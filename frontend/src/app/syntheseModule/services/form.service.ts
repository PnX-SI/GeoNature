import { Injectable } from '@angular/core';
import { FormGroup, FormBuilder, FormControl, ValidatorFn } from '@angular/forms';
import { AppConfig } from '@geonature_config/app.config';
import { stringify as toWKT } from 'wellknown';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { NgbDatePeriodParserFormatter } from '@geonature_common/form/date/ngb-date-custom-parser-formatter';
import { DYNAMIC_FORM_DEF } from '@geonature_common/form/synthese-form/dynamicFormConfig';
import { isArray } from 'util';

@Injectable()
export class SyntheseFormService {
  public searchForm: FormGroup;
  public formBuilded = false;
  public selectedtaxonFromComponent = [];
  public selectedCdRefFromTree = [];
  public dynamycFormDef: Array<any>;

  constructor(
    private _fb: FormBuilder,
    private _dateParser: NgbDateParserFormatter,
    private _periodFormatter: NgbDatePeriodParserFormatter
  ) {
    this.searchForm = this._fb.group({
      cd_nom: null,
      observers: null,
      id_organism: null,
      id_dataset: null,
      id_acquisition_framework: null,
      date_min: null,
      date_max: null,
      period_start: null,
      period_end: null,
      geoIntersection: null,
      radius: null,
      taxonomy_lr: null,
      taxonomy_id_hab: null,
      taxonomy_group2_inpn: null
    });

    this.searchForm.setValidators([this.periodValidator()]);

    AppConfig.SYNTHESE.AREA_FILTERS.forEach(area => {
      const control_name = 'area_' + area.id_type;
      this.searchForm.addControl(control_name, new FormControl(new Array()));
      const control = this.searchForm.controls[control_name];
      area['control'] = control;
    });
    // init the dynamic form with the user parameters
    // remove the filters which are in AppConfig.SYNTHESE.EXCLUDED_COLUMNS
    this.dynamycFormDef = DYNAMIC_FORM_DEF.filter(formDef => {
      return AppConfig.SYNTHESE.EXCLUDED_COLUMNS.indexOf(formDef.attribut_name) === -1;
    });
    this.formBuilded = true;
  }

  getCurrentTaxon($event) {
    this.selectedtaxonFromComponent.push($event.item);
    $event.preventDefault();
    this.searchForm.controls.cd_nom.reset();
  }

  removeTaxon(index) {
    this.selectedtaxonFromComponent.splice(index, 1);
  }

  formatParams() {
    // function which take parameters from the form and format them correctly
    // before build url query string
    const params = Object.assign({}, this.searchForm.value);
    const updatedParams = {};
    // tslint:disable-next-line:forin
    for (let key in params) {
      if ((key === 'date_min' && params.date_min) || (key === 'date_max' && params.date_max)) {
        updatedParams[key] = this._dateParser.format(params[key]);
      } else if (
        (key === 'period_end' && params.period_end) ||
        (key === 'period_start' && params.period_start)
      ) {
        updatedParams[key] = this._periodFormatter.format(params[key]);
      } else if (key === 'geoIntersection' && params['geoIntersection']) {
        const wktArray = [];
        // if geointersection is an array of geojson (from filelayer) convert each one in WKT
        if (isArray(params['geoIntersection'])) {
          params['geoIntersection'].forEach(geojson => {
            wktArray.push(toWKT(geojson));
          });
          updatedParams['geoIntersection'] = wktArray;
        } else {
          updatedParams['geoIntersection'] = toWKT(params['geoIntersection']);
        }
      } else if (params[key]) {
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
      updatedParams['cd_ref'] = this.selectedtaxonFromComponent.map(taxon => taxon.cd_ref);
    }
    if (this.selectedCdRefFromTree.length > 0) {
      updatedParams['cd_ref_parent'] = this.selectedCdRefFromTree;
    }
    return updatedParams;
  }

  periodValidator(): ValidatorFn {
    return (formGroup: FormGroup): { [key: string]: boolean } => {
      const perioStart = formGroup.controls.period_start.value;
      const periodEnd = formGroup.controls.period_end.value;
      if ((perioStart && !periodEnd) || (!perioStart && periodEnd)) {
        return {
          invalidPeriod: true
        };
      }
      return null;
    };
  }
}
