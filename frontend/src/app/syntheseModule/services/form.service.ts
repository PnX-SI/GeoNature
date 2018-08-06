import { Injectable } from '@angular/core';
import { FormGroup, FormBuilder, FormControl, FormArray } from '@angular/forms';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { AppConfig } from '@geonature_config/app.config';
import { stringify } from 'wellknown';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap/datepicker/ngb-date-parser-formatter';

@Injectable()
export class SyntheseFormService {
  public searchForm: FormGroup;
  public taxonsList: Array<Taxon>;
  public formBuilded = false;

  constructor(private _fb: FormBuilder, private _dateParser: NgbDateParserFormatter) {
    this.taxonsList = [];
    const areasFormArray = this._fb.array([]);

    this.searchForm = this._fb.group({
      cd_nom: null,
      observers: null,
      id_dataset: null,
      id_acquisition_frameworks: null,
      date_min: null,
      date_max: null,
      municipalities: null,
      geoIntersection: null,
      radius: null
    });

    AppConfig.SYNTHESE.AREA_FILTERS.forEach(area => {
      const control_name = 'area_' + area.id_type;
      const new_area_control = new FormControl();
      this.searchForm.addControl(control_name, new FormControl());
      const control = this.searchForm.controls[control_name];
      area['control'] = control;
      // const t = new FormArray([]);
      // (this.searchForm.controls.areas as FormArray).push(new_area_control);
    });

    console.log(this.searchForm);

    this.formBuilded = true;
  }

  getCurrentTaxon($event) {
    this.taxonsList.push($event.item);
    $event.preventDefault();
    this.searchForm.controls.cd_nom.reset();
  }

  removeTaxon(index) {
    this.taxonsList.splice(index, 1);
  }

  formatParams() {
    const params = Object.assign({}, this.searchForm.value);
    const updatedParams = {};
    // tslint:disable-next-line:forin
    for (let key in params) {
      // if cd_nom
      if (key === 'cd_nom' && params.cd_nom && params.cd_nom.length > 0) {
        updatedParams['cd_nom'] = [];
        params.cd_nom.forEach(el => {
          params.cd_nom = params.cd_nom.cd_nom;
          updatedParams['cd_nom'].push(el.cd_nom);
        });
      } else if (
        (key === 'date_min' && params.date_min) ||
        (key === 'date_max' && params.date_max)
      ) {
        console.log(key);
        console.log(params[key]);
        updatedParams[key] = this._dateParser.format(params[key]);
      } else if (params['geoIntersection']) {
        updatedParams['geoIntersection'] = stringify(params['geoIntersection']);
        // if other key an value not null or undefined
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
    console.log('le updated', updatedParams);
    return updatedParams;
  }
}
