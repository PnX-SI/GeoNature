import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { GeoJSON } from 'leaflet';
import { AppConfig } from '@geonature/conf/app.config';

@Injectable()
export class SearchService {

    constructor(private _api: HttpClient) { }

    getSyntheseData(params) {
        return this._api.post<GeoJSON>(`${AppConfig.API_ENDPOINT}/synthese/synthese`, params);
    }
}
