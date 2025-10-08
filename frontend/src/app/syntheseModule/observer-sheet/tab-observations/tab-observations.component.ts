import { Component, OnInit } from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { FeatureCollection } from 'geojson';
import { ObserverSheetService } from '../observer-sheet.service';
import { Observer } from '../observer';

@Component({
  standalone: true,
  selector: 'tab-observations',
  templateUrl: 'tab-observations.component.html',
  imports: [GN2CommonModule, CommonModule],
})
export class TabObservationsComponent implements OnInit {
  observations: FeatureCollection | null = null;
  constructor(
    private _syntheseDataService: SyntheseDataService,
    private _oss: ObserverSheetService,
    public mapListService: MapListService
  ) {}

  ngOnInit() {
    this._oss.observer.subscribe((observer: Observer | null) => {
      if (!observer) {
        this.observations = null;
        return;
      }
      this._syntheseDataService
        .getSyntheseData(
          {
            observers: observer.nom_complet,
            id_role: observer.id_role
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
