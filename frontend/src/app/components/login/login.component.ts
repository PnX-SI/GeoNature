import { Component, OnInit } from '@angular/core';
import { AppConfig } from '../../../conf/app.config';
import { AuthService } from '../auth/auth.service';
import { Router } from '@angular/router';
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
  constructor(private _authService: AuthService) {
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
    }
  }
  register(user) {
    this._authService.signinUser(user.username, user.password);
  }
}
