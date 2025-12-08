import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { map } from 'rxjs/operators';
import { Role } from './form.service';
import { ConfigService } from '@geonature/services/config.service';
import { AuthService } from '@geonature/components/auth/auth.service';

@Injectable()
export class UserDataService {
  constructor(
    private _http: HttpClient,
    public config: ConfigService,
    private authService: AuthService
  ) {}

  getCurrentUserRole(): Observable<Role> {
    return this.getRole(this.authService.getCurrentUser().id_role);
  }

  getRole(id: number): Observable<Role> {
    return this._http.get<any>(`${this.config.API_ENDPOINT}/users/role/${id}`);
  }

  getRoles(params?: any) {
    let queryString: HttpParams = new HttpParams();
    // eslint-disable-next-line guard-for-in
    for (let key in params) {
      if (params[key] !== null) {
        queryString = queryString.set(key, params[key]);
      }
    }
    return this._http.get<any>(`${this.config.API_ENDPOINT}/users/roles`, { params: queryString });
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
    return of({ success: true, msg: 'Email change request simulated' });
  }
  putPassword(role: Role): Observable<any> {
    const options = role;
    return this._http.put<any>(`${this.config.API_ENDPOINT}/users/password/change`, options).pipe(
      map((res: Role) => {
        return res;
      })
    );
  }
}
