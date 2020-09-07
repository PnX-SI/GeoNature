import { Injectable } from '@angular/core';
import { FormGroup, FormBuilder } from "@angular/forms";

@Injectable({ providedIn: 'root' })
export class OcctaxMapListService {
    public dynamicFormGroup: FormGroup;

    constructor(private _fb: FormBuilder) {
        this.dynamicFormGroup = this._fb.group({
            cd_nom: null,
            observers: null,
            dataset: null,
            observers_txt: null,
            id_dataset: null,
            date_up: null,
            date_low: null,
            municipality: null
        });
    }

}