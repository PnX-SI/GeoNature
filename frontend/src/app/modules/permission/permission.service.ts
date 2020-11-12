import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { delay } from 'rxjs/operators';
import { HttpClient, HttpParams } from '@angular/common/http';

import { AppConfig } from '@geonature_config/app.config';
import { GnRolePermission, GnPermissionRequest } from './permission.interface'


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

  getAllRoles(): Observable<GnRolePermission[]> {
    const url = `${AppConfig.API_ENDPOINT}/permissions/roles`;
    return this.http.get<GnRolePermission[]>(url).pipe(delay(3000));
  }

  getRoleById(id: number): Observable<GnRolePermission> {
    const url = `${AppConfig.API_ENDPOINT}/permissions/roles/${id}`;
    return this.http.get<GnRolePermission>(url).pipe(delay(3000));
  }

  getAllProcessedRequests(): Observable<GnPermissionRequest[]> {
    const params = new HttpParams().set('state', 'processed');
    return this.getAllRequests(params)
  }

  getAllPendingRequests(): Observable<GnPermissionRequest[]> {
    const params = new HttpParams().set('state', 'prending');
    return this.getAllRequests(params)
  }

  private getAllRequests(params: HttpParams): Observable<GnPermissionRequest[]> {
    const url = `${AppConfig.API_ENDPOINT}/permissions/requests`;
    return this.http.get<GnPermissionRequest[]>(url, {params: params});
  }

  getRequestByToken(token: string): Observable<GnPermissionRequest> {
    const url = `${AppConfig.API_ENDPOINT}/permissions/requests/${token}`;
    return this.http.get<GnPermissionRequest>(url);
  }
}
