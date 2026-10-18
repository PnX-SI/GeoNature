import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { HigherTaxon } from '../../interfaces';
import { DataFormService } from '../data-form.service';
import { ItemsSource } from '../items-source';

export interface TaxaQuery {
  /** Minimum rank of the names, ex: ``GN`` */
  rank: string;
  /** Search term */
  term: string;
}

@Injectable({ providedIn: 'root' })
export class TaxaSource implements ItemsSource<TaxaQuery, HigherTaxon> {
  constructor(private _dfs: DataFormService) {}

  load(query: TaxaQuery): Observable<HigherTaxon[]> {
    return this._dfs.getHigherTaxa(query.rank, query.term);
  }
}
