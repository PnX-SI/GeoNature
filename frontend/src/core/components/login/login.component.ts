import { Component, OnInit } from '@angular/core';
import { AppConfig } from '../../../conf/app.config';
import { AuthService } from '../auth/auth.service';
import { Router } from '@angular/router';
import { Location } from '@angular/common';


@Component({
  selector: 'pnx-login',
  templateUrl: 'login.component.html'
})

export class LoginComponent implements OnInit {
  constructor(private _authService: AuthService, private _router: Router, private _location: Location) {

   }

    ngOnInit() {
      console.log('init login ');
      if (AppConfig.CAS.CAS_AUTHENTIFICATION) {
        const url_redirection_cas = `${AppConfig.CAS.CAS_LOGIN_URL}?service=${AppConfig.URL_APPLICATION}`;
         //document.location.href = url_redirection_cas;
        //  console.log('redirect');
        //  this._location.subscribe(val => {
        //   console.log(val);
        //   // recuperer le
        // });
        // document.location.href = 'http://localhost:4200/#/lalalalala';
      }

   }
  register(user) {
    this._authService.fakeSigninUser(user.username, user.password);
  }
  
  logUrl(requestDetail) {
    console.log(requestDetail);
  }
}