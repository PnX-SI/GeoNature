import { Component, OnInit } from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { FeatureCollection } from 'geojson';
import { ObserverSheetService } from '../observer-sheet.service';
import { Observer } from '../observer';
import { ConfigService } from '@geonature/services/config.service';
import { Router, RouterModule } from '@angular/router';

@Component({
  standalone: true,
  selector: 'tab-last-observations',
  templateUrl: 'tab-last-observations.component.html',
  styleUrls: ['tab-last-observations.component.scss'],
  imports: [GN2CommonModule, CommonModule, RouterModule],
})
export class TabLAstObservationsComponent implements OnInit {
  observations: FeatureCollection | null = null;
  constructor(
    private _syntheseDataService: SyntheseDataService,
    private _oss: ObserverSheetService,
    public mapListService: MapListService,
    public config: ConfigService,
    private _router: Router
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
            id_role: observer.id_role,
            limit: 100,
          },
          {}
        )
        .subscribe((data) => {
          this.observations = data.features.map((feature) => feature.properties);
          console.log(this.observations);
        });
    });
  }

  openObservation(id_synthese) {
    this._router.navigate(['/synthese/occurrence/' + id_synthese]);
  }

  backToModule(url_source, id_pk_source) {
    const link = document.createElement('a');
    link.target = '_blank';
    link.href = url_source + '/' + id_pk_source;
    link.setAttribute('visibility', 'hidden');
    document.body.appendChild(link);
    link.click();
    link.remove();
  }
}
