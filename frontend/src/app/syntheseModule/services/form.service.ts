import { Injectable } from '@angular/core';
import { FormGroup, FormBuilder, FormControl } from '@angular/forms';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { AppConfig } from '@geonature_config/app.config';

@Injectable()
export class FormService {
  public searchForm: FormGroup;
  public taxonsList: Array<Taxon>;
  public formBuilded = false;

  constructor(private _fb: FormBuilder) {
    this.taxonsList = [];
    const areasFormArray = this._fb.array([]);

    this.searchForm = this._fb.group({
      cd_nom: null,
      observers: null,
      id_dataset: null,
      id_acquisition_frameworks: null,
      id_nomenclature_bio_condition: null,
      date_min: null,
      date_max: null,
      municipalities: null,
      areas: this._fb.array([]),
      geoIntersection: null
    });

    AppConfig.SYNTHESE.AREA_FILTERS.forEach(area => {
      const control_name = 'area_' + area.id_type;
      this.searchForm.addControl(control_name, new FormControl());
      const control = this.searchForm.controls[control_name];
      area['control'] = control;
    });

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
}
