import { Component, OnInit } from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { TaxonSheetService } from '../taxon-sheet.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxon';
import { SharedSyntheseModule } from '@geonature/shared/syntheseSharedModule/synthese-shared.module';

@Component({
  standalone: true,
  selector: 'tab-taxonomy',
  templateUrl: 'tab-taxonomy.component.html',
  styleUrls: ['tab-taxonomy.component.scss'],
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
