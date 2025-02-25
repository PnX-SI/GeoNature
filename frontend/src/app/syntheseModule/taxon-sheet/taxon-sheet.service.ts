import { Injectable } from '@angular/core';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { BehaviorSubject } from 'rxjs';

@Injectable()
export class TaxonSheetService {
  taxon: BehaviorSubject<Taxon | null> = new BehaviorSubject<Taxon | null>(null);

  constructor(private _ds: DataFormService) {}

  updateTaxonByCdRef(cd_ref: number) {
    const taxon = this.taxon.getValue();
    if (taxon && taxon.cd_ref == cd_ref) {
      return;
    }
    const taxhubFields = ['attributs', 'attributs.bib_attribut.label_attribut', 'status'];
    this._ds.getTaxonInfo(cd_ref, taxhubFields).subscribe((taxon) => {
      this.taxon.next(taxon);
    });
  }
}
