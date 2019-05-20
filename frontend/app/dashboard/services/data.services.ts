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

    getNameRegne() {
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/regnes")
    }

    getNamePhylum() {
        return this.httpClient.get<any>("http://127.0.0.1:8000/dashboard/phylum")
    }

}
