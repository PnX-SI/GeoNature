import { Component, OnInit } from '@angular/core';
import {
  ActivatedRoute,
  Router,
  RouterLink,
  RouterLinkActive,
  RouterOutlet,
} from '@angular/router';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { InfosComponent } from './infos/infos.component';
import { LayoutComponent } from './layout/layout.component';
import {
  computeIndicatorFromDecsription,
  Indicator,
  IndicatorDescription,
} from './indicator/indicator';
import { IndicatorComponent } from './indicator/indicator.component';
import { CommonModule } from '@angular/common';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { TaxonSheetService } from './taxon-sheet.service';
import { RouteService } from './taxon-sheet.route.service';

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
  selector: 'pnx-taxon-sheet',
  templateUrl: 'taxon-sheet.component.html',
  styleUrls: ['taxon-sheet.component.scss'],
  imports: [
    CommonModule,
    GN2CommonModule,
    IndicatorComponent,
    InfosComponent,
    LayoutComponent,
    RouterOutlet,
    RouterLink,
    RouterLinkActive,
  ],
  providers: [TaxonSheetService],
})
export class TaxonSheetComponent implements OnInit {
  readonly TAB_LINKS = [];

  indicators: Array<Indicator>;

  constructor(
    private _router: Router,
    private _route: ActivatedRoute,
    private _tss: TaxonSheetService,
    private _syntheseDataService: SyntheseDataService,
    private _routes: RouteService
  ) {
    this.TAB_LINKS = this._routes.TAB_LINKS;
  }
  ngOnInit() {
    this._route.params.subscribe((params) => {
      const cd_ref = params['cd_ref'];
      if (cd_ref) {
        this._tss.updateTaxonByCdRef(cd_ref);
        this._syntheseDataService.getSyntheseSpeciesSheetStat(cd_ref).subscribe((stats) => {
          this.setIndicators(stats);
        });
      }
    });
  }

  setIndicators(stats: any) {
    this.indicators = INDICATORS.map((indicatorConfig: IndicatorDescription) =>
      computeIndicatorFromDecsription(indicatorConfig, stats)
    );
  }

  goToPath(path: string) {
    this._router.navigate([path], { relativeTo: this._route });
  }
}
