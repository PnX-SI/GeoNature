import { Component, OnInit } from '@angular/core';
import { FormGroup } from '@angular/forms';

import { CommonService } from '@geonature_common/service/common.service';

import { AuthService } from '../../../components/auth/auth.service';
import { ConfigService } from '@geonature/services/config.service';

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
  public enablePublicAccess = null;
  identifiant: FormGroup;
  password: FormGroup;
  form: FormGroup;
  login_or_pass_recovery: boolean = false;
  public APP_NAME = null;

  constructor(
    private _authService: AuthService,
    private _commonService: CommonService,
    public config: ConfigService
  ) {
    this.enablePublicAccess = this.config.PUBLIC_ACCESS_USERNAME;
    this.APP_NAME = this.config.appName;
    this.casLogin = this.config.CAS_PUBLIC.CAS_AUTHENTIFICATION;
    this.enable_sign_up = this.config['ACCOUNT_MANAGEMENT']['ENABLE_SIGN_UP'] || false;
    this.enable_user_management =
      this.config['ACCOUNT_MANAGEMENT']['ENABLE_USER_MANAGEMENT'] || false;
  }

  ngOnInit() {
    if (this.config.CAS_PUBLIC.CAS_AUTHENTIFICATION) {
      // if token not here here, redirection to CAS login page
      const url_redirection_cas = `${this.config.CAS_PUBLIC.CAS_URL_LOGIN}?service=${this.config.API_ENDPOINT}/gn_auth/login_cas`;
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
      .subscribe(() => {
        this._commonService.translateToaster('info', 'PasswordAndLoginRecovery');
      })
      .add(() => {
        this.disableSubmit = false;
      });
  }
}
