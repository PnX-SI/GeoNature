import { Component, OnInit } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';

@Component({
  selector: 'pnx-admin',
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.scss']
})
export class AdminComponent implements OnInit {
  URL_NOMENCLATURE_ADMIN = AppConfig.API_ENDPOINT +
    '/nomenclatures/admin/bibnomenclaturestypesadmin/';
  constructor() {}

  ngOnInit() {}
}
