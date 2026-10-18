import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { AcquisitionFramework } from '../../interfaces';
import { DataFormService } from '../data-form.service';
import { ItemsSource } from '../items-source';
import { sortAcquisitionFrameworks } from './acquisition-frameworks.utils';

/** All the acquisition frameworks of the user, sorted by name */
@Injectable({ providedIn: 'root' })
export class AcquisitionFrameworksSource implements ItemsSource<void, AcquisitionFramework> {
  constructor(private _dfs: DataFormService) {}

  load(): Observable<AcquisitionFramework[]> {
    return this._dfs
      .getAcquisitionFrameworksList({}, {}, 1, -1)
      .pipe(map((data) => sortAcquisitionFrameworks(data.items)));
  }
}
