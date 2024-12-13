import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { ConfigService } from '@geonature/services/config.service';
import { TaxonSheetService } from '../taxon-sheet.service';

import { StatusComponent } from './status/status.component';
import { TaxonomyComponent } from './taxonomy/taxonomy.component';

@Component({
  standalone: true,
  selector: 'infos',
  templateUrl: 'infos.component.html',
  styleUrls: ['infos.component.scss'],
  imports: [CommonModule, StatusComponent, TaxonomyComponent],
})
export class InfosComponent implements OnInit {
  taxon: Taxon | null = null;

  constructor(private _tss: TaxonSheetService) {}

  ngOnInit() {
    this._tss.taxon.subscribe((taxon: Taxon | null) => {
      this.taxon = taxon;
    });
  }
}
