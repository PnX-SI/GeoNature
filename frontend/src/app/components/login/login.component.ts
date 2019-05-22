import { Component, OnInit } from '@angular/core';
import { FormGroup, FormBuilder, Validators, ValidatorFn, AbstractControl } from '@angular/forms';
import { AppConfig } from '../../../conf/app.config';
import { AuthService } from '../auth/auth.service';
import { Router } from '@angular/router';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { Location } from '@angular/common';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'pnx-login',
  templateUrl: 'login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent implements OnInit {
  enable_sign_up: boolean = false;
  public casLogin: boolean;

  identifiant: FormGroup;
  password: FormGroup;
  form: FormGroup;
  password_recovery: boolean = false;
  login_recovery: boolean = false;
  identifiantLoading: boolean = false;

  constructor(
    private _authService: AuthService,
    private fb: FormBuilder,
    private _toasterService: ToastrService
  ) {
    this.casLogin = AppConfig.CAS_PUBLIC.CAS_AUTHENTIFICATION;
    this.enable_sign_up = AppConfig['ENABLE_SIGN_UP'] || false;
  }

  ngOnInit() {
    if (AppConfig.CAS_PUBLIC.CAS_AUTHENTIFICATION) {
      // if token not here here, redirection to CAS login page
      const url_redirection_cas = `${AppConfig.CAS_PUBLIC.CAS_URL_LOGIN}?service=${
        AppConfig.API_ENDPOINT
      }/gn_auth/login_cas`;
      document.location.href = url_redirection_cas;
    } else {
      this.setForm();
    }
  }

  register() {
    if (this.identifiant.valid && this.password.valid) {
      const user = Object.assign(this.identifiant.value, this.password.value);
      this._authService.signinUser(user);
    }
  }

  setForm() {
    this.identifiant = this.fb.group({
      identifiant: ['', [Validators.required], this.identifiantNotExist.bind(this)]
    });
    this.password = this.fb.group({
      password: ['', Validators.required]
    });
  }

  loginRecovery(data) {
    this._authService.loginRecovery(data)
          .subscribe(
            res => {
              this._toasterService.info(
                    res.msg,
                    '',
                    {
                      positionClass: 'toast-top-center',
                      tapToDismiss: true,
                      timeOut: 10000
                    }
                  );
            },
            error => {
              this._toasterService.error(
                error.error.msg,
                '',
                {
                  positionClass: 'toast-top-center',
                  tapToDismiss: true,
                  timeOut: 5000
                }
              );
            }
          );
  }

  pwd_recovery() {
    if (this.identifiant.valid) {
      this._authService.passwordRecovery(this.identifiant.value)
          .subscribe(
            res => {
              this._toasterService.info(
                    res.msg,
                    '',
                    {
                      positionClass: 'toast-top-center',
                      tapToDismiss: true,
                      timeOut: 10000
                    }
                  );
            },
            error => {
              this._toasterService.error(
                error.error.msg,
                '',
                {
                  positionClass: 'toast-top-center',
                  tapToDismiss: true,
                  timeOut: 5000
                }
              );
            }
          );
    }
  }

  /**
  * Validateur qui retourne true/false selon qu'un login existe ou non en BD
  **/
  identifiantNotExist(control: AbstractControl) {
    return control
            .valueChanges
            .delay(500)
            .debounceTime(500)
            .distinctUntilChanged()
            .switchMap(value => {
              this.identifiantLoading = true;
              return this._authService.checkUserExist(control.value);})
            .map(res => {
              this.identifiantLoading = false;
              if (res.login_exist === true) {
                return control.setErrors(null);
              } else {
                return control.setErrors({ loginNotExist: 'Identifiant inconnu' })
              }
            })
    };
}
