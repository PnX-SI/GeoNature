import { Injectable } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Individual } from './interfaces';

@Injectable()
export class IndividualsService {
  constructor(
    private _http: HttpClient,
    public config: ConfigService
  ) {}

  getIndividuals(idModule: number, cd_nom: number | null = null) {
    let queryString: HttpParams = new HttpParams();
    if (cd_nom) {
      queryString = queryString.set('cd_nom', cd_nom);
    }
    return this._http.get<Individual[]>(
      `${this.config.API_ENDPOINT}/gn_monitoring/individuals/${idModule}`,
      { params: queryString }
    );
  }

  postIndividual(value: Individual, idModule: number) {
    return this._http.post<Individual>(
      `${this.config.API_ENDPOINT}/gn_monitoring/individual/${idModule}`,
      value
    );
  }
}
