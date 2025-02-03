import { CommonModule } from '@angular/common';
import { Component, Input, OnChanges, SimpleChanges } from '@angular/core';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { RouterModule } from '@librairies/@angular/router';

@Component({
  standalone: true,
  selector: 'taxonomy',
  templateUrl: 'taxonomy.component.html',
  styleUrls: ['taxonomy.component.scss'],
  imports: [CommonModule, RouterModule],
})
export class TaxonomyComponent implements OnChanges {
  @Input()
  taxon: Taxon | null = null;
  breadcrumb: any[] = [];

  constructor(private _ds: DataFormService) {}

  ngOnChanges(changes: SimpleChanges) {
    if (changes.taxon && changes.taxon.currentValue) {
      this.buildBreadCrumb(this.taxon);
    }
  }

  async buildBreadCrumb(taxon: Taxon) {
    const breadcrumb = [];
    let currentTaxon = taxon;
    const allowedRanks = ['KD', 'PH', 'CL', 'OR', 'FM', 'GN', 'ES'];

    while (currentTaxon) {
      if (allowedRanks.includes(currentTaxon.id_rang)) {
        breadcrumb.unshift({
          cd_ref: currentTaxon.cd_ref,
          name: currentTaxon.nom_complet,
          lb_nom: currentTaxon.lb_nom,
          rank: currentTaxon.id_rang,
        });
      }
      if (currentTaxon.cd_sup) {
        const parentTaxon = await this._ds.getTaxonInfo(currentTaxon.cd_sup).toPromise();
        currentTaxon = parentTaxon;
      } else {
        currentTaxon = null;
      }
    }
    this.breadcrumb = breadcrumb;
  }
}
