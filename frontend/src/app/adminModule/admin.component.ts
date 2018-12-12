import { Component, OnInit } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { AdminStoreService } from './services/admin-store.service';

@Component({
  selector: 'pnx-admin',
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.scss'],
  providers: [AdminStoreService]
})
export class AdminComponent implements OnInit {
  URL_NOMENCLATURE_ADMIN = AppConfig.API_ENDPOINT +
    '/nomenclatures/admin/bibnomenclaturestypesadmin/';

  URL_BACKOFFICE_PERM = AppConfig.API_ENDPOINT + '/permissions_backoffice/users';
  constructor(public adminStoreService: AdminStoreService) {}

  ngOnInit() {}
}
