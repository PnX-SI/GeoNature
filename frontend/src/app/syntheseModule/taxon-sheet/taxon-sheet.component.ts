import { Component, OnDestroy, OnInit } from '@angular/core';
import { ActivatedRoute, NavigationEnd, Router } from '@angular/router';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { InfosComponent } from './infos/infos.component';
import {
  computeIndicatorFromStats,
  Indicator,
  IndicatorDescription,
} from '@geonature_common/others/indicator/indicator';
import { TaxonImageComponent } from './taxon-image/taxon-image.component';
import { CommonModule } from '@angular/common';
import { TaxonStats } from '@geonature_common/form/synthese-form/synthese-data.service';
import { TaxonSheetService } from './taxon-sheet.service';
import { CD_REF_PARAM_NAME, TaxonSheetRouteService } from './taxon-sheet.route.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { Loadable } from '../sheets/loadable';
import { ObservationsFiltersService } from '../sheets/observations/observations-filters.service';
import { Subject } from 'rxjs';
import { filter, takeUntil } from 'rxjs/operators';

const INDICATORS: Array<IndicatorDescription> = [
  {
    name: 'observation(s)',
    matIcon: 'search',
    field: 'observation_count',
    type: 'number',
  },
  {
    name: 'observateur(s)',
    matIcon: 'people',
    field: 'observer_count',
    type: 'number',
  },
  {
    name: 'commune(s)',
    matIcon: 'location_on',
    field: 'area_count',
    type: 'number',
  },
  {
    name: "Plage d'altitude(s)",
    matIcon: 'terrain',
    unit: 'm',
    type: 'number',
    field: ['altitude_min', 'altitude_max'],
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
  templateUrl: 'taxon-sheet.component.html',
  imports: [CommonModule, GN2CommonModule, InfosComponent, TaxonImageComponent],
  providers: [TaxonSheetService],
})
export class TaxonSheetComponent extends Loadable implements OnInit {
  taxon: Taxon | null = null;
  private readonly _destroy$ = new Subject<void>();

  get isLoadingIndicators() {
    return this.isLoading;
  }

  indicators: Array<Indicator>;

  constructor(
    private _route: ActivatedRoute,
    private _router: Router,
    private _tss: TaxonSheetService,
    public routes: TaxonSheetRouteService
  ) {
    super();
  }

  ngOnInit() {
    this._tss.taxon.pipe(takeUntil(this._destroy$)).subscribe((taxon: Taxon | null) => {
      this.taxon = taxon;
    });

    this._tss.taxonStats.pipe(takeUntil(this._destroy$)).subscribe((stats: TaxonStats | null) => {
      this.stopLoading();
      this.setIndicators(stats);
    });

    this._route.params.pipe(takeUntil(this._destroy$)).subscribe((params) => {
      const cd_ref = params[CD_REF_PARAM_NAME];
      if (cd_ref) {
        this.startLoading();
        this.setIndicators(null);
        this._tss.fetchTaxonByCdRef(cd_ref);
        this.redirectToDefaultTabIfNeeded();
      }
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

  setIndicators(stats: any) {
    this.indicators = INDICATORS.map((indicatorConfig: IndicatorDescription) =>
      computeIndicatorFromStats(indicatorConfig, stats)
    );
  }

  private redirectToDefaultTabIfNeeded() {
    if (!this._route.snapshot.params[CD_REF_PARAM_NAME] || this._route.firstChild) {
      return;
    }

    const defaultTab = this.routes.TAB_LINKS[0]?.path;
    if (defaultTab) {
      this._router.navigate(['./', defaultTab], { relativeTo: this._route });
    }
  }
}
