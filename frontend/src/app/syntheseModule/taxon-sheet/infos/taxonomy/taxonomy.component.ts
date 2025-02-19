import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { Taxon, TaxonParents } from '@geonature_common/form/taxonomy/taxonomy.component';
import { RouterModule } from '@librairies/@angular/router';
import { RouteService } from '../../taxon-sheet.route.service';
import { DataFormService } from '@geonature_common/form/data-form.service';

@Component({
  standalone: true,
  selector: 'taxonomy',
  templateUrl: 'taxonomy.component.html',
  styleUrls: ['taxonomy.component.scss'],
  imports: [CommonModule, RouterModule],
})
export class TaxonomyComponent {
  static readonly PRIORITY = ['nom_vern', 'nom_valide', 'nom_complet', 'lb_nom'];
  private _taxon: Taxon | null = null;
  linnaeanParents: TaxonParents = [];

  @Input()
  set taxon(taxon: Taxon | null) {
    if (taxon == this._taxon) {
      return;
    }
    this._taxon = taxon;

    if (taxon) {
      this._ds.getTaxonLinnaeanParents(this.taxon).subscribe((parents) => {
        this.linnaeanParents = parents['parents'];
      });
    } else {
      this.linnaeanParents = [];
    }
  }

  get taxon(): Taxon | null {
    return this._taxon;
  }

  constructor(
    private _rs: RouteService,
    private _ds: DataFormService
  ) {}

  get nomComplet(): string {
    for (const attributePath of TaxonomyComponent.PRIORITY) {
      if (this.taxon[attributePath]) {
        return this.taxon[attributePath];
      }
    }

    return '';
  }

  navigateToCDRef(cd_ref: number) {
    this._rs.navigateToCDRef(cd_ref);
  }
}
