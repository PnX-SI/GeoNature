import { Injectable } from '@angular/core';
import { DataFormService } from '@geonature_common/form/data-form.service';
import {
  SyntheseDataService,
  TaxonStats,
} from '@geonature_common/form/synthese-form/synthese-data.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { BehaviorSubject } from 'rxjs';

@Injectable()
export class TaxonSheetService {
  taxon: BehaviorSubject<Taxon | null> = new BehaviorSubject<Taxon | null>(null);
  taxonStats: BehaviorSubject<TaxonStats | null> = new BehaviorSubject<TaxonStats | null>(null);

  constructor(
    private _ds: DataFormService,
    private _sds: SyntheseDataService
  ) {}

  updateTaxonByCdRef(cd_ref: number) {
    const taxon = this.taxon.getValue();
    if (taxon && taxon.cd_ref == cd_ref) {
      return;
    }
    this._ds.getTaxonInfo(cd_ref).subscribe((taxon) => {
      this.taxon.next(taxon);
      this.fetchTaxonStats(cd_ref);
    });
  }

  fetchTaxonStats(cd_ref: number) {
    this._sds.getSyntheseTaxonSheetStat(cd_ref).subscribe((stats: TaxonStats) => {
      this.taxonStats.next(stats);
    });
  }
}
