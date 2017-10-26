import { Injectable } from '@angular/core';
import { Http } from '@angular/http';
import { AppConfig } from '../../../conf/app.config';

@Injectable()
export class ContactService {

  constructor(private _api: Http) { }

  getReleve(id) {
    return this._api.get(`${AppConfig.API_ENDPOINT}contact/releve/${id}`)
    .map(res => res.json());
  }

  deleteReleve(id) {
    return this._api.delete(`${AppConfig.API_ENDPOINT}contact/releve/${id}`)
      .map(res => res.status);
  }
}
