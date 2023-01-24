import { Component, OnInit } from '@angular/core';
import { UntypedFormGroup, UntypedFormBuilder } from '@angular/forms';

import { ToastrService } from 'ngx-toastr';
import { CommonService } from '@geonature_common/service/common.service';

import { AppConfig } from '../../../../conf/app.config';
import { AuthService } from '../../../components/auth/auth.service';

@Component({
  selector: 'pnx-login',
  templateUrl: 'login.component.html',
  styleUrls: ['./login.component.scss'],
})
export class LoginComponent implements OnInit {
  enable_sign_up: boolean = false;
  enable_user_management: boolean = false;
  public casLogin: boolean;
  public disableSubmit = false;
  public enablePublicAccess = AppConfig.PUBLIC_ACCESS_USERNAME;
  identifiant: UntypedFormGroup;
  password: UntypedFormGroup;
  form: UntypedFormGroup;
  login_or_pass_recovery: boolean = false;
  public APP_NAME = AppConfig.appName;

  constructor(
    private _authService: AuthService,
    private fb: UntypedFormBuilder,
    private _toasterService: ToastrService,
    private _commonService: CommonService
  ) {
    this.casLogin = AppConfig.CAS_PUBLIC.CAS_AUTHENTIFICATION;
    this.enable_sign_up = AppConfig['ACCOUNT_MANAGEMENT']['ENABLE_SIGN_UP'] || false;
    this.enable_user_management =
      AppConfig['ACCOUNT_MANAGEMENT']['ENABLE_USER_MANAGEMENT'] || false;
  }

  ngOnInit() {
    if (AppConfig.CAS_PUBLIC.CAS_AUTHENTIFICATION) {
      // if token not here here, redirection to CAS login page
      const url_redirection_cas = `${AppConfig.CAS_PUBLIC.CAS_URL_LOGIN}?service=${AppConfig.API_ENDPOINT}/gn_auth/login_cas`;
      document.location.href = url_redirection_cas;
    }
  }

  register(user) {
    this._authService.signinUser(user);
  }

  registerPublic() {
    this._authService.signinPublicUser();
  }

  loginOrPwdRecovery(data) {
    this.disableSubmit = true;
    this._authService
      .loginOrPwdRecovery(data)
      .subscribe((res) => {
        this._commonService.translateToaster('info', 'PasswordAndLoginRecovery');
      })
      .add(() => {
        this.disableSubmit = false;
      });
  }
}
