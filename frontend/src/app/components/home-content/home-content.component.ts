import { Component, OnInit, Inject } from '@angular/core';
import { AppConfig } from '../../../conf/app.config';
import { MapService } from '@geonature_common/map/map.service';
import { SideNavService } from '../sidenav-items/sidenav-service';


@Component({
  selector: 'pnx-home-content',
  templateUrl: './home-content.component.html',
  styleUrls: ['./home-content.component.scss'],
  providers: [MapService]
})
export class HomeContentComponent implements OnInit {
  private moduleName: string;
  public appConfig: any;

  constructor(private _SideNavService: SideNavService) {}

  ngOnInit() {
    this._SideNavService.sidenav.open();
    this.appConfig = AppConfig;
  }
}
