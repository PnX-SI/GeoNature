import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';

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
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/synthese",{params: queryString})
    }
    
    getCommunes(params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }                 
            }
        }
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/communes",{params: queryString})
    }

    getCommunesINPN(params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }                 
            }
        }
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/communes_inpn",{params: queryString})
    }

    getDataRegne(params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }                 
            }
        }
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/regne_data",{params: queryString})
    }

    getDataPhylum(params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }                 
            }
        }
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/phylum_data",{params: queryString})
    }

    getDataClasse(params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }                 
            }
        }
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/classe_data",{params: queryString})
    }

    getDataGroup1INPN(params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }                 
            }
        }
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/group1_inpn_data",{params: queryString})
    }

    getDataGroup2INPN(params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }                 
            }
        }
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/group2_inpn_data",{params: queryString})
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
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/taxonomie",{params: queryString})
    }

    getYears() {
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/years")
    }

}
