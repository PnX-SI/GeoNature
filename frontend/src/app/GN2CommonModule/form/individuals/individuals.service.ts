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
    idModule: number,
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
      `${this.config.API_ENDPOINT}/gn_monitoring/individuals/${idModule}`,
      { params: queryString }
    );
  }

  postIndividual(value: Individual, idModule: number) {
    return this._http.post<Individual>(
      `${this.config.API_ENDPOINT}/gn_monitoring/individual/${idModule}`,
      { ...value, id_modules: [idModule] }
    );
  }
}
