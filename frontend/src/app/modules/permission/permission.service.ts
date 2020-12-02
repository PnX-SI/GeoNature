import { Inject, Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { delay } from 'rxjs/operators';
import { HttpClient, HttpParams } from '@angular/common/http';

import { APP_CONFIG_TOKEN } from '@geonature_config/app.config';
import { IRolePermission, IPermissionRequest } from './permission.interface'


@Injectable()
export class PermissionService {

  constructor(
    @Inject(APP_CONFIG_TOKEN) private cfg,
    private http: HttpClient,
  ) {}

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
    const url = `${this.cfg.API_ENDPOINT}/permissions/access_requests`;
    return this.http.post<any>(url, data);
  }

  getAllRoles(): Observable<IRolePermission[]> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/roles`;
    return this.http.get<IRolePermission[]>(url).pipe(delay(3000));
  }

  getRoleById(id: number): Observable<IRolePermission> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/roles/${id}`;
    return this.http.get<IRolePermission>(url).pipe(delay(3000));
  }

  getAllProcessedRequests(): Observable<IPermissionRequest[]> {
    const params = new HttpParams().set('state', 'processed');
    return this.getAllRequests(params)
  }

  getAllPendingRequests(): Observable<IPermissionRequest[]> {
    const params = new HttpParams().set('state', 'pending');
    return this.getAllRequests(params)
  }

  private getAllRequests(params: HttpParams): Observable<IPermissionRequest[]> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/requests`;
    return this.http.get<IPermissionRequest[]>(url, {params: params});
  }

  getRequestByToken(token: string): Observable<IPermissionRequest> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/requests/${token}`;
    return this.http.get<IPermissionRequest>(url);
  }

  acceptRequest(token: string): Observable<IPermissionRequest> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/requests/${token}`;
    return this.http.patch<IPermissionRequest>(url, {'processedState': 'accepted'});
  }

  pendingRequest(token: string): Observable<IPermissionRequest> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/requests/${token}`;
    return this.http.patch<IPermissionRequest>(url, {'processedState': 'pending'});
  }

  refuseRequest(request: IPermissionRequest): Observable<IPermissionRequest> {
    const url = `${this.cfg.API_ENDPOINT}/permissions/requests/${request.token}`;
    request.processedState = 'refused';
    return this.http.patch<IPermissionRequest>(url, request);
  }
}
