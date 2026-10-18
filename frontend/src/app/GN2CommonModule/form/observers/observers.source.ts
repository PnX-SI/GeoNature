import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { Observer } from '../../interfaces';
import { DataFormService } from '../data-form.service';
import { ItemsSource } from '../items-source';

export interface ObserversQuery {
  /** Id of the list of users. Without id nor code, all the users are loaded */
  idMenu?: number;
  /** Code of the list of users, used when there is no id */
  codeList?: string;
}

@Injectable({ providedIn: 'root' })
export class ObserversSource implements ItemsSource<ObserversQuery, Observer> {
  constructor(private _dfs: DataFormService) {}

  load(query: ObserversQuery = {}): Observable<Observer[]> {
    if (query.idMenu) {
      return this._dfs.getObservers(query.idMenu);
    }
    if (query.codeList) {
      return this._dfs.getObserversFromCode(query.codeList);
    }
    return this._dfs.getObservers();
  }
}
