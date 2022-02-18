import { Component, OnInit } from '@angular/core';
import { FormGroup, FormBuilder } from '@angular/forms';
import { AuthService } from '../auth/auth.service';
import { ToastrService } from 'ngx-toastr';
import { CommonService } from '@geonature_common/service/common.service';
import { ConfigService } from '../../services/config.service';

@Component({
  selector: 'pnx-login',
  templateUrl: 'login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent implements OnInit {
  public appConfig;
  enable_sign_up: boolean = false;
  enable_user_management: boolean = false;
  public casLogin: boolean;
  public disableSubmit = false;
  public enablePublicAccess: boolean;
  identifiant: FormGroup;
  password: FormGroup;
  form: FormGroup;
  login_or_pass_recovery: boolean = false;
  public APP_NAME:string;

  constructor(
    private _authService: AuthService,
    private fb: FormBuilder,
    private _toasterService: ToastrService,
    private _commonService: CommonService,
    public configService: ConfigService
  ) {
    this.appConfig = this.configService.config;

    this.casLogin = this.appConfig.CAS_PUBLIC.CAS_AUTHENTIFICATION;
    this.enable_sign_up = this.appConfig['ACCOUNT_MANAGEMENT']['ENABLE_SIGN_UP'] || false;
    this.enable_user_management =
      this.appConfig['ACCOUNT_MANAGEMENT']['ENABLE_USER_MANAGEMENT'] || false;
    this.enablePublicAccess = this.appConfig.PUBLIC_ACCESS.ENABLE_PUBLIC_ACCESS;
    this.APP_NAME = this.appConfig.appName;
  }

  ngOnInit() {
    if (this.appConfig.CAS_PUBLIC.CAS_AUTHENTIFICATION) {
      // if token not here here, redirection to CAS login page
      const url_redirection_cas = `${this.appConfig.CAS_PUBLIC.CAS_URL_LOGIN}?service=${
        this.appConfig.API_ENDPOINT
      }/gn_auth/login_cas`;
      document.location.href = url_redirection_cas;
    }
  }

  register(user) {
    this._authService.signinUser(user);
  }

  registerPublic() {
    const userPublic = {
      "username": this.appConfig.PUBLIC_ACCESS.PUBLIC_LOGIN,
      "password": this.appConfig.PUBLIC_ACCESS.PUBLIC_PASSWORD,
    }
    this._authService.signinUser(userPublic);
  }

  loginOrPwdRecovery(data) {
    this.disableSubmit = true;
    this._authService
      .loginOrPwdRecovery(data)
      .subscribe(
        res => {
          this._commonService.translateToaster('info', 'PasswordAndLoginRecovery');
        }
      )
      .add(() => {
        this.disableSubmit = false;
      });
  }
}
