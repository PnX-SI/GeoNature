import { Component, OnInit } from '@angular/core';

import { LangChangeEvent, TranslateService } from '@ngx-translate/core';

import { MapService } from '@geonature_common/map/map.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';

import { AppConfig } from '../../../conf/app.config';
import { SideNavService } from '../sidenav-items/sidenav-service';
import { ModuleService } from '../../services/module.service';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

@Component({
  selector: 'pnx-home-content',
  templateUrl: './home-content.component.html',
  styleUrls: ['./home-content.component.scss'],
  providers: [MapService, SyntheseDataService],
})
export class HomeContentComponent implements OnInit {
  public appConfig: any;
  public showLastObsMap: boolean = false;
  public lastObs: any;
  public showGeneralStat: boolean = false;
  public generalStat: any;
  public locale: string;
  public destroy$: Subject<boolean> = new Subject<boolean>();

  constructor(
    private _SideNavService: SideNavService,
    private _syntheseApi: SyntheseDataService,
    private _mapService: MapService,
    private _moduleService: ModuleService,
    private translateService: TranslateService
  ) {
    // this work here thanks to APP_INITIALIZER on ModuleService
    let synthese_module = this._moduleService.getModule('SYNTHESE');
    let synthese_read_scope = synthese_module ? synthese_module.cruved['R'] : 0;

    if (AppConfig.FRONTEND.DISPLAY_MAP_LAST_OBS && synthese_read_scope > 0) {
      this.showLastObsMap = true;
    }
    if (AppConfig.FRONTEND.DISPLAY_STAT_BLOC && synthese_read_scope > 0) {
      this.showGeneralStat = true;
    }
  }

  ngOnInit() {
    this.getI18nLocale();

    this._SideNavService.sidenav.open();
    this.appConfig = AppConfig;

    if (this.showLastObsMap) {
      this._syntheseApi.getSyntheseData({ limit: 100 }).subscribe((data) => {
        this.lastObs = data;
      });
    }

    if (this.showGeneralStat) {
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
      const milliSecondsTtl = AppConfig.FRONTEND.STAT_BLOC_TTL * 1000;
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
        // .map(stat => {
        //   // eslint-disable-next-line guard-for-in
        //   for (const key in stat) {
        //     // Pretty the number with spaces
        //     if (stat[key]) {
        //       stat[key] = stat[key].toLocaleString('fr-FR');
        //     }
        //   }
        //   return stat;
        // })
        .subscribe((stats) => {
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
      .pipe(takeUntil(this.destroy$))
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
      },
    });
  }
}
