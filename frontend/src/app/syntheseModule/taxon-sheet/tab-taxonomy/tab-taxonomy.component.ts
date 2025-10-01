import { Component, OnInit } from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { TaxonSheetService } from '../taxon-sheet.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { SharedSyntheseModule } from '@geonature/shared/syntheseSharedModule/synthese-shared.module';

@Component({
  standalone: true,
  templateUrl: 'tab-taxonomy.component.html',
  imports: [GN2CommonModule, CommonModule, SharedSyntheseModule],
})
export class TabTaxonomyComponent implements OnInit {
  taxon: Taxon | null = null;
  constructor(private _tss: TaxonSheetService) {}

  ngOnInit() {
    this._tss.taxon.subscribe((taxon: Taxon | null) => {
      this.taxon = taxon;
    });
  }
}
