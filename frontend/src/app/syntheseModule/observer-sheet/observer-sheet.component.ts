import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';import { GN2CommonModule } from '@geonature_common/GN2Common.module';

import { CommonModule } from '@angular/common';
import { ObserverSheetService } from './observer-sheet.service';
import { InfosComponent } from './infos/infos.component';
import { computeIndicatorFromStats, Indicator, IndicatorDescription } from '@geonature_common/others/indicator/indicator';
import { ObserverStats, Stats, SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { ObserverSheetRouteService } from './observer-sheet.route.service';
import { Loadable } from '../sheets/loadable';

const INDICATORS: Array<IndicatorDescription> = [
  {
    name: 'observation(s)',
    matIcon: 'search',
    field: 'observation_count',
    type: 'number',
  },
  {
    name: 'taxon(s) observé(s)',
    matIcon: 'search',
    field: 'taxa_count',
    type: 'number',
  },
  {
    name: 'commune(s)',
    matIcon: 'location_on',
    field: 'area_count',
    type: 'number',
  },
  {
    name: "Plage d'observation(s)",
    matIcon: 'date_range',
    type: 'date',
    field: ['date_min', 'date_max'],
    separator: '-',
  },
];

@Component({
  standalone: true,
  selector: 'pnx-observer-sheet',
  templateUrl: 'observer-sheet.component.html',
  styleUrls: ['observer-sheet.component.scss'],
  imports: [CommonModule, GN2CommonModule, InfosComponent],
})
export class ObserverSheetComponent extends Loadable implements OnInit {
  indicators: Array<Indicator>;

  get isLoadingIndicators() {
    return this.isLoading;
  }

  constructor(
    private _route: ActivatedRoute,
    private _sds: SyntheseDataService,
    public routes: ObserverSheetRouteService
  ) {
    super();
  }

  ngOnInit() {
    this._route.params.subscribe((params) => {
      const id_role = params['id_role'];
      if (id_role) {
        this.startLoading();
        this.setIndicators(null);
        this._sds.getSyntheseObserverSheetStats(id_role).subscribe((stats) => {
          if (stats) {
            this.stopLoading();
          }
          this.setIndicators(stats);
        });
      }
    });
  }

  setIndicators(stats: ObserverStats) {
    this.indicators = INDICATORS.map((indicatorConfig: IndicatorDescription) =>
      computeIndicatorFromStats(indicatorConfig, stats as Stats)
    );
  }
}
