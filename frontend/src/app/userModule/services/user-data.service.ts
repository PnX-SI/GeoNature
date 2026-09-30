import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { Role } from './form.service';
import { ConfigService } from '@geonature/services/config.service';

@Injectable()
export class UserDataService {
  constructor(
    private _http: HttpClient,
    public config: ConfigService
  ) {}

  getCurrentUserRole(): Observable<Role> {
    return this._http
      .get<any>(`${this.config.API_ENDPOINT}/auth/get_current_user`)
      .pipe(map((res) => res.user as Role));
  }

  putRole(role: Role): Observable<Role> {
    const options = role;
    return this._http.put<any>(`${this.config.API_ENDPOINT}/users/role`, options).pipe(
      map((res: Role) => {
        return res;
      })
    );
  }

  requestEmailChange(data: any): Observable<any> {
    return this._http.put<any>(`${this.config.API_ENDPOINT}/users/mail/change`, data).pipe(
      map((res: Role) => {
        return res;
      })
    );
  }
  validateEmailChange(newMail: string, userId: string): Observable<any> {
    const data = {
      new_mail: newMail,
      user: userId,
    };
    return this._http.put<any>(`${this.config.API_ENDPOINT}/users/mail/new`, data).pipe(
      map((res: Role) => {
        return res;
      })
    );
  }
  putPassword(role: Role): Observable<any> {
    const options = role;
    return this._http.put<any>(`${this.config.API_ENDPOINT}/users/password/change`, options).pipe(
      map((res: Role) => {
        return res;
      })
    );
  }
  checkLoginExists(login: string): Observable<boolean> {
    return this._http
      .get<boolean>(`${this.config.API_ENDPOINT}/auth/login_exists`, {
        params: { login: login },
      })
      .pipe(
        map((exists) => exists),
        catchError(() => of(false))
      );
  }
}
