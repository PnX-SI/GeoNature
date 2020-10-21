import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { HttpClient } from '@angular/common/http';

import { AppConfig } from '@geonature_config/app.config';

@Injectable()
export class PermissionService {

  constructor(private http: HttpClient) {}

  sendAccessRequest(data: any): Observable<any> {
    const url = `${AppConfig.API_ENDPOINT}/permissions/access_requests`;
    return this.http.post<any>(url, data);
  }
}
