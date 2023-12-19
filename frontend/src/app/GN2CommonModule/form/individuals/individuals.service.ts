import { Injectable } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
import { HttpClient } from '@angular/common/http';
import { Individual } from './interfaces';

@Injectable()
export class IndividualsService {
  constructor(
    private _http: HttpClient,
    public config: ConfigService
  ) {}

  getIndividuals(idModule: number) {
    return this._http.get<Individual[]>(
      `${this.config.API_ENDPOINT}/gn_monitoring/individuals/${idModule}`
    );
  }

  postIndividual(value: Individual, idModule: number) {
    return this._http.post<Individual>(
      `${this.config.API_ENDPOINT}/gn_monitoring/individual/${idModule}`,
      value
    );
  }
}
