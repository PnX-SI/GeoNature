import { Injectable } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';


@Injectable()
export class MetadataFormService {

  constructor(private _fb: FormBuilder) { }

  generateCorDatasetActorForm(): FormGroup {
    return this._fb.group({
      id_nomenclature_actor_role: [null, Validators.required],
      organisms: [new Array()],
      roles: [new Array()]
    });
  }
}
