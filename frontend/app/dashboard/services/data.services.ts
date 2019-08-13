import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { AppConfig } from "@geonature_config/app.config";
import { ModuleConfig } from "../../module.config";

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
        return this.httpClient.get<any>(AppConfig.API_ENDPOINT + "/" + ModuleConfig.MODULE_URL + "/synthese", { params: queryString })
    }

    getDataCommunes(type_code, params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }
            }
        }
        return this.httpClient.get<any>(AppConfig.API_ENDPOINT + "/" + ModuleConfig.MODULE_URL + "/areas/" + type_code, { params: queryString })
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
        return this.httpClient.get<any>(AppConfig.API_ENDPOINT + "/" + ModuleConfig.MODULE_URL + "/communes_inpn", { params: queryString })
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
        return this.httpClient.get<any>(AppConfig.API_ENDPOINT + "/" + ModuleConfig.MODULE_URL + "/synthese_per_tax_level", { params: queryString })
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
        return this.httpClient.get<any>(AppConfig.API_ENDPOINT + "/" + ModuleConfig.MODULE_URL + "/frameworks", { params: queryString })
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
        return this.httpClient.get<any>(AppConfig.API_ENDPOINT + "/" + ModuleConfig.MODULE_URL + "/species", { params: queryString })
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
        return this.httpClient.get<any>(AppConfig.API_ENDPOINT + "/" + ModuleConfig.MODULE_URL + "/taxonomie", { params: queryString })
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
        return this.httpClient.get<any>(AppConfig.API_ENDPOINT + "/" + ModuleConfig.MODULE_URL + "/years", { params: queryString })
    }

    getAreasTypes(types_codes: Array<string>) {
        let queryString = new HttpParams();
        types_codes.forEach(
            elt => {
                queryString = queryString.append("type_code", elt);
            }
        )
        return this.httpClient.get<any>(AppConfig.API_ENDPOINT + "/" + ModuleConfig.MODULE_URL + "/areas_types", { params: queryString })
    }

}
