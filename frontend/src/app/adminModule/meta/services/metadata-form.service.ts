import { Injectable } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';


@Injectable()
export class MetadataFormService {

  constructor(private _fb: FormBuilder) { }

  generateCorDatasetActorForm(): FormGroup {
    return this._fb.group({
      id_cda: null,
      id_nomenclature_actor_role: [null, Validators.required],
      id_organism: null,
      id_role: null
    });
  }

  generateCorAfActorForm(): FormGroup {
    return this._fb.group({
      id_cafa: null,
      id_nomenclature_actor_role: [null, Validators.required],
      id_organism: null,
      id_role: null
    });
  }
}
