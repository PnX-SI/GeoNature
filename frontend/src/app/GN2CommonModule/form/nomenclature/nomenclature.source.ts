import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { Nomenclature } from '../../interfaces';
import { DataFormService } from '../data-form.service';
import { ItemsSource } from '../items-source';

export interface NomenclatureQuery {
  codeNomenclatureType: string;
  regne?: string;
  group2Inpn?: string;
  group3Inpn?: string;
  /** Restrict the items to these codes */
  cdNomenclatures?: Array<string>;
}

/** Items of a nomenclature type, ordered by label */
@Injectable({ providedIn: 'root' })
export class NomenclatureSource implements ItemsSource<NomenclatureQuery, Nomenclature> {
  constructor(private _dfs: DataFormService) {}

  load(query: NomenclatureQuery): Observable<Nomenclature[]> {
    return this._dfs
      .getNomenclature(
        query.codeNomenclatureType,
        query.regne,
        query.group2Inpn,
        query.group3Inpn,
        {
          orderby: 'label_default',
          cd_nomenclature: query.cdNomenclatures,
        }
      )
      .pipe(map((data) => data.values));
  }
}
