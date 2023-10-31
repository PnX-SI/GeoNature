import { Injectable } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Individual } from './interfaces';

@Injectable()
export class IndividualsService {
  constructor(private _http: HttpClient, public config: ConfigService) {}

  getIndividuals(idModule?: number) {
    let params: HttpParams = new HttpParams();
    if (idModule) {
      params = params.set('id_module', idModule);
    }

    return this._http.get<Individual[]>(`${this.config.API_ENDPOINT}/gn_monitoring/individuals`, {
      params: params,
    });
  }
}
