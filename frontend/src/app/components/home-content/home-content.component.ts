import { Component, OnInit } from '@angular/core';
import { AppConfig } from '../../../conf/app.config';
import { MapService } from '@geonature_common/map/map.service';
import { SideNavService } from '../sidenav-items/sidenav-service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { GlobalSubService } from '../../services/global-sub.service';
import { ModuleService } from '../../services/module.service';

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

  constructor(
    private _SideNavService: SideNavService,
    private _syntheseApi: SyntheseDataService,
    private _globalSub: GlobalSubService,
    private _mapService: MapService,
    private _moduleService: ModuleService
  ) {}

  ngOnInit() {
    this._moduleService.moduleSub
    .filter(m => m!== null)
    .subscribe(m => {
      const gn_module = m.find(el => {
        return el.module_code == 'GEONATURE'
      });
      gn_module.module_label = 'Accueil'
      this._globalSub.currentModuleSubject.next(gn_module);
      
      
    })
    
    this._SideNavService.sidenav.open();
    this.appConfig = AppConfig;

    if (AppConfig.FRONTEND.DISPLAY_MAP_LAST_OBS) {
      this._syntheseApi.getSyntheseData({ limit: 100 }).subscribe(result => {
        this.lastObs = result.data;
      });
    }

    if (AppConfig.FRONTEND.DISPLAY_STAT_BLOC) {
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
