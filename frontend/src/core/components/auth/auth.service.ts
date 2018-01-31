import { Router } from '@angular/router';
//import * as firebase from 'firebase';
import { Injectable } from '@angular/core';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { HttpClient } from '@angular/common/http';
import { AppConfig } from '../../../conf/app.config';
import { CookieService } from 'ng2-cookies';
import { Location } from '@angular/common';


export class User {

  constructor(public userName: string, public userId: number, public organismId: number) {
    this.userName = userName;
    this.userId = userId;
    this.organismId = organismId;
  }

}

@Injectable()
export class AuthService {
    authentified = false;
    currentUser: any;
    token: string;
    toastrConfig: ToastrConfig;
    loginError: boolean;
    constructor(private router: Router,  private toastrService: ToastrService, private _http: HttpClient,
    private _cookie: CookieService, private _router: Router) {
    }

  setCurrentUser(user, expireDate) {
    sessionStorage.setItem('current_user', JSON.stringify(user));
  }

  getCurrentUser(): any {
    const currentUser = JSON.parse(sessionStorage.getItem('current_user'));
    return currentUser;
  }

  setToken(token, expireDate) {
    this._cookie.set('token', token, expireDate);
  }

  getToken() {
    const token = this._cookie.get('token');
    const response = token.length === 0 ? null : token;
    return response;
  }



  signinUser(username: string, password: string) {
    const user = {
    'login': username,
    'password': password,
    'id_application': AppConfig.ID_APPLICATION_GEONATURE,
    'with_cruved': true
    };
    this._http.post<any>(`${AppConfig.API_ENDPOINT}/auth/login`, user)
      .subscribe(data => {
      const userForFront = {
        userName : data.user.identifiant,
        userId : data.user.id_role,
        organismId:  data.user.id_organisme,
      };
      this.setCurrentUser(userForFront, new Date(data.expires));
      this.loginError = false;
      this.router.navigate(['']);
    },
    error => {
      this.loginError = true;
    });

  }

deleteTokenCookie() {
  document.cookie = 'token=; path=/; expires' + new Date(0).toUTCString();
}

logout() {
    this._cookie.delete('token', '/');
    if (AppConfig.CAS.CAS_AUTHENTIFICATION) {
      this.deleteTokenCookie();
      document.location.href = AppConfig.CAS.CAS_URL_LOGOUT;
    } else {
      this.router.navigate(['/login']);
    }
  }

  isAuthenticated(): boolean {
      return this._cookie.get('token') !== null;
  }

}
