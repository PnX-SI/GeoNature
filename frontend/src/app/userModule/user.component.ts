import { Component, OnInit } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { CruvedStoreService } from '../services/cruved-store.service';

@Component({
  selector: 'pnx-user',
  templateUrl: './user.component.html',
  /*styleUrls: ['./user.component.scss'],*/
  providers: []
})
export class UserComponent implements OnInit {
  URL_NOMENCLATURE_ADMIN = AppConfig.API_ENDPOINT +
    '/nomenclatures/admin/bibnomenclaturestypesadmin/';

  URL_BACKOFFICE_PERM = AppConfig.API_ENDPOINT + '/permissions_backoffice/users';
  constructor(private _cruvedStore: CruvedStoreService) {}

  ngOnInit() {}
}
