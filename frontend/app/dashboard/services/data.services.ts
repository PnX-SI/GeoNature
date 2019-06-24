import { Injectable } from '@angular/core';
import { HttpClient, HttpParams, HttpErrorResponse } from '@angular/common/http';

@Injectable()
export class DataService {
    constructor(private httpClient: HttpClient) { }

    getDataSynthese(params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }
            }
        }
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/synthese", { params: queryString })
    }

    getDataCommunes(params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }
            }
        }
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/communes", { params: queryString })
    }

    getDataCommunesINPN(params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }
            }
        }
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/communes_inpn", { params: queryString })
    }

    getDataSynthesePerTaxLevel(params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }
            }
        }
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/synthese_per_tax_level", { params: queryString })
    }

    getDataFrameworks(params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }
            }
        }
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/frameworks", { params: queryString })
    }

    getFrameworksName(params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }
            }
        }
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/frameworks_name", { params: queryString })
    }

    getSpecies(params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }
            }
        }
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/species", { params: queryString })
    }

    getTaxonomie(params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }
            }
        }
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/taxonomie", { params: queryString })
    }

    getYears(params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }
            }
        }
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/years", { params: queryString })
    }

}
