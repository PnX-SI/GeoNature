import { Injectable } from '@angular/core';
import { UntypedFormGroup, UntypedFormBuilder, Validators } from '@angular/forms';
import { DataFormService } from '@geonature_common/form/data-form.service';

export interface Role {
  id_role?: string;
  nom_role?: string;
  prenom_role?: string;
  identifiant?: string;
  remarques?: string;
  pass_plus?: string;
  email?: string;
  id_organisme?: string;
  nom_complet?: string;
}

@Injectable()
export class RoleFormService {
  private roleForm: UntypedFormGroup;

  constructor(
    private fb: UntypedFormBuilder,
    private dataService: DataFormService
  ) {
    this.setForm();
  }

  getForm(role?: number): UntypedFormGroup {
    if (role !== null) {
      this.getRole(role);
    }
    return this.roleForm;
  }

  private setForm() {
    this.roleForm = this.fb.group({
      identifiant: ['', Validators.required],
      nom_role: ['', Validators.required],
      prenom_role: ['', Validators.required],
      email: [
        '',
        [Validators.pattern('^[a-z0-9._-]+@[a-z0-9._-]{2,}.[a-z]{2,4}$'), Validators.required],
      ],
      remarques: ['', null],
      champs_addi: this.fb.group({})
    });
    this.roleForm.disable();
  }

  private getRole(role: number) {
    this.dataService.getRole(role).subscribe((res) => {
      this.roleForm.patchValue(res);
    });
  }
}
