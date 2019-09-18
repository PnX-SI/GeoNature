import { Component, OnInit } from '@angular/core';
import { FormGroup, FormBuilder, Validators, FormControl } from '@angular/forms';
import { Router } from '@angular/router';
import { AppConfig } from '@geonature_config/app.config';
import { ToastrService } from 'ngx-toastr';
import { AuthService } from '../auth/auth.service';
import { similarValidator } from '@geonature/services/validators/validators';
import { CommonService } from '@geonature_common/service/common.service';

@Component({
  selector: 'pnx-signup',
  templateUrl: './sign-up.component.html',
  styleUrls: ['./sign-up.component.scss']
})
export class SignUpComponent implements OnInit {
  form: FormGroup;
  dynamicFormGroup: FormGroup;
  public disableSubmit = false;
  public formControlBuilded = false;
  public FORM_CONFIG = AppConfig.ACCOUNT_MANAGEMENT.ACCOUNT_FORM;

  constructor(
    private fb: FormBuilder,
    private _authService: AuthService,
    private _router: Router,
    private _toasterService: ToastrService,
    private _commonService: CommonService
  ) {
    if (!(AppConfig['ACCOUNT_MANAGEMENT']['ENABLE_SIGN_UP'] || false)) {
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
        [Validators.pattern('^[a-z0-9._-]+@[a-z0-9._-]{2,}.[a-z]{2,4}$'), Validators.required]
      ],
      password: ['', [Validators.required]],
      password_confirmation: ['', [Validators.required]],
      remarques: ['', null],
      organisme: ['', null]
    });
    this.form.setValidators([similarValidator('password', 'password_confirmation')]);
    this.dynamicFormGroup = this.fb.group({});
  }

  save() {
    if (this.form.valid) {
      this.disableSubmit = true;
      const finalForm = Object.assign({}, this.form.value);
      // concatenate two forms
      if (AppConfig.ACCOUNT_MANAGEMENT.ACCOUNT_FORM.length > 0) {
        finalForm['champs_addi'] = this.dynamicFormGroup.value;
      }
      this._authService
        .signupUser(finalForm)
        .subscribe(
          res => {
            const callbackMessage = AppConfig.ACCOUNT_MANAGEMENT.AUTO_ACCOUNT_CREATION
              ? 'AutoAccountEmailConfirmation'
              : 'AdminAccountEmailConfirmation';
            this._commonService.translateToaster('info', callbackMessage);
            this._router.navigate(['/login']);
          },
          // error callback
          error => {
            this._toasterService.error(error.error.msg, '', {
              positionClass: 'toast-top-center',
              tapToDismiss: true,
              timeOut: 5000
            });
          }
        )
        .add(() => {
          this.disableSubmit = false;
        });
    }
  }
}
