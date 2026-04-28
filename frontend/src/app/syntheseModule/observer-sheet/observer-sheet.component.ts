import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, NavigationEnd, Router } from '@angular/router';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { Subject } from 'rxjs';
import { filter, takeUntil } from 'rxjs/operators';

import { CommonModule } from '@angular/common';
import { InfosComponent } from './infos/infos.component';
import {
  computeIndicatorFromStats,
  Indicator,
  IndicatorDescription,
} from '@geonature_common/others/indicator/indicator';
import { ObserverStats } from '@geonature_common/form/synthese-form/synthese-data.service';
import { ObserverSheetRouteService } from './observer-sheet.route.service';
import { Loadable } from '../sheets/loadable';
import { ObserverSheetService } from './observer-sheet.service';
import { Observer } from './observer';

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
})
export class ObserverSheetComponent extends Loadable implements OnInit {
  observer: Observer;

  indicators: Array<Indicator>;

  get isLoadingIndicators() {
    return this.isLoading;
  }

  private readonly _destroy$ = new Subject<void>();

  constructor(
    private _route: ActivatedRoute,
    private _router: Router,
    public routes: ObserverSheetRouteService,
    private _oss: ObserverSheetService
  ) {
    super();
  }

  ngOnInit() {
    this._oss.observer.pipe(takeUntil(this._destroy$)).subscribe((observer: Observer) => {
      this.observer = observer;
      if (observer) {
        this.startLoading();
        this.setIndicators(null);
        this.redirectToDefaultTabIfNeeded();
      }
    });

    this._oss.observerStats
      .pipe(takeUntil(this._destroy$))
      .subscribe((stats: ObserverStats | null) => {
        if (stats) {
          this.stopLoading();
        }
        this.setIndicators(stats);
      });

    this._router.events
      .pipe(
        filter((event) => event instanceof NavigationEnd),
        takeUntil(this._destroy$)
      )
      .subscribe(() => this.redirectToDefaultTabIfNeeded());
  }

  ngOnDestroy(): void {
    this._destroy$.next();
    this._destroy$.complete();
  }

  setIndicators(stats: ObserverStats) {
    this.indicators = INDICATORS.map((indicatorConfig: IndicatorDescription) =>
      computeIndicatorFromStats(indicatorConfig, stats)
    );
  }

  private redirectToDefaultTabIfNeeded() {
    if (!this.observer || this._route.firstChild) {
      return;
    }

    const defaultTab = this.routes.TAB_LINKS[0]?.path;
    if (defaultTab) {
      this._router.navigate(['./', defaultTab], { relativeTo: this._route });
    }
  }
}
