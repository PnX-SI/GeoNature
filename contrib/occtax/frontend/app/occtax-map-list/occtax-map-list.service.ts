import { Injectable } from '@angular/core';
import { UntypedFormGroup, UntypedFormBuilder } from '@angular/forms';

@Injectable({ providedIn: 'root' })
export class OcctaxMapListService {
  public dynamicFormGroup: UntypedFormGroup;
  public rowPerPage: number;

  constructor(private _fb: UntypedFormBuilder) {
    this.dynamicFormGroup = this._fb.group({
      cd_nom: null,
      observers: null,
      dataset: null,
      observers_txt: null,
      id_dataset: null,
      date_up: null,
      date_low: null,
      municipality: null,
    });
  }

  nbOfFilter() {
    let result = 0;
    Object.keys(this.dynamicFormGroup.value).forEach((key) => {
      if (this.dynamicFormGroup.value[key]) {
        result = result + 1;
      }
    });
    return result;
  }
}
