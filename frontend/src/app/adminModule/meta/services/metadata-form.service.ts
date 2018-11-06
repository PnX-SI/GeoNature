import { Injectable } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { ToastrService } from 'ngx-toastr';


@Injectable()
export class MetadataFormService {
  public formValid = true;

  constructor(private _fb: FormBuilder, private _toaster: ToastrService) { }

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
  checkFormValidity(element) {
    if (element.id_role == null && element.id_organism == null) {
      this.formValid = false;
      this._toaster.error(
        'Veuillez spécifier un organisme ou une personne pour chaque acteur du JDD',
        '',
        { positionClass: 'toast-top-center' }
      );
    }
  }

}
