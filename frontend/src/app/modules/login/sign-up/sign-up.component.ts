import { Component, OnInit } from '@angular/core';
import { UntypedFormGroup, UntypedFormBuilder, Validators } from '@angular/forms';
import { Router } from '@angular/router';

import { similarValidator } from '@geonature/services/validators/validators';
import { CommonService } from '@geonature_common/service/common.service';

import { AuthService } from '../../../components/auth/auth.service';
import { ConfigService } from '@geonature/services/config.service';
@Component({
  selector: 'pnx-signup',
  templateUrl: './sign-up.component.html',
  styleUrls: ['./sign-up.component.scss'],
})
export class SignUpComponent implements OnInit {
  form: UntypedFormGroup;
  dynamicFormGroup: UntypedFormGroup;
  public disableSubmit = false;
  public formControlBuilded = false;
  public FORM_CONFIG = null;
  public errorMsg = '';

  constructor(
    private fb: UntypedFormBuilder,
    private _authService: AuthService,
    private _router: Router,
    private _commonService: CommonService,
    public config: ConfigService
  ) {
    this.FORM_CONFIG = this.config.ACCOUNT_MANAGEMENT.ACCOUNT_FORM;
    if (!(this.config['ACCOUNT_MANAGEMENT']['ENABLE_SIGN_UP'] || false)) {
      this._router.navigate(['/login']);
    }
  }

  ngOnInit() {
    this.createForm();
  }

  createForm() {
    this.form = this.fb.group({
      nom_role: ['', Validators.required],
      prenom_role: ['', Validators.required],
      identifiant: ['', Validators.required],
      email: [
        '',
        [Validators.pattern('^[+a-z0-9._-]+@[a-z0-9._-]{2,}.[a-z]{2,4}$'), Validators.required],
      ],
      password: ['', [Validators.required]],
      password_confirmation: ['', [Validators.required]],
      remarques: ['', null],
      organisme: ['', null],
    });
    this.form.setValidators([similarValidator('password', 'password_confirmation')]);
    this.dynamicFormGroup = this.fb.group({});
  }

  save() {
    if (this.form.valid) {
      this.errorMsg = ''; // raz de l'erreur
      this.disableSubmit = true;
      const finalForm = Object.assign({}, this.form.value);
      // concatenate two forms
      finalForm['champs_addi'] = {};
      if (this.config.ACCOUNT_MANAGEMENT.ACCOUNT_FORM.length > 0) {
        finalForm['champs_addi'] = this.dynamicFormGroup.value;
      }
      // ajout de organisme aux champs addi
      finalForm['champs_addi']['organisme'] = this.form.value['organisme'];
      this._authService
        .signupUser(finalForm)
        .subscribe(
          () => {
            const callbackMessage = this.config.ACCOUNT_MANAGEMENT.AUTO_ACCOUNT_CREATION
              ? 'AutoAccountEmailConfirmation'
              : 'AdminAccountEmailConfirmation';
            this._commonService.translateToaster('info', callbackMessage);
            this._router.navigate(['/login']);
          },
          (error) => {
            // affichage de l'erreur renvoyé par l'api
            if (error.error.msg) {
              this.errorMsg = error.error.msg;
            }
          }
        )
        .add(() => {
          this.disableSubmit = false;
        });
    }
  }
}
