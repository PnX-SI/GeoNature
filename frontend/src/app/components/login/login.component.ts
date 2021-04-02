import { Component, OnInit } from '@angular/core';
import { FormGroup, FormBuilder } from '@angular/forms';
import { ConfigService } from '@geonature/utils/configModule/core';
import { AuthService } from '../auth/auth.service';
import { ToastrService } from 'ngx-toastr';
import { CommonService } from '@geonature_common/service/common.service';

@Component({
  selector: 'pnx-login',
  templateUrl: 'login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent implements OnInit {
  enable_sign_up: boolean = false;
  enable_user_management: boolean = false;
  public casLogin: boolean;
  public disableSubmit = false;
  public appConfig: any;

  identifiant: FormGroup;
  password: FormGroup;
  form: FormGroup;
  login_or_pass_recovery: boolean = false;

  constructor(
    private _authService: AuthService,
    private fb: FormBuilder,
    private _toasterService: ToastrService,
    private _commonService: CommonService,
    private _configService: ConfigService,
  ) {
    this.appConfig = this._configService.getSettings();
    this.casLogin = this.appConfig.CAS_PUBLIC.CAS_AUTHENTIFICATION;
    this.enable_sign_up = this.appConfig['ACCOUNT_MANAGEMENT']['ENABLE_SIGN_UP'] || false;
    this.enable_user_management =
      this.appConfig['ACCOUNT_MANAGEMENT']['ENABLE_USER_MANAGEMENT'] || false;
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

  loginOrPwdRecovery(data) {
    this.disableSubmit = true;
    this._authService
      .loginOrPwdRecovery(data)
      .subscribe(
        res => {
          this._commonService.translateToaster('info', 'PasswordAndLoginRecovery');
        },
        error => {
          this._toasterService.error(error.error.msg, '');
        }
      )
      .add(() => {
        this.disableSubmit = false;
      });
  }
}
