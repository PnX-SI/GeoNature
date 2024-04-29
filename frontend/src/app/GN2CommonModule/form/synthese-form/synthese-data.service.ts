import { Injectable } from '@angular/core';
import {
  HttpClient,
  HttpParams,
  HttpHeaders,
  HttpEventType,
  HttpErrorResponse,
  HttpEvent,
} from '@angular/common/http';
import { BehaviorSubject } from 'rxjs';
import { CommonService } from '@geonature_common/service/common.service';
import { Observable } from 'rxjs';
import { ConfigService } from '@geonature/services/config.service';

export const FormatMapMime = new Map([
  ['csv', 'text/csv'],
  ['json', 'application/json'],
  ['shp', 'application/zip'],
]);

@Injectable()
export class SyntheseDataService {
  public dataLoaded: Boolean = false;
  public isDownloading: Boolean = false;
  public downloadProgress: BehaviorSubject<number>;
  private _blob: Blob;
  constructor(
    private _api: HttpClient,
    public config: ConfigService
  ) {
    this.downloadProgress = <BehaviorSubject<number>>new BehaviorSubject(0.0);
  }

  buildQueryUrl(params): HttpParams {
    let queryUrl = new HttpParams();
    for (let key in params) {
      if (Array.isArray(params[key])) {
        params[key].forEach((value) => {
          queryUrl = queryUrl.append(key, value);
        });
      } else {
        queryUrl = queryUrl.set(key, params[key]);
      }
    }
    return queryUrl;
  }

  getSyntheseData(filters, selectors) {
    return this._api.post<any>(`${this.config.API_ENDPOINT}/synthese/for_web`, filters, {
      params: selectors,
    });
  }

  getSyntheseGeneralStat() {
    return this._api.get<any>(`${this.config.API_ENDPOINT}/synthese/general_stats`);
  }

  getTaxaCount(params = {}) {
    let queryString = new HttpParams();
    for (let key in params) {
      queryString = queryString.set(key, params[key].toString());
    }
    return this._api.get<any>(`${this.config.API_ENDPOINT}/synthese/taxa_count`, {
      params: queryString,
    });
  }

  getObsCount(params = {}) {
    let queryString = new HttpParams();
    for (let key in params) {
      queryString = queryString.set(key, params[key].toString());
    }
    return this._api.get<any>(`${this.config.API_ENDPOINT}/synthese/observation_count`, {
      params: queryString,
    });
  }

  getObsBbox(params = {}) {
    let queryString = new HttpParams();
    for (let key in params) {
      queryString = queryString.set(key, params[key].toString());
    }
    return this._api.get<any>(`${this.config.API_ENDPOINT}/synthese/observations_bbox`, {
      params: queryString,
    });
  }

  getOneSyntheseObservation(id_synthese) {
    return this._api.get<any>(`${this.config.API_ENDPOINT}/synthese/vsynthese/${id_synthese}`);
  }

  // validation data
  getDefinitionData() {
    return this._api.get<any>(`${this.config.API_ENDPOINT}/validation/definitions`);
  }

  getStatusNames() {
    return this._api.get<any>(`${this.config.API_ENDPOINT}/validation/statusNames`);
  }

  getTaxonTree() {
    return this._api.get<any>(`${this.config.API_ENDPOINT}/synthese/taxons_tree`);
  }

  downloadObservations(idSyntheseList: Array<number>, format: string, view_name: string) {
    this.isDownloading = true;
    let queryString = new HttpParams().set('export_format', format);
    queryString = queryString.set('view_name', view_name);
    const source = this._api.post(
      `${this.config.API_ENDPOINT}/synthese/export_observations`,
      idSyntheseList,
      {
        params: queryString,
        headers: new HttpHeaders().set('Content-Type', 'application/json'),
        observe: 'events',
        responseType: 'blob',
        reportProgress: true,
      }
    );

    this.subscribeAndDownload(source, 'synthese_observations', format);
  }

  downloadTaxons(idSyntheseList: Array<number>, format: string, filename: string) {
    this.isDownloading = true;

    const source = this._api.post(
      `${this.config.API_ENDPOINT}/synthese/export_taxons`,
      idSyntheseList,
      {
        headers: new HttpHeaders().set('Content-Type', 'application/json'),
        observe: 'events',
        responseType: 'blob',
        reportProgress: true,
      }
    );

    this.subscribeAndDownload(source, filename, format);
  }

  downloadStatusOrMetadata(url: string, format: string, postParams: any, filename: string) {
    this.isDownloading = true;

    const source = this._api.post(`${url}`, postParams, {
      observe: 'events',
      responseType: 'blob',
      reportProgress: true,
    });
    this.subscribeAndDownload(source, filename, format);
  }

  downloadUuidReport(filename: string, args: { [key: string]: string }) {
    let queryString: HttpParams = new HttpParams();
    // eslint-disable-next-line guard-for-in
    for (const key in args) {
      queryString = queryString.set(key, args[key].toString());
    }
    const source = this._api.get(`${this.config.API_ENDPOINT}/meta/uuid_report`, {
      headers: new HttpHeaders().set('Content-Type', 'text/csv'),
      observe: 'events',
      responseType: 'blob',
      reportProgress: true,
      params: queryString,
    });
    this.subscribeAndDownload(source, filename, 'csv', false);
  }

  downloadSensiReport(filename: string, args: { [key: string]: string }) {
    let queryString: HttpParams = new HttpParams();
    // eslint-disable-next-line guard-for-in
    for (const key in args) {
      queryString = queryString.set(key, args[key].toString());
    }
    const source = this._api.get(`${this.config.API_ENDPOINT}/meta/sensi_report`, {
      headers: new HttpHeaders().set('Content-Type', 'text/csv'),
      observe: 'events',
      responseType: 'blob',
      reportProgress: true,
      params: queryString,
    });
    this.subscribeAndDownload(source, filename, 'csv', false);
  }

  subscribeAndDownload(
    source: Observable<HttpEvent<Blob>>,
    fileName: string,
    format: string,
    addDateToFilename: boolean = true
  ): void {
    const subscription = source.subscribe(
      (event) => {
        if (event.type === HttpEventType.Response) {
          this._blob = new Blob([event.body], { type: event.headers.get('Content-Type') });
        }
      },
      (e: HttpErrorResponse) => {
        this.isDownloading = false;
      },
      // response OK
      () => {
        this.isDownloading = false;
        const date = new Date();
        const extension = format === 'shapefile' ? 'zip' : format;
        this.saveBlob(
          this._blob,
          `${fileName}${addDateToFilename ? '_' + date.toISOString() : ''}.${extension}`
        );
        subscription.unsubscribe();
      }
    );
  }

  saveBlob(blob, filename) {
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.setAttribute('visibility', 'hidden');
    link.download = filename;
    link.onload = () => {
      URL.revokeObjectURL(link.href);
    };
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  getReports(params) {
    return this._api.get(`${this.config.API_ENDPOINT}/synthese/reports?${params}`);
  }

  createReport(params) {
    return this._api.post(`${this.config.API_ENDPOINT}/synthese/reports`, params);
  }

  deleteReport(id) {
    return this._api.delete(`${this.config.API_ENDPOINT}/synthese/reports/${id}`);
  }

  modifyReport(id, params) {
    return this._api.put(`${this.config.API_ENDPOINT}/synthese/reports/${id}`, params);
  }
}
