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

    getDataAreas(simplify_level, type_code, params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }
            }
        }
        return this.httpClient.get<any>(AppConfig.API_ENDPOINT + "/" + ModuleConfig.MODULE_URL + "/areas/" + simplify_level + "/" + type_code, { params: queryString })
    }

    getDataSynthesePerTaxLevel(taxLevel, params?) {
        let queryString = new HttpParams();
        if (params) {
            for (const key in params) {
                if (params[key]) {
                    queryString = queryString.set(key, params[key]);
                }
            }
        }
        return this.httpClient.get<any>(AppConfig.API_ENDPOINT + "/" + ModuleConfig.MODULE_URL + "/synthese_per_tax_level/" + taxLevel, { params: queryString })
    }

    getDataFrameworks() {
        return this.httpClient.get<any>(AppConfig.API_ENDPOINT + "/" + ModuleConfig.MODULE_URL + "/frameworks")
    }

    getDataRecontact(year) {
        return this.httpClient.get<any>(AppConfig.API_ENDPOINT + "/" + ModuleConfig.MODULE_URL + "/recontact/" + year)
    }

    getTaxonomy(taxLevel) {
        return this.httpClient.get<any>(AppConfig.API_ENDPOINT + "/" + ModuleConfig.MODULE_URL + "/taxonomy/" + taxLevel)
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

    getYears(model) {
        return this.httpClient.get<any>(AppConfig.API_ENDPOINT + "/" + ModuleConfig.MODULE_URL + "/years/" + model)
    }

}
