import { Component, OnInit } from '@angular/core';
import { CruvedStoreService } from '../GN2CommonModule/service/cruved-store.service';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-admin',
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.scss'],
  providers: [],
})
export class AdminComponent implements OnInit {
  URL_ADMIN = null;

  constructor(
    public _cruvedStore: CruvedStoreService,
    public config: ConfigService
  ) {
    this.URL_ADMIN = this.config.API_ENDPOINT + '/admin/';
  }

  ngOnInit() {}
}
