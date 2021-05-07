import { Component, OnInit } from '@angular/core';
import { MapService } from '@geonature_common/map/map.service';
import { SideNavService } from '../sidenav-items/sidenav-service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { GlobalSubService } from '../../services/global-sub.service';
import { ConfigService } from '@geonature/utils/configModule/core';
import { ModuleService } from '../../services/module.service';
import { HttpClient} from "@angular/common/http";

@Component({
  selector: 'pnx-home-content',
  templateUrl: './home-content.component.html',
  styleUrls: ['./home-content.component.css'],
  providers: [MapService, SyntheseDataService]
})
export class HomeContentComponent implements OnInit {

  public appConfig: any;
  public lastObs: any;
  public generalStat: any;
  public introductionComponent: any;
  public footerComponent: any;

  constructor(
    private _SideNavService: SideNavService,
    private _syntheseApi: SyntheseDataService,
    private _globalSub: GlobalSubService,
    private _mapService: MapService,
    private _moduleService: ModuleService,
    private _configService: ConfigService,
    private _httpClient: HttpClient,
  ) {
    this.appConfig = this._configService.getSettings();
  }

  ngOnInit() {
    this.loadCustomComponents();
    let gn_module = this._moduleService.getModule('GEONATURE');
    gn_module.module_label = 'Accueil';
    this._globalSub.currentModuleSubject.next(gn_module);

    this._SideNavService.sidenav.open();

    if (this.appConfig.FRONTEND.DISPLAY_MAP_LAST_OBS) {
      this._syntheseApi.getSyntheseData({ limit: 100 }).subscribe(result => {
        this.lastObs = result.data;
      });
    }

    if (this.appConfig.FRONTEND.DISPLAY_STAT_BLOC) {
      // Get general stats
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
        .subscribe(result => {
          this.generalStat = result;
        });
    }

  }

  loadCustomComponents() {
    this._httpClient.get(this.appConfig.API_ENDPOINT + '/static/custom/components/introduction.component.html', {
      responseType: 'text'
    }).subscribe(html => {
      this.introductionComponent = html;
    });

    this._httpClient.get(this.appConfig.API_ENDPOINT + '/static/custom/components/footer.component.html', {
      responseType: 'text'
    }).subscribe(html => {
      this.footerComponent = html;
    })
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
