import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { Area } from '../../interfaces';
import { DataFormService } from '../data-form.service';
import { ItemsSource } from '../items-source';
import { formatAreas } from './areas.utils';

/** Geographic areas matching the filters of the API (``type_code``, ``area_name``, ...) */
@Injectable({ providedIn: 'root' })
export class AreasSource implements ItemsSource<Object, Area> {
  constructor(private _dfs: DataFormService) {}

  load(params: Object = {}): Observable<Area[]> {
    return this._dfs.getAreas(params).pipe(map((data) => formatAreas(data) as Area[]));
  }
}
