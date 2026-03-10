import { Router, ActivatedRoute } from '@angular/router';
import { Observable, BehaviorSubject } from 'rxjs';
import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';

import { CookieService } from 'ng2-cookies';
import 'rxjs/add/operator/delay';
import * as moment from 'moment';
import { CruvedStoreService } from '@geonature_common/service/cruved-store.service';
import { ModuleService } from '../../services/module.service';
import { RoutingService } from '@geonature/routing/routing.service';
import { ConfigService } from '@geonature/services/config.service';
import { Provider } from '@geonature/modules/login/providers';
import { LoginDialog } from '@geonature/modules/login/login/external-login-dialog';

export interface User {
  user_login: string;
  id_role: string;
  id_organisme: number;
  prenom_role?: string;
  nom_role?: string;
  nom_complet?: string;
  providers?: string[];
}

export interface AuthMessage {
  translationKey: string;
  alertType: 'danger' | 'success';
}

@Injectable()
export class AuthService {
  authentified = false;
  currentUser: any;
  token: string;
  loginError: boolean;
  public isLoading = false;
  private prefix: string = 'gn_';
  private _currentMessage = new BehaviorSubject<AuthMessage | null>(null);
  currentMessage$ = this._currentMessage.asObservable();

  constructor(
    private router: Router,
    private route: ActivatedRoute,
    private _http: HttpClient,
    private _cookie: CookieService,
    private cruvedService: CruvedStoreService,
    private _routingService: RoutingService,
    private moduleService: ModuleService,
    public config: ConfigService
  ) {
    this.refreshCurrentUserData();
  }

  refreshCurrentUserData() {
    if (!this.currentUser) {
      this.currentUser = this.getCurrentUser();
    }
  }
  setCurrentUser(user) {
    localStorage.setItem(this.prefix + 'current_user', JSON.stringify(user));
  }

  getAuthProviders(): Observable<Array<Provider>> {
    return this._http.get<Array<Provider>>(`${this.config.API_ENDPOINT}/auth/providers`);
  }

  getCurrentUser() {
    let currentUser = localStorage.getItem(this.prefix + 'current_user');
    return JSON.parse(currentUser);
  }

  loginOrPwdRecovery(data: any): Observable<any> {
    // So error is not intercepted by interceptor and displayed in toaster
    const httpOptions = {
      headers: new HttpHeaders({
        'not-to-handle': 'true',
      }),
    };

    return this._http.post<any>(
      `${this.config.API_ENDPOINT}/users/login/recovery`,
      data,
      httpOptions
    );
  }

  passwordChange(data: any): Observable<any> {
    return this._http.put<any>(`${this.config.API_ENDPOINT}/users/password/new`, data);
  }

  confirmToken(data: any): Observable<any> {
    return this._http.get<any>(
      `${this.config.API_ENDPOINT}/users/confirmation?token=${data.token}`
    );
  }

  manageUser(data): any {
    this.setSession(data);
    if (!data.user.providers) {
      // when using public login
      data.user.providers = [];
    }
    const userForFront = {
      user_login: data.user.identifiant,
      prenom_role: data.user.prenom_role,
      id_role: data.user.id_role,
      nom_role: data.user.nom_role,
      nom_complet: data.user.nom_role + ' ' + data.user.prenom_role,
      id_organisme: data.user.id_organisme,
      providers: data.user.providers.map((provider) => provider.name),
    };
    this.setCurrentUser(userForFront);
    this.loginError = false;
  }

  setSession(authResult) {
    localStorage.setItem(this.prefix + 'id_token', authResult.token);
    localStorage.setItem(this.prefix + 'expires_at', authResult.expires);
  }

  signinUser(form: any) {
    return this._http.post<any>(`${this.config.API_ENDPOINT}/auth/login`, form);
  }

  signinPublicUser(): Observable<any> {
    return this._http.post<any>(`${this.config.API_ENDPOINT}/auth/public_login`, {});
  }

  signupUser(data: any): Observable<any> {
    const options = data;
    // So error is not intercepted by interceptor and displayed in toaster
    const httpOptions = {
      headers: new HttpHeaders({
        'not-to-handle': 'true',
      }),
    };
    return this._http.post<any>(`${this.config.API_ENDPOINT}/users/inscription`, data, httpOptions);
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
    document.cookie.split(';').forEach((c) => {
      document.cookie = c
        .replace(/^ +/, '')
        .replace(/=.*/, '=;expires=' + new Date().toUTCString() + ';path=/');
    });
  }

  isLoggedIn() {
    return moment().utc().isBefore(this.getExpiration());
  }

  isLoggedOut() {
    return !this.isLoggedIn();
  }

  getExpiration() {
    const expiration = localStorage.getItem(this.prefix + 'expires_at');
    return moment(expiration).utc();
  }

  logout() {
    this.cleanLocalStorage();
    this.cruvedService.clearCruved();
    let logout_url = `${this.config.API_ENDPOINT}/auth/logout`;
    location.href = logout_url;
  }

  private cleanLocalStorage() {
    // Remove only local storage items need to clear when user logout
    localStorage.removeItem(this.prefix + 'current_user');
    localStorage.removeItem(this.prefix + 'id_token');
    localStorage.removeItem(this.prefix + 'expires_at');
    localStorage.removeItem('modules');
    localStorage.removeItem('homePage.stats');
  }

  isAuthenticated(): boolean {
    return this._cookie.check('gn_id_token') && this._cookie.get('gn_id_token') !== null;
  }

  // Permet de mapper les codes renseignés dans GN ou renvoyés par UsersHubs vers des traductions.
  private errorCodeMappings: Record<string, AuthMessage> = {
    INCORRECT_LOGIN: {
      translationKey: 'Authentication.Errors.WrongLoginOrPassword',
      alertType: 'danger',
    },
    PENDING_VALIDATION_ALREADY_EXISTS: {
      translationKey: 'Authentication.Errors.PendingValidationAlreadyExists',
      alertType: 'danger',
    },
    PENDING_VALIDATION: {
      translationKey: 'MyAccount.Messages.AdminAccountEmailConfirmation',
      alertType: 'success',
    },
    WRONG_MAIL_ADRESS: {
      translationKey: 'Authentication.Errors.WrongMailAddress',
      alertType: 'danger',
    },
    UNEXPECTED_ERROR: {
      translationKey: 'Authentication.Errors.UnexpectedError',
      alertType: 'danger',
    },
  };

  handleLoginError(apiError?: { error_code?: string; message?: string }) {
    this.isLoading = false;
    this.loginError = true;
    this.handleLoginMessage(apiError.error_code, apiError.message);
  }

  handleLoginMessage(errorCode?: string, message?: string) {
    if (errorCode && this.errorCodeMappings[errorCode]) {
      this._currentMessage.next(this.errorCodeMappings[errorCode]);
    } else if (message) {
      this._currentMessage.next({ translationKey: message, alertType: 'danger' });
    } else {
      this._currentMessage.next({
        translationKey: 'Authentication.Errors.Generic',
        alertType: 'danger',
      });
    }
  }

  clearMessage() {
    this._currentMessage.next(null);
  }

  enableLoader() {
    this.isLoading = true;
  }

  disableLoader() {
    this.isLoading = false;
  }

  canBeLoggedWithLocalProvider(): boolean {
    this.refreshCurrentUserData();
    return this.currentUser.providers.includes('local_provider');
  }
}
