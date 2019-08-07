import { Injectable } from '@angular/core';
import { FormGroup, FormBuilder, Validators, ValidatorFn, AbstractControl } from '@angular/forms';
import { BehaviorSubject } from 'rxjs';
import { AppConfig } from '@geonature_config/app.config';
import { DataFormService } from "@geonature_common/form/data-form.service";

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
  private role: BehaviorSubject<Role> = new BehaviorSubject(null);
  private roleForm: FormGroup;

  constructor(private fb: FormBuilder, private dataService: DataFormService) {
    this.setForm();
  }

  getForm(role?: number): FormGroup {
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
      email: ['', [Validators.pattern('^[a-z0-9._-]+@[a-z0-9._-]{2,}\.[a-z]{2,4}$'), Validators.required]],
      remarques: ['', null]
    });
    this.roleForm.disable();
  }

  private getRole(role: number) {
    this.dataService.getRole(role).subscribe(res => {this.roleForm.patchValue(res)});
  }
}