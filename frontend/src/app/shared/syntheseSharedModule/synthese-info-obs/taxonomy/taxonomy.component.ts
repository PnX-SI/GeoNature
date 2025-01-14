import { Component, Input, OnInit } from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { Taxon } from '@geonature_common/form/taxonomy/taxon';

@Component({
  selector: 'pnx-synthese-taxonomy',
  templateUrl: 'taxonomy.component.html',
  styleUrls: ['taxonomy.component.scss'],
})
export class TaxonomyComponent {
  @Input()
  taxon: Taxon | null = null;
  constructor() {}
}
