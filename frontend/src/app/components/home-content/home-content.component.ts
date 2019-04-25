import { Component, OnInit } from '@angular/core';
import { AppConfig } from '../../../conf/app.config';
import { MapService } from '@geonature_common/map/map.service';
import { SideNavService } from '../sidenav-items/sidenav-service';
import { DataService } from '@geonature/syntheseModule/services/data.service';
import { GlobalSubService } from '../../services/global-sub.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { ModuleService } from '../../services/module.service';

@Component({
  selector: 'pnx-home-content',
  templateUrl: './home-content.component.html',
  styleUrls: ['./home-content.component.scss'],
  providers: [MapService, DataService]
})
export class HomeContentComponent implements OnInit {
  private moduleName: string;
  public appConfig: any;
  public lastObs: any;
  public generalStat: any;

  constructor(
    private _SideNavService: SideNavService,
    private _syntheseApi: DataService,
    private _globalSub: GlobalSubService,
    private _api: DataFormService,
    private _moduleService: ModuleService
  ) {}

  ngOnInit() {
    this._SideNavService.sidenav.open();
    this.appConfig = AppConfig;
    if (AppConfig.FRONTEND.DISPLAY_MAP_LAST_OBS){
      this._syntheseApi.getSyntheseData({ limit: 100 }).subscribe(result => {
        this.lastObs = result.data;
      });
    }
    if (AppConfig.FRONTEND.DISPLAY_STAT_BLOC){
      // get general stats
      this._syntheseApi.getSyntheseGeneralStat().subscribe(result => {
        this.generalStat = result;
      });
    }


    // get module home if not already in localstorage
    if (!localStorage.getItem('modules')) {
      this._api.getModuleByCodeName('GEONATURE').subscribe(module => {
        module['module_label'] = 'Accueil';
        // emit the currentModule event
        this._globalSub.currentModuleSubject.next(module);
      });
    } else {
      // emit the currentModule event
      this._globalSub.currentModuleSubject.next(this._moduleService.getModule('GEONATURE'));
    }
  }

  onEachFeature(feature, layer) {
    // event from the map
    layer.on({
      click: () => {
        // open popup
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
