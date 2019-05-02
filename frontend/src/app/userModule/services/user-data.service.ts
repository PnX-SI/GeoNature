import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import 'rxjs/add/operator/toPromise';
import { AppConfig } from '../../../conf/app.config';

@Injectable()
export class UserDataService {
  constructor(private _http: HttpClient) {}

  getRole(id: number) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/role/${id}`);
  }

  getRoles(params?: any) {
    let queryString: HttpParams = new HttpParams();
    // tslint:disable-next-line:forin
    for (let key in params) {
      if (params[key] !== null) {
        queryString = queryString.set(key, params[key]);
      }
    }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/users/roles`, { params: queryString });
  }


}
