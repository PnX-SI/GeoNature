import { Component, OnInit } from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { FeatureCollection } from 'geojson';
import { TaxonSheetService } from '../taxon-sheet.service';

@Component({
  standalone: true,
  selector: 'tab-geographic-overview',
  templateUrl: 'tab-geographic-overview.component.html',
  styleUrls: ['tab-geographic-overview.component.scss'],
  imports: [GN2CommonModule, CommonModule],
})
export class TabGeographicOverviewComponent implements OnInit {
  observations: FeatureCollection | null = null;
  constructor(
    private _syntheseDataService: SyntheseDataService,
    private _tss: TaxonSheetService,
    public mapListService: MapListService
  ) {}

  ngOnInit() {
    this._tss.taxon.subscribe((taxon: Taxon | null) => {
      if (!taxon) {
        this.observations = null;
        return;
      }
      this._syntheseDataService
        .getSyntheseData(
          {
            cd_ref_parent: [taxon.cd_ref],
          },
          {}
        )
        .subscribe((data) => {
          // Store geojson
          this.observations = data;
        });
    });
  }
}
