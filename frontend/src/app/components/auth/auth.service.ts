import { Router, ActivatedRoute } from '@angular/router';
import { Observable } from 'rxjs';
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

import { CookieService } from 'ng2-cookies';
import 'rxjs/add/operator/delay';
import { forkJoin } from "rxjs/observable/forkJoin";

import { AppConfig } from '../../../conf/app.config';
import { CruvedStoreService } from '@geonature_common/service/cruved-store.service';
import { ModuleService } from '../../services/module.service';


export interface User {
  user_login: string;
  id_role: string;
  id_organisme: number;
  prenom_role?: string;
  nom_role?: string;
  nom_complet?: string;
}

@Injectable()
export class AuthService {
  authentified = false;
  currentUser: any;
  token: string;
  loginError: boolean;
  public isLoading = false;
  constructor(
    private router: Router,
    private route: ActivatedRoute,
    private _http: HttpClient,
    private _cookie: CookieService,
    private cruvedService: CruvedStoreService,
    private moduleService: ModuleService,
  ) { }

  setCurrentUser(user) {
    localStorage.setItem('current_user', JSON.stringify(user));
  }

  getCurrentUser() {
    let currentUser = localStorage.getItem('current_user');
    if (!currentUser) {
      const userCookie = this._cookie.get('current_user');
      if (userCookie !== '') {
        this.setCurrentUser(this.decodeObjectCookies(userCookie));
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

  checkUserExist(username: string): Observable<any> {
    const options = {
      identifiant: username,
      id_application: AppConfig.ID_APPLICATION_GEONATURE
    };
    return this._http.post<any>(`${AppConfig.API_ENDPOINT}/auth/login/check`, options);
  }

  loginOrPwdRecovery(data: any): Observable<any> {
    return this._http.post<any>(`${AppConfig.API_ENDPOINT}/users/login/recovery`, data);
  }

  passwordChange(data: any): Observable<any> {
    return this._http.put<any>(`${AppConfig.API_ENDPOINT}/users/password/new`, data);
  }

  signinUser(user: any) {
    this.isLoading = true;

    const options = {
      login: user.username,
      password: user.password,
      id_application: AppConfig.ID_APPLICATION_GEONATURE
    };
    this._http
      .post<any>(`${AppConfig.API_ENDPOINT}/auth/login`, options)
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
          // Now that we are logged, we fetch the cruved again, and redirect once received
          forkJoin({
              modules: this.moduleService.fetchModules(),
          }).subscribe(() => {
            this.isLoading = false;
            let next = this.route.snapshot.queryParams['next'];
            let route = this.route.snapshot.queryParams['route'];
            // next means redirect to url
            // route means navigate to angular route
            if (next) {
                if (route) {
                    window.location.href = next + '#' + route;
                } else {
                    window.location.href = next;
                }
            } else if (route) {
                this.router.navigateByUrl(route);
            } else {
                this.router.navigate(['']);
            }
          });
        },
        // error callback
        () => {
          this.isLoading = false;
          this.loginError = true;
        }
      );
  }

  signupUser(data: any): Observable<any> {
    const options = data;
    return this._http.post<any>(`${AppConfig.API_ENDPOINT}/users/inscription`, options);
  }

  decodeObjectCookies(val) {
    try {

      val = val.replace(/\\(\d{3})/g, function (match, octal) {
        return String.fromCharCode(parseInt(octal, 8));
      });
      val = val.replaceAll('"', '');
      val = val.replaceAll("'", '"');
      val = val.replace(/\\\\/g, '\\');
      return JSON.parse(val);
    } catch (error) {
      console.error('error parsing user cookie');
      return '';
    }
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
    this.cleanLocalStorage();
    this.cruvedService.clearCruved();

    if (AppConfig.CAS_PUBLIC.CAS_AUTHENTIFICATION) {
      document.location.href = `${AppConfig.CAS_PUBLIC.CAS_URL_LOGOUT}?service=${
        AppConfig.URL_APPLICATION
        }`;
    } else {
      this.router.navigate(['/login']);
      // call the logout route to delete the session
      // TODO: in case of different cruved user in DEPOBIO context must run this routes
      // but actually make bug the INPN CAS deconnexion
      this._http.get<any>(`${AppConfig.API_ENDPOINT}/gn_auth/logout_cruved`).subscribe(() => {

        location.reload();

      });
      // refresh the page to refresh all the shared service to avoid cruved conflict

    }
  }

  private cleanLocalStorage() {
    // Remove only local storage items need to clear when user logout
    localStorage.removeItem('current_user');
    localStorage.removeItem('modules');
  }

  isAuthenticated(): boolean {
    return this._cookie.get('token') !== null;
  }
}
