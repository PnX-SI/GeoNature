import { Router } from '@angular/router';
//import * as firebase from 'firebase';
import { Injectable } from '@angular/core';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { HttpClient } from '@angular/common/http';
import { AppConfig } from '../../../conf/app.config';
import { CookieService } from 'ng2-cookies';
import { Idle, DEFAULT_INTERRUPTSOURCES } from '@ng-idle/core';

export interface User {
  user_login: string;
  id_role: string;
  id_organisme: string;
  prenom_role?: string;
  nom_role?: string;
  nom_complet?: string;
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
    private _http: HttpClient,
    private _cookie: CookieService,
    private _idle: Idle
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
          console.log(data.user);
          const userForFront = {
            user_login: data.user.identifiant,
            prenom_role: data.user.prenom_role,
            id_role: data.user.id_role,
            nom_role: data.user.nom_role,
            nom_complet: data.user.nom_role + ' ' + data.user.prenom_role,
            id_organisme: data.user.id_organisme
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
    if (AppConfig.CAS_PUBLIC.CAS_AUTHENTIFICATION) {
      this.deleteTokenCookie();
      document.location.href = AppConfig.CAS_PUBLIC.CAS_URL_LOGOUT;
    } else {
      this.router.navigate(['/login']);
    }
    // call the logout route to delete the session
    this._http.get<any>(`${AppConfig.API_ENDPOINT}/auth/logout_cruved`).subscribe(() => {});
  }

  isAuthenticated(): boolean {
    return this._cookie.get('token') !== null;
  }

  activateIdle() {
    this._idle.setIdle(1);
    this._idle.setTimeout(AppConfig.INACTIVITY_PERIOD_DISCONECT);
    this._idle.setInterrupts(DEFAULT_INTERRUPTSOURCES);

    this._idle.onTimeout.subscribe(() => {
      this.logout();
    });

    this.resetIdle();
  }

  resetIdle() {
    this._idle.watch();
  }
}
