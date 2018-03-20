import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../auth/auth.service';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
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

  constructor(
    private _authService: AuthService,
    private router: Router,
    private toastrService: ToastrService,
    private _sideNavService: SideNavService
  ) {
    this.toastrConfig = {
      positionClass: 'toast-top-center',
      tapToDismiss: true,
      timeOut: 2000
    };
    this.nav = _sideNavService.getAppList();
  }
  ngOnInit() {}
  onSetApp(app) {
    this._sideNavService.setCurrentApp(app);
    if (app.moduleName === 'Accueil') {
      this._sideNavService.setHome(this._sideNavService.sidenav);
    } else {
      this._sideNavService.setModule(this._sideNavService.sidenav);
    }
  }
}
