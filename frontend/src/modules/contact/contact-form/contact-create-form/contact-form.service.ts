import { Injectable } from '@angular/core';
import { Http } from '@angular/http';
import { AppConfig } from '../../../../conf/app.config';
@Injectable()
export class ContactFormService {

  constructor( private _http:Http) { }

  getReleve(id){
    return this._http.get(`${AppConfig.API_ENDPOINT}contact/releve/${id}`)
    .map(res => res.json());
  }  
}