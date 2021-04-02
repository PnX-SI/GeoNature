import { Component, OnInit } from '@angular/core';
import { ConfigService } from '@geonature/utils/configModule/core';
import { CruvedStoreService } from '../GN2CommonModule/service/cruved-store.service';

@Component({
  selector: 'pnx-admin',
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.scss'],
  providers: []
})
export class AdminComponent implements OnInit {
  public appConfig: any;
  URL_NOMENCLATURE_ADMIN: any;
  URL_BACKOFFICE_PERM: any;

  constructor(
    public _cruvedStore: CruvedStoreService,
    private _configService: ConfigService,
  ) {
    this.appConfig = this._configService.getSettings();
    this.URL_NOMENCLATURE_ADMIN = this.appConfig.API_ENDPOINT + '/admin/';
    this.URL_BACKOFFICE_PERM = this.appConfig.API_ENDPOINT + '/permissions_backoffice/users';
  }

  ngOnInit() {}
}
