import { Component, OnInit, AfterViewInit } from '@angular/core';
import { UntypedFormGroup, UntypedFormBuilder, Validators } from '@angular/forms';
import { AppConfig } from '@geonature_config/app.config';
import { AuthService } from '@geonature/components/auth/auth.service';
import { UserDataService } from './services/user-data.service';
import { DataFormService } from '@geonature_common/form/data-form.service';

@Component({
  selector: 'pnx-user',
  templateUrl: './user.component.html',
  styleUrls: ['./user.component.scss'],
})
export class UserComponent implements OnInit {
  form: FormGroup;
  // dynamicFormGroup: FormGroup;
  // public FORM_CONFIG = AppConfig.ACCOUNT_MANAGEMENT.ACCOUNT_FORM;

  constructor(
    private authService: AuthService,
    private roleFormService: RoleFormService,
    private userService: UserDataService
  ) { }

  ngOnInit() {
    //recupération des infos custom depuis la config de GN
    this.additionalFieldsForm = [...AppConfig.ACCOUNT_MANAGEMENT.ACCOUNT_FORM]
      .map(form_element => {
        //on desactive les elements customs
        form_element['disable'] = true;
        return form_element;
      });
    this.initForm();
    this.form.disable();
  }

  ngAfterViewInit() {
    //patch du formulaire à partir des infos de l'utilisateur connecté
    this.dataService.getRole(this.authService.getCurrentUser().id_role)
      .subscribe((user) => this.form.patchValue(user));
  }

  initForm() {
    this.form = this.getForm(this.authService.getCurrentUser().id_role);
    // this.dynamicFormGroup = this.fb.group({});
  }

  getForm(role: number): UntypedFormGroup {
    return this.roleFormService.getForm(role);
  }

  save() {
    if (this.form.valid) {
      // const finalForm = Object.assign({}, this.form.value);
      // // concatenate two forms
      // if (AppConfig.ACCOUNT_MANAGEMENT.ACCOUNT_FORM.length > 0) {
      //   finalForm['champs_addi'] = this.dynamicFormGroup.value;
      // }
      this.userService.putRole(this.form.value).subscribe((res) => this.form.disable());
    }
  }

  cancel() {
    this.initForm();
    this.form.disable();
  }

  enableForm() {
    this.form.enable();
  }
}
