import { Component, OnInit } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { ToastrConfig } from 'ngx-toastr';
import { SideNavService } from './sidenav-service';
import { ModuleService } from '../../services/module.service';

@Component({
  selector: 'pnx-sidenav-items',
  templateUrl: './sidenav-items.component.html',
  styleUrls: ['./sidenav-items.component.scss'],
  providers: [ModuleService]
})
export class SidenavItemsComponent implements OnInit {
  public nav = [{}];
  public toastrConfig: ToastrConfig;
  public appConfig: any;
  public version = AppConfig.GEONATURE_VERSION;
  public home_page: any;
  public exportModule: any;


  constructor(
    private _sideNavService: SideNavService,
    public moduleService: ModuleService
    ) {
    this.toastrConfig = {
      positionClass: 'toast-top-center',
      tapToDismiss: true,
      timeOut: 2000
    };
  }
  ngOnInit() {

    this.home_page = { module_url: '/', module_label: 'Accueil', module_picto: 'fa-home', id: '1' };
    this.exportModule = {
      module_url: '/exports',
      module_label: 'Export',
      module_picto: 'fa-download',
      id: '2'
    };
  
  }

  onSetApp(app) {
    this._sideNavService.setCurrentApp(app);
    if (app.module_name === 'Accueil') {
      this._sideNavService.setHome(this._sideNavService.sidenav);
    } else {
      this._sideNavService.setModule(this._sideNavService.sidenav);
    }
  }
}
