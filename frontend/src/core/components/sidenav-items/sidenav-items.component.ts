import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { NavService } from '../../services/nav.service';
import { AuthService } from '../auth/auth.service';
import { ToastrService, ToastrConfig } from 'ngx-toastr';

@Component({
  selector: 'app-sidenav-items',
  templateUrl: './sidenav-items.component.html',
  styleUrls: ['./sidenav-items.component.scss']
})
export class SidenavItemsComponent implements OnInit {
  public nav = [{}];
  public toastrConfig: ToastrConfig;

  constructor(private _navService: NavService, private _authService: AuthService,
              private router: Router,  private toastrService: ToastrService) {
    this.toastrConfig = {
        positionClass: 'toast-top-center',
        tapToDismiss: true,
        timeOut: 2000
    };
    this.nav = _navService.getAppList();
  }
  ngOnInit() {
  }
  onSetApp(appName: string) {
    /** comment for dev **/
    // Test Authenticate if not valid, show dialog message.
    // if (!this._authService.isAuthenticated() && appName !== 'Accueil') {
    //   this.toastrService.warning('', 'Login to get access', this.toastrConfig);
    //   this.router.navigate(['/']);
    // } else {
    //   this._navService.setAppName(appName);
    // }
    this._navService.setAppName(appName);
  }
}
