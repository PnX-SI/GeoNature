import { Injectable } from '@angular/core';
import { FormGroup, FormBuilder } from '@angular/forms';

@Injectable()
export class FormService {
  public searchForm: FormGroup;

  constructor(private _fb: FormBuilder) {
    this.searchForm = this._fb.group({
      cd_nom: null,
      observers: null,
      id_dataset: null,
      id_nomenclature_bio_condition: null,
      date_min: null,
      date_max: null,
      municipalities: null,
      geoIntersection: null
    });
  }
}
