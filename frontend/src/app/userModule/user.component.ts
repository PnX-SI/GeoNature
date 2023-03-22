import { Component, OnInit, AfterViewInit } from '@angular/core';
import { FormGroup, FormBuilder, Validators, ValidatorFn, AbstractControl } from '@angular/forms';
import { BehaviorSubject } from 'rxjs';
import { AppConfig } from '@geonature_config/app.config';
import { AuthService, User } from '@geonature/components/auth/auth.service';
// import { Role, RoleFormService } from './services/form.service';
// import { UserDataService } from './services/user-data.service';
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

@Component({
  selector: 'pnx-user',
  templateUrl: './user.component.html',
  styleUrls: ['./user.component.scss'],
})
export class UserComponent implements OnInit, AfterViewInit {

  private role: BehaviorSubject<Role> = new BehaviorSubject(null);
  private roleForm: FormGroup;

  form: FormGroup;
  public FORM_CONFIG = AppConfig.ACCOUNT_MANAGEMENT.ACCOUNT_FORM;

  constructor(
    private authService: AuthService,
    private fb: FormBuilder,
    // private roleFormService: RoleFormService,
    // private userService: UserDataService,
    private dataService: DataFormService
  ) {}

  ngOnInit() {
    this.initForm();

    this.form.disable();
  }

  ngAfterViewInit() {
    this.dataService.getRole(this.authService.getCurrentUser().id_role)
      .subscribe((user) => {
        this.form.patchValue(user)
        console.log(this.form.value)
      });      

  }
  console() {
console.log(this.form)
    this.form.disable();

  }
  initForm() {
    // this.form = this.getForm(this.authService.getCurrentUser().id_role);

    this.form = this.fb.group({
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
  }

  // getForm(role: number): FormGroup {
  //   return this.roleFormService.getForm(role);
  // }

  private getRole(role: number) {
    this.dataService.getRole(role).subscribe((res) => {
      this.roleForm.patchValue(res);
      
    });
  }

  save() {
    if (this.form.valid) {
      // const finalForm = Object.assign({}, this.form.value);
      // // concatenate two forms
      // if (AppConfig.ACCOUNT_MANAGEMENT.ACCOUNT_FORM.length > 0) {
      //   finalForm['champs_addi'] = this.dynamicFormGroup.value;
      // }
      // this.userService.putRole(this.form.value).subscribe((res) => this.form.disable());
    }
  }

  cancel() {
    // this.initForm();
    // this.form.disable();
  }

  enableForm() {
    // this.form.enable();
  }
}
