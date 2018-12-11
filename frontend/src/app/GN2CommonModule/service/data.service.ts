import { Injectable } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { HttpClient, HttpParams } from '@angular/common/http';

@Injectable()
export class DataService {

    constructor(private _api: HttpClient) { }

    getCruvedForUserInApp(idApp, idAppParent?) {
        let queryString = new HttpParams();
        if (idAppParent) {
            queryString = queryString.set('id_app_parent', idAppParent);
        }
        return this._api.get<any>(`${AppConfig.API_ENDPOINT}/auth/cruved/${idApp}`, {params: queryString});
    }
}