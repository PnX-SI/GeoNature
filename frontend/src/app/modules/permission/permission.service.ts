import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { delay } from 'rxjs/operators';
import { HttpClient } from '@angular/common/http';

import { AppConfig } from '@geonature_config/app.config';
import { IRole } from './permission.interface'


@Injectable()
export class PermissionService {

  constructor(private http: HttpClient) {}

  getBreadcrumbsRoot() {
    return [
      {
        label: 'Accueil',
        iconClass: 'home',
        title: "Accueil de GeoNature.",
        url: '/'
      },
      {
        label: 'Admin',
        iconClass: 'settings',
        title: "Accueil de l'administration de GeoNature.",
        url: '/admin'
      },
    ];
  }

  sendAccessRequest(data: any): Observable<any> {
    const url = `${AppConfig.API_ENDPOINT}/permissions/access_requests`;
    return this.http.post<any>(url, data);
  }

  getAllRoles(): Observable<IRole[]> {
    const url = `${AppConfig.API_ENDPOINT}/permissions/roles`;
    return this.http.get<IRole[]>(url);
  }

  getRoleById(id: number): Observable<IRole> {
    const url = `${AppConfig.API_ENDPOINT}/permissions/roles/${id}`;
    return this.http.get<IRole>(url).pipe(delay(3000));
  }
}
