import { Injectable } from '@angular/core';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { BehaviorSubject } from 'rxjs';

@Injectable()
export class TaxonSheetService {
  taxon: BehaviorSubject<Taxon | null> = new BehaviorSubject<Taxon | null>(null);
  symbology: BehaviorSubject<any> = new BehaviorSubject<any>(null);

  constructor(private _ds: DataFormService) {}

  fetchStatusSymbology() {
    this._ds.fetchStatusSymbology().subscribe((symbology) => {
      this.symbology.next(symbology);
    });
  }

  updateTaxonByCdRef(cd_ref: number) {
    const taxon = this.taxon.getValue();
    if (taxon && taxon.cd_ref == cd_ref) {
      return;
    }
    this._ds.getTaxonInfo(cd_ref).subscribe((taxon) => {
      this.taxon.next(taxon);
    });
  }
}
