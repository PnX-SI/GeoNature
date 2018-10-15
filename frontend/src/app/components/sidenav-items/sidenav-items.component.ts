import { Component, OnInit } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { ToastrConfig } from 'ngx-toastr';
import { SideNavService } from './sidenav.service';
import { AuthService } from '../auth/auth.service';

@Component({
  selector: 'pnx-sidenav-items',
  templateUrl: './sidenav-items.component.html',
  styleUrls: ['./sidenav-items.component.scss']
})
export class SidenavItemsComponent implements OnInit {
  public nav = [{}];
  public toastrConfig: ToastrConfig;
  public appConfig: any;
  public version = AppConfig.GEONATURE_VERSION;

  constructor(private _sideNavService: SideNavService, private _authService: AuthService) {
    this.toastrConfig = {
      positionClass: 'toast-top-center',
      tapToDismiss: true,
      timeOut: 2000
    };
  }
  ngOnInit() {
    this._sideNavService.fetchModules().subscribe(
      data => {
        this._sideNavService.modules = data;
        this._sideNavService.setModulesLocalStorage(data);
      },
      error => {
        // @FIXME fix temporaire pour pallier au conflit de token entre geonature et taxhub
        if (error.status === 403) {
          this._authService.logout();
        }
      }
    );
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
