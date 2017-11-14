import { Component, OnInit } from '@angular/core';
import { AppConfig } from '../../../conf/app.config';
import { AuthService } from '../auth/auth.service';
import { Router } from '@angular/router';
import { Location } from '@angular/common';
import { HttpClient, HttpParams } from '@angular/common/http';



@Component({
  selector: 'pnx-login',
  templateUrl: 'login.component.html'
})

export class LoginComponent implements OnInit {
  isLoged = false;
  constructor(private _authService: AuthService, private _router: Router, private _location: Location,
  private _http: HttpClient) {

   }

    ngOnInit() {
       if (AppConfig.CAS.CAS_AUTHENTIFICATION) {
         const url_redirection_cas = `${AppConfig.CAS.CAS_LOGIN_URL}?service=${AppConfig.API_ENDPOINT}test_auth/login_cas`;
        // const url_redirection_cas = `${AppConfig.CAS.CAS_LOGIN_URL}?service=http://localhost:4200`;
         document.location.href = url_redirection_cas;

         const d1 = new Date();
         const d2 = new Date(d1);
         d2.setMinutes(d1.getMinutes() + 60);
         this._authService.setToken('zrqgoviedfohvfd', d2);

         // document.location.href = 'http://localhost:4200/#/lalalalala';
      this._authService.fakeSigninUser('admin', 'test');
       }

   }
  register(user) {
    this._authService.fakeSigninUser(user.username, user.password);

  }
}


