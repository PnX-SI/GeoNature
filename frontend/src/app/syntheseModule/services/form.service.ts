import { Injectable } from '@angular/core';
import { FormGroup, FormBuilder, FormControl } from '@angular/forms';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';

@Injectable()
export class FormService {
  public searchForm: FormGroup;
  public taxonsList: Array<Taxon>;

  constructor(private _fb: FormBuilder) {
    this.taxonsList = [];
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

  getCurrentTaxon($event) {
    this.taxonsList.push($event.item);
    $event.preventDefault();
    this.searchForm.controls.cd_nom.reset();
  }

  removeTaxon(index) {
    this.taxonsList.splice(index, 1);
  }
}
