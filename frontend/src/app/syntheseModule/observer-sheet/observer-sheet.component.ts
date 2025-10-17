import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';import { GN2CommonModule } from '@geonature_common/GN2Common.module';

import { CommonModule } from '@angular/common';
import { InfosComponent } from './infos/infos.component';
import { computeIndicatorFromStats, Indicator, IndicatorDescription } from '@geonature_common/others/indicator/indicator';
import { ObserverStats } from '@geonature_common/form/synthese-form/synthese-data.service';
import { ID_ROLE_PARAM_NAME, ObserverSheetRouteService } from './observer-sheet.route.service';
import { Loadable } from '../sheets/loadable';
import { ObserverSheetService } from './observer-sheet.service';
import { Observer } from './observer';
import { ObservationsFiltersService } from '../sheets/observations/observations-filters.service';

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
  templateUrl: 'observer-sheet.component.html',
  imports: [CommonModule, GN2CommonModule, InfosComponent],
  providers: [ObservationsFiltersService, ObserverSheetService],
})
export class ObserverSheetComponent extends Loadable implements OnInit {
  observer: Observer | null = null;

  indicators: Array<Indicator>;

  get isLoadingIndicators() {
    return this.isLoading;
  }

  constructor(
    private _route: ActivatedRoute,
    public routes: ObserverSheetRouteService,
    private _oss: ObserverSheetService
  ) {
    super();
  }

  ngOnInit() {
    this._oss.observer.subscribe((observer: Observer | null) => {
      this.observer = observer;
    });

    this._oss.observerStats.subscribe((stats: ObserverStats | null) => {
      if (stats) {
        this.stopLoading();
      }
      this.setIndicators(stats);
    });

    this._route.params.subscribe((params) => {
      const id_role = params[ID_ROLE_PARAM_NAME];
      if (id_role) {
        this.startLoading();
        this.setIndicators(null);
        this._oss.fetchObserverByIdRole(id_role);
      }
    });
  }

  setIndicators(stats: ObserverStats) {
    this.indicators = INDICATORS.map((indicatorConfig: IndicatorDescription) =>
      computeIndicatorFromStats(indicatorConfig, stats)
    );
  }
}
