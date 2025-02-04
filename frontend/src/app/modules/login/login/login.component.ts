import { Component, OnInit } from '@angular/core';
import { UntypedFormGroup } from '@angular/forms';

import { CommonService } from '@geonature_common/service/common.service';

import { CookieService } from 'ng2-cookies';
import { AuthService } from '../../../components/auth/auth.service';
import { ConfigService } from '@geonature/services/config.service';
import { ModuleService } from '@geonature/services/module.service';
import { ActivatedRoute, Router } from '@angular/router';
import { RoutingService } from '@geonature/routing/routing.service';

@Component({
  selector: 'pnx-login',
  templateUrl: 'login.component.html',
  styleUrls: ['./login.component.scss'],
})
export class LoginComponent implements OnInit {
  enable_sign_up: boolean = false;
  enable_user_management: boolean = false;
  external_links: [] = [];
  public casLogin: boolean;
  public disableSubmit = false;
  public enablePublicAccess = null;
  identifiant: UntypedFormGroup;
  password: UntypedFormGroup;
  form: UntypedFormGroup;
  login_or_pass_recovery: boolean = false;
  public APP_NAME = null;

  constructor(
    private _authService: AuthService,
    private _commonService: CommonService,
    public config: ConfigService,
    private moduleService: ModuleService,
    private router: Router,
    private route: ActivatedRoute,
    private _routingService: RoutingService,
    private _cookie: CookieService
  ) {
    this.enablePublicAccess = this.config.PUBLIC_ACCESS_USERNAME;
    this.APP_NAME = this.config.appName;
    this.casLogin = this.config.CAS_PUBLIC.CAS_AUTHENTIFICATION;
    this.enable_sign_up = this.config['ACCOUNT_MANAGEMENT']['ENABLE_SIGN_UP'] || false;
    this.enable_user_management =
      this.config['ACCOUNT_MANAGEMENT']['ENABLE_USER_MANAGEMENT'] || false;
    this.external_links = this.config['ACCOUNT_MANAGEMENT']['EXTERNAL_LINKS'];
  }

  ngOnInit() {
    if (this.casLogin) {
      // Try to navigate to the home page, and may then be redirected to the CAS login page by the AuthGuard in a second step
      //  this is done because the route 'login', associated to the current component LoginComponent, is not protected by any guard
      //  while the route '' is well protected, by the AuthGuard
      this.router.navigate(['']);
    }
  }

  async register(user) {
    this._authService.enableLoader();
    const data = await this._authService
      .signinUser(user)
      .toPromise()
      .catch(() => {
        this._authService.handleLoginError();
      });
    this.handleRegister(data);
    this._authService.disableLoader();
  }

  async registerPublic() {
    const data = await this._authService
      .signinPublicUser()
      .toPromise()
      .catch(() => {
        this._authService.handleLoginError();
      });
    this.handleRegister(data);
  }

  loginOrPwdRecovery(data) {
    this.disableSubmit = true;
    this._authService
      .loginOrPwdRecovery(data)
      .subscribe(() => {
        this._commonService.translateToaster('info', 'PasswordAndLoginRecovery');
      })
      .add(() => {
        this.disableSubmit = false;
      });
  }

  async handleRegister(data) {
    if (data) {
      this._authService.manageUser(data);
      const modules = await this.moduleService.loadModules().toPromise();
      await this._routingService.loadRoutes(modules);
      let next = this.route.snapshot.queryParams['next'];
      let route = this.route.snapshot.queryParams['route'];
      // next means redirect to url
      // route means navigate to angular route
      if (next) {
        if (route) {
          window.location.href = next + '#' + route;
        } else {
          window.location.href = next;
        }
      } else if (route) {
        this.router.navigateByUrl(route);
      } else {
        this.router.navigate(['']);
      }
    }
  }
}
