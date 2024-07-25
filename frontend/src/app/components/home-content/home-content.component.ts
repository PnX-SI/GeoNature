import { AfterViewInit, Component, OnInit } from '@angular/core';

import { LangChangeEvent, TranslateService } from '@ngx-translate/core';

import { MapService } from '@geonature_common/map/map.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';

import { SideNavService } from '../sidenav-items/sidenav-service';
import { ModuleService } from '../../services/module.service';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import * as L from 'leaflet';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-home-content',
  templateUrl: './home-content.component.html',
  styleUrls: ['./home-content.component.scss'],
  providers: [MapService, SyntheseDataService],
})
export class HomeContentComponent implements OnInit, AfterViewInit {
  public showLastObsMap: boolean = false;
  public showGeneralStat: boolean = false;
  public generalStat: any;
  public locale: string;
  public destroy$: Subject<boolean> = new Subject<boolean>();
  public cluserOrSimpleFeatureGroup = null;


  discussions = [];
  columns = [];
  currentPage = 1;
  perPage = 10;
  totalPages = 1;
  myReportsOnly = false; // Variable pour le filtre "Mes discussions"
  sort = 'desc'; // Assurez-vous d'avoir une méthode ou une logique pour gérer le tri si nécessaire
  expandedRow = null; // Track the currently expanded row
  constructor(
    private _SideNavService: SideNavService,
    private _syntheseApi: SyntheseDataService,
    private _mapService: MapService,
    private _moduleService: ModuleService,
    private translateService: TranslateService,
    public config: ConfigService
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
    this.getDiscussions();
  }

  ngOnDestroy(): void {
    this.destroy$.next(true);
    this.destroy$.unsubscribe();
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

  toggleMyReports() {
    this.myReportsOnly = !this.myReportsOnly;
    this.currentPage = 1; // Réinitialiser à la première page lors du changement du filtre
    this.getDiscussions(); // Recharger les discussions avec le filtre mis à jour
  }
  setDiscussions(data) {
    this.discussions = data.items || [];
    this.totalPages = data.totalPages || 1;
    this.columns = data.columns || [];
  }

  getDiscussions() {
    const params = new URLSearchParams();
    params.set('type', 'discussion');
    params.set('sort', this.sort || 'desc');
    params.set('page', this.currentPage.toString());
    params.set('per_page', this.perPage.toString());
    params.set('my_reports', this.myReportsOnly.toString());

    this._syntheseApi.getReports(params.toString()).subscribe((response) => {
      this.setDiscussions(response);
    });
  }

  changePage(page: number) {
    this.currentPage = page;
    this.getDiscussions(); // Recharger les discussions pour la nouvelle page
  }
  onRowClick(event) {
    console.log('Clicked row:', event.row);
  }

  toggleExpandRow(row) {
    if (this.expandedRow === row) {
      this.expandedRow = null; // Collapse if the same row is clicked again
    } else {
      this.expandedRow = row; // Expand the new row
    }
  }

}
