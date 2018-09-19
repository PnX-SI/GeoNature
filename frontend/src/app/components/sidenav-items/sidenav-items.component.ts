import { Component, OnInit } from '@angular/core';
import { ToastrConfig } from 'ngx-toastr';
import { SideNavService } from './sidenav.service';

@Component({
  selector: 'pnx-sidenav-items',
  templateUrl: './sidenav-items.component.html',
  styleUrls: ['./sidenav-items.component.scss']
})
export class SidenavItemsComponent implements OnInit {
  public nav = [{}];
  public toastrConfig: ToastrConfig;
  public appConfig: any;

  constructor(private _sideNavService: SideNavService) {
    this.toastrConfig = {
      positionClass: 'toast-top-center',
      tapToDismiss: true,
      timeOut: 2000
    };
  }
  ngOnInit() {
    this._sideNavService.fetchModules().subscribe(data => {
      this._sideNavService.modules = data;
      this._sideNavService.setModulesLocalStorage(data);
    });
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
