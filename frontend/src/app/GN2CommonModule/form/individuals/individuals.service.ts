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

  getIndividuals(
    moduleCode: string,
    cd_nom: number | null = null,
    active: boolean | null = null,
    id_nomenclature_sex: number | null = null
  ) {
    let queryString: HttpParams = new HttpParams();
    if (cd_nom) {
      queryString = queryString.set('cd_nom', cd_nom);
    }
    if (active !== null) {
      queryString = queryString.set('active', active);
    }
    if (id_nomenclature_sex) {
      queryString = queryString.set('id_nomenclature_sex', id_nomenclature_sex);
    }
    return this._http.get<Individual[]>(
      `${this.config.API_ENDPOINT}/gn_monitoring/individuals/${moduleCode}`,
      { params: queryString }
    );
  }

  postIndividual(value: Individual, moduleCode: string) {
    return this._http.post<Individual>(
      `${this.config.API_ENDPOINT}/gn_monitoring/individual/${moduleCode}`,
      { ...value, id_modules: value.id_modules ?? [] }
    );
  }
}
