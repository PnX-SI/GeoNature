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
export class UserComponent implements OnInit, AfterViewInit {

  private roleForm: UntypedFormGroup;

  form: UntypedFormGroup;
  additionalFieldsForm: Array<any>;

  constructor(
    private authService: AuthService,
    private fb: UntypedFormBuilder,
    private userService: UserDataService,
    private dataService: DataFormService
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

  save() {
    if (this.form.valid) {
      this.userService.putRole(this.form.value)
        .subscribe((res) => this.form.disable());
    }
  }

  cancel() {
    this.initForm();
    this.form.disable();
  }

  enableForm() {
    this.form.enable();
  }

  enableForm() {
    this.form.enable();
  }
}
