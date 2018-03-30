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
  public isLoading = false;
  constructor(
    private router: Router,
    private toastrService: ToastrService,
    private _http: HttpClient,
    private _cookie: CookieService,
    private _router: Router
  ) {}

  setCurrentUser(user) {
    localStorage.setItem('current_user', JSON.stringify(user));
  }

  getCurrentUser() {
    let currentUser = localStorage.getItem('current_user');
    if (!currentUser) {
      const userCookie = this._cookie.get('current_user');
      if (userCookie !== '') {
        let decodedCookie = this.decodeObjectCookies(userCookie);
        decodedCookie = decodedCookie.split("'").join('"');
        this.setCurrentUser(decodedCookie);
        currentUser = localStorage.getItem('current_user');
      }
    }
    return JSON.parse(currentUser);
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
    this.isLoading = true;
    const user = {
      login: username,
      password: password,
      id_application: AppConfig.ID_APPLICATION_GEONATURE,
      with_cruved: true
    };
    this._http
      .post<any>(`${AppConfig.API_ENDPOINT}/auth/login`, user)
      .finally(() => (this.isLoading = false))
      .subscribe(
        data => {
          const userForFront = {
            userName: data.user.identifiant,
            userId: data.user.id_role,
            organismId: data.user.id_organisme
          };
          this.setCurrentUser(userForFront);
          this.loginError = false;
          this.router.navigate(['']);
        },
        error => {
          this.loginError = true;
        }
      );
  }

  decodeObjectCookies(val) {
    if (val.indexOf('\\') === -1) {
      return val; // not encoded
    }
    val = val.slice(1, -1).replace(/\\"/g, '"');
    val = val.replace(/\\(\d{3})/g, function(match, octal) {
      return String.fromCharCode(parseInt(octal, 8));
    });
    return val.replace(/\\\\/g, '\\');
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
