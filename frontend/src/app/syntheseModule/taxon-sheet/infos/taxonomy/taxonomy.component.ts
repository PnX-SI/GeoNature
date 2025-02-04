import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
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
export class TaxonomyComponent {
  @Input()
  set taxon(taxon: Taxon | null) {
    this.updateBreadcrumb(taxon);
  }
  breadcrumb: any[] = [];

  constructor(private _ds: DataFormService) {}

  updateBreadcrumb(taxon: Taxon) {
    const breadcrumb = [];
    const allowedRanks = ['KD', 'PH', 'CL', 'OR', 'FM', 'GN', 'ES'];

    if (!taxon) {
      return;
    }

    this._ds
      .getTaxonInfo(taxon.cd_ref, ['cd_ref', 'id_rang', 'lb_nom', 'tree'])
      .subscribe((data: Taxon) => {
        if (!data.tree || !data.tree.parents) {
          return;
        }

        data.tree.parents
          .filter((parent) => allowedRanks.includes(parent.id_rang))
          .forEach((parent) => {
            breadcrumb.push({ cd_ref: parent.cd_ref, lb_nom: parent.lb_nom });
          });

        breadcrumb.sort(
          (a, b) => allowedRanks.indexOf(a.id_rang) - allowedRanks.indexOf(b.id_rang)
        );

        this.breadcrumb = breadcrumb;
      });
  }
}
