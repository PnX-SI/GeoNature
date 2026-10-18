import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { Dataset } from '../../interfaces';
import { DataFormService } from '../data-form.service';
import { ItemsSource } from '../items-source';

/** Datasets of the user. The query is the filters of the API (see ``buildDatasetsParams``) */
@Injectable({ providedIn: 'root' })
export class DatasetsSource implements ItemsSource<Object, Dataset> {
  constructor(private _dfs: DataFormService) {}

  load(params: Object = {}): Observable<Dataset[]> {
    return this._dfs.getDatasets(params);
  }
}
