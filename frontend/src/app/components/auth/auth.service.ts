import { Router } from '@angular/router';
//import * as firebase from 'firebase';
import { Injectable } from '@angular/core';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { HttpClient } from '@angular/common/http';
import { AppConfig } from '../../../conf/app.config';
import { CookieService } from 'ng2-cookies';

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
  constructor(private router: Router, private _http: HttpClient, private _cookie: CookieService) {}

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
      id_application: AppConfig.ID_APPLICATION_GEONATURE
    };
    this._http
      .post<any>(`${AppConfig.API_ENDPOINT}/auth/login`, user)
      .finally(() => (this.isLoading = false))
      .subscribe(
        data => {
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
        // error callback
        () => {
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

  deleteAllCookies() {
    document.cookie.split(';').forEach(c => {
      document.cookie = c
        .replace(/^ +/, '')
        .replace(/=.*/, '=;expires=' + new Date().toUTCString() + ';path=/');
    });
  }

  logout() {
    this.deleteAllCookies();
    if (AppConfig.CAS_PUBLIC.CAS_AUTHENTIFICATION) {
      document.location.href = AppConfig.CAS_PUBLIC.CAS_URL_LOGOUT;
    } else {
      this.router.navigate(['/login']);
      // call the logout route to delete the session
      // TODO: in case of different cruved user in DEPOBIO context must run this routes
      // but actually make bug the INPN CAS deconnexion
      this._http.get<any>(`${AppConfig.API_ENDPOINT}/gn_auth/logout_cruved`).subscribe(() => {});
      // refresh the page to refresh all the shared service to avoid cruved conflict
      location.reload();
    }
  }

  isAuthenticated(): boolean {
    return this._cookie.get('token') !== null;
  }
}
