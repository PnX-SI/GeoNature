import { Component, OnInit } from '@angular/core';
import { UntypedFormGroup } from '@angular/forms';
import { MatDialog } from '@angular/material/dialog';

import { CommonService } from '@geonature_common/service/common.service';

import { CookieService } from 'ng2-cookies';
import { AuthService } from '../../../components/auth/auth.service';
import { ConfigService } from '@geonature/services/config.service';
import { ModuleService } from '@geonature/services/module.service';
import { ActivatedRoute, Router } from '@angular/router';
import { RoutingService } from '@geonature/routing/routing.service';
import { Provider } from '../providers';
import { LoginDialog } from './external-login-dialog';

@Component({
  selector: 'pnx-login',
  templateUrl: 'login.component.html',
  styleUrls: ['./login.component.scss'],
})
export class LoginComponent implements OnInit {
  enable_sign_up: boolean = false;
  enable_user_management: boolean = false;
  external_links: [] = [];
  public disableSubmit = false;
  public enablePublicAccess = null;
  identifiant: UntypedFormGroup;
  password: UntypedFormGroup;
  form: UntypedFormGroup;
  login_or_pass_recovery: boolean = false;
  public APP_NAME = null;
  public authProviders: Array<Provider>;
  public localProviderEnabled: boolean = true;
  public isOtherProviders: boolean = false;
  constructor(
    public _authService: AuthService, //FIXME : change to private (html must be modified)
    private _commonService: CommonService,
    public config: ConfigService,
    private moduleService: ModuleService,
    private router: Router,
    private route: ActivatedRoute,
    private _routingService: RoutingService,
    public dialog: MatDialog
  ) {
    this.enablePublicAccess = this.config.PUBLIC_ACCESS_USERNAME;
    this.APP_NAME = this.config.appName;
    this.enable_sign_up = this.config['ACCOUNT_MANAGEMENT']['ENABLE_SIGN_UP'] || false;
    this.enable_user_management =
      this.config['ACCOUNT_MANAGEMENT']['ENABLE_USER_MANAGEMENT'] || false;
    this.external_links = this.config['ACCOUNT_MANAGEMENT']['EXTERNAL_LINKS'];
  }

  ngOnInit() {

    this._authService.getAuthProviders().subscribe((providers) => {
      this.authProviders = providers;
      this.isOtherProviders = this.authProviders.length > 1;
      // If local provider is not available in the configuration, disable it
      if (!this.authProviders.find((p) => p.id_provider === 'local_provider')) {
        this.localProviderEnabled = false;
      }
      // Local provider should not be display in the other providers buttons
      this.authProviders = this.authProviders.filter((p) => p.id_provider !== 'local_provider');

      // If one provider is declared (except the local one)
      if (this.authProviders.length === 1 && !this.localProviderEnabled) {
        const provider = this.authProviders[0];
        window.location.href = this.getProviderLoginUrl(provider.id_provider);
      }
    });
  }

  async register(form) {
    this._authService.enableLoader();
    const data = await this._authService
      .signinUser(form)
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

  /**
   * Returns the login URL for a given provider.
   *
   * @param {string} provider_id - The ID of the provider.
   * @return {string} The login URL for the provider.
   */
  getProviderLoginUrl(provider_id: string): string {
    return `${this.config.API_ENDPOINT}/auth/login/${provider_id}`;
  }

  /**
   * Opens a dialog to connect to a specified provider (with is_external activated) .
   *
   * @param {Provider} provider - The provider for which the dialog is opened.
   */
  openDialog(provider) {
    const dialogRef = this.dialog.open(LoginDialog, {
      height: '30%',
      width: '30%',
      position: { top: '10%' },
      data: {
        provider: provider,
      },
    });

    const componentInstance: LoginDialog = dialogRef.componentInstance;
    componentInstance.userLogged.subscribe((data) => {
      this.handleRegister(data);
      dialogRef.close();
    });
  }
}
