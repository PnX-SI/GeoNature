import { Component, OnInit } from '@angular/core';

import { LangChangeEvent, TranslateService } from '@ngx-translate/core';

import { MapService } from '@geonature_common/map/map.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';

import { AppConfig } from '../../../conf/app.config';
import { SideNavService } from '../sidenav-items/sidenav-service';
import { GlobalSubService } from '../../services/global-sub.service';
import { ModuleService } from '../../services/module.service';
import { Subject } from 'rxjs';

@Component({
  selector: 'pnx-home-content',
  templateUrl: './home-content.component.html',
  styleUrls: ['./home-content.component.scss'],
  providers: [MapService, SyntheseDataService]
})
export class HomeContentComponent implements OnInit {

  public appConfig: any;
  public lastObs: any;
  public generalStat: any;
  public locale: string;
  public destroy$: Subject<boolean> = new Subject<boolean>();

  constructor(
    private _SideNavService: SideNavService,
    private _syntheseApi: SyntheseDataService,
    private _globalSub: GlobalSubService,
    private _mapService: MapService,
    private _moduleService: ModuleService,
    private translateService: TranslateService,
  ) {}

  ngOnInit() {
    this.getI18nLocale();

    this._SideNavService.sidenav.open();
    this.appConfig = AppConfig;

    if (AppConfig.FRONTEND.DISPLAY_MAP_LAST_OBS) {
      this._syntheseApi.getSyntheseData({ limit: 100 }).subscribe(result => {
        this.lastObs = result.data;
      });
    }

    if (AppConfig.FRONTEND.DISPLAY_STAT_BLOC) {
      this.computeStatsBloc();
    }
  }

  ngOnDestroy(): void {
    this.destroy$.next(true);
    this.destroy$.unsubscribe();
  }

  private computeStatsBloc() {
    // Get general stats from Local Storage if exists
    let needToRefreshStats = true;
    let statsSerialized = localStorage.getItem('homePage.stats');
    if (statsSerialized && JSON.parse(statsSerialized)) {
      let stats = JSON.parse(statsSerialized);
      this.generalStat = stats;

      // Compute refresh need
      const currentDatetime = new Date();
      const cacheEndDatetime = new Date(stats.createdDate);
      const milliSecondsTtl = (AppConfig.FRONTEND.STAT_BLOC_TTL * 1000)
      const futureTimestamp = cacheEndDatetime.getTime() + milliSecondsTtl;
      cacheEndDatetime.setTime(futureTimestamp);

      if (currentDatetime.getTime() < cacheEndDatetime.getTime()) {
        needToRefreshStats = false;
      }
    }

    if (needToRefreshStats) {
      // Get general stats from Server
      this._syntheseApi
        .getSyntheseGeneralStat()
        .map(stat => {
          // tslint:disable-next-line:forin
          for (const key in stat) {
            // Pretty the number with spaces
            if (stat[key]) {
              stat[key] = stat[key].toLocaleString('fr-FR');
            }
          }
          return stat;
        })
        .subscribe(stats => {
          stats['createdDate'] = new Date().toUTCString();
          localStorage.setItem('homePage.stats', JSON.stringify(stats));
          this.generalStat = stats;
        });
    }
  }

  private getI18nLocale() {
    this.locale = this.translateService.currentLang;
    // don't forget to unsubscribe!
    this.translateService.onLangChange
      .takeUntil(this.destroy$)
      .subscribe((langChangeEvent: LangChangeEvent) => {
        this.locale = langChangeEvent.lang;
      });
  }

  onEachFeature(feature, layer) {
    layer.setStyle(this._mapService.originStyle);
    // Event from the map
    layer.on({
      click: () => {
        // Open popup
        const popup = `
          ${feature.properties.nom_vern_or_lb_nom} <br>
          <b> Observé le: </b> ${feature.properties.date_min} <br>
          <b> Par</b>:  ${feature.properties.observers}
        `;
        layer.bindPopup(popup).openPopup();
      }
    });
  }
}
