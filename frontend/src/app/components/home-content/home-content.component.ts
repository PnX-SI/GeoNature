import { AfterViewInit, Component, OnInit, ViewChild } from '@angular/core';

import { LangChangeEvent, TranslateService } from '@ngx-translate/core';

import { MapService } from '@geonature_common/map/map.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';

import { SideNavService } from '../sidenav-items/sidenav-service';
import { ModuleService } from '../../services/module.service';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import * as L from 'leaflet';
import { ConfigService } from '@geonature/services/config.service';
import { HomeDiscussionsService } from './home-discussions/home-discussions.service';

@Component({
  selector: 'pnx-home-content',
  templateUrl: './home-content.component.html',
  styleUrls: ['./home-content.component.scss'],
  providers: [MapService, SyntheseDataService, HomeDiscussionsService],
})
export class HomeContentComponent implements OnInit, AfterViewInit {
  public showLastObsMap: boolean = false;
  public showGeneralStat: boolean = false;
  public generalStat: any;
  public locale: string;
  public destroy$: Subject<boolean> = new Subject<boolean>();
  public cluserOrSimpleFeatureGroup = null;

  params: URLSearchParams = new URLSearchParams();
  constructor(
    private _SideNavService: SideNavService,
    private _syntheseApi: SyntheseDataService,
    private _mapService: MapService,
    private _moduleService: ModuleService,
    private translateService: TranslateService,
    public config: ConfigService,
    private _discussionsService: HomeDiscussionsService
  ) {
    // this work here thanks to APP_INITIALIZER on ModuleService
    let synthese_module = this._moduleService.getModule('SYNTHESE');
    let synthese_read_scope = synthese_module ? synthese_module.cruved['R'] : 0;

    if (this.config.FRONTEND.DISPLAY_MAP_LAST_OBS && synthese_read_scope > 0) {
      this.showLastObsMap = true;
    }
    if (this.config.FRONTEND.DISPLAY_STAT_BLOC && synthese_read_scope > 0) {
      this.showGeneralStat = true;
    }

    this.cluserOrSimpleFeatureGroup = this.config.SYNTHESE.ENABLE_LEAFLET_CLUSTER
      ? (L as any).markerClusterGroup()
      : new L.FeatureGroup();
  }

  ngOnInit() {
    // Ensure cleaning of currentModule
    this._moduleService.currentModule$.next(null);

    this.getI18nLocale();

    this._SideNavService.sidenav.open();

    if (this.showGeneralStat) {
      this.computeStatsBloc();
    }
  }

  ngAfterViewInit() {
    if (this.showLastObsMap) {
      this.computeMapBloc();
    }
  }

  ngOnDestroy(): void {
    this.destroy$.next(true);
    this.destroy$.unsubscribe();
  }

  get isExistBlockToDisplay(): boolean {
    return this._discussionsService.isAvailable; // NOTES [projet ARB]: ajouter les autres config à afficher ici || this.config.HOME.DISPLAY_LATEST_VALIDATIONS ..;
  }

  private computeMapBloc() {
    this.cluserOrSimpleFeatureGroup.addTo(this._mapService.map);
    this._syntheseApi
      .getSyntheseData({}, { limit: 100, format: 'ungrouped_geom' })
      .subscribe((data) => {
        let geojsonLayer = this._mapService.createGeojson(data, true, this.onEachFeature);
        this.cluserOrSimpleFeatureGroup.addLayer(geojsonLayer);
        this._mapService.map.addLayer(this.cluserOrSimpleFeatureGroup);
      });
  }

  private onEachFeature(feature, layer) {
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
      const milliSecondsTtl = this.config.FRONTEND.STAT_BLOC_TTL * 1000;
      const futureTimestamp = cacheEndDatetime.getTime() + milliSecondsTtl;
      cacheEndDatetime.setTime(futureTimestamp);

      if (currentDatetime.getTime() < cacheEndDatetime.getTime()) {
        needToRefreshStats = false;
      }
    }

    if (needToRefreshStats) {
      // Get general stats from Server
      this._syntheseApi.getSyntheseGeneralStat().subscribe((stats) => {
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
}
