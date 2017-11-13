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
  constructor(private _authService: AuthService, private _router: Router, private _location: Location,
  private _http: HttpClient) {

   }

    ngOnInit() {
      // if (AppConfig.CAS.CAS_AUTHENTIFICATION) {
      //   const url_redirection_cas = `${AppConfig.CAS.CAS_LOGIN_URL}?service=${AppConfig.URL_APPLICATION}`;
      //   document.location.href = url_redirection_cas;
      //    console.log('redirect');
      //    this._location.subscribe(val => {
      //     console.log("url changeeeeeee");


      //     this._authService.authentified = true;
      //     // recuperer le ticket et le faire le GET login
      //   });
      //   const d1 = new Date();
      //   const d2 = new Date(d1);
      //   d2.setMinutes(d1.getMinutes() + 60);
      //   this._authService.setToken('zrqgoviedfohvfd', d2);

      //   // document.location.href = 'http://localhost:4200/#/lalalalala';
      // }


   }
  register(user) {
    console.log(user);
    
    // this._authService.fakeSigninUser(user.username, user.password);
    this._http.post('https://preprod-inpn.mnhn.fr/auth/login', user)
    .subscribe(resp => {
      console.log(resp);
    });
  }
  
  logUrl(requestDetail) {
    console.log(requestDetail);
  }
}