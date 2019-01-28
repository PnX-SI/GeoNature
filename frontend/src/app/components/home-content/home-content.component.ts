import { Component, OnInit, Inject } from '@angular/core';
import { AppConfig } from '../../../conf/app.config';
import { MapService } from '@geonature_common/map/map.service';
import { SideNavService } from '../sidenav-items/sidenav-service';
import { DataService } from '@geonature/syntheseModule/services/data.service';

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

  constructor(private _SideNavService: SideNavService, private _syntheseApi: DataService) {}

  ngOnInit() {
    this._SideNavService.sidenav.open();
    this.appConfig = AppConfig;

    this._syntheseApi.getSyntheseData({ limit: 100 }).subscribe(result => {
      this.lastObs = result.data;
    });
    // get general stats
    this._syntheseApi.getSyntheseGeneralStat().subscribe(result => {
      this.generalStat = result;
    });
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
