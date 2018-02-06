import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { AppConfig } from '../../../conf/app.config';

@Injectable()
export class ContactService {

  constructor(private _api: HttpClient) { }

  getOneReleve(id) {
    return this._api.get<any>(`${AppConfig.API_ENDPOINT}/contact/releve/${id}`);
  }

  deleteReleve(id) {
    return this._api.delete(`${AppConfig.API_ENDPOINT}/contact/releve/${id}`);
  }

}
