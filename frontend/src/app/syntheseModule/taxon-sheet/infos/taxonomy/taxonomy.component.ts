import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
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
  static readonly PRIORITY = ['nom_vern', 'nom_valide', 'nom_complet', 'lb_nom'];
  @Input()
  taxon: Taxon | null = null;

  get nomComplet(): string {
    for (const attributePath of TaxonomyComponent.PRIORITY) {
      if (this.taxon[attributePath]) {
        return this.taxon[attributePath];
      }
    }

    return '';
  }
}
