import { Injectable } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
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
    public config: ConfigService,
    private _sds: SyntheseDataService
  ) {}

  updateTaxonByCdRef(cd_ref: number) {
    const taxon = this.taxon.getValue();
    if (taxon && taxon.cd_ref == cd_ref) {
      return;
    }
    const taxhubFields = ['attributs', 'attributs.bib_attribut.label_attribut', 'status'];
    this._ds.getTaxonInfo(cd_ref, taxhubFields).subscribe((taxon) => {
      taxon['attributs'] = taxon['attributs'].filter((v) => {
        return this.config.SYNTHESE.ID_ATTRIBUT_TAXHUB.includes(v.id_attribut);
      });
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
