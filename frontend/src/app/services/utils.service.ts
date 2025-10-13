import { Injectable } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
import { HttpClient } from '@angular/common/http';
import { map } from 'rxjs/operators';
import { Observable } from 'rxjs';

export interface ReferentialData {
  referencial_name: string;
  version: string;
}

@Injectable({
  providedIn: 'root',
})
export class UtilsService {
  constructor(
    private _http: HttpClient,
    public config: ConfigService
  ) {}

  getRefVersion(): Observable<ReferentialData[]> {
    return this._http
      .get<any>(`${this.config.API_ENDPOINT}/taxhub${this.config.TAXHUB.API_PREFIX}/taxref/version`)
      .pipe(map((response: ReferentialData) => [response]));
  }
}
