import {
  ActivatedRouteSnapshot,
  CanActivate,
  CanActivateChild,
  Router,
  RouterStateSnapshot,
} from '@angular/router';
import { Injectable, Injector } from '@angular/core';
import { HttpClient } from '@angular/common/http';

import { AuthService } from '@geonature/components/auth/auth.service';
import { ModuleService } from '@geonature/services/module.service';
import { ConfigService } from '@geonature/services/config.service';
import { RoutingService } from './routing.service';

@Injectable()
export class AuthGuard implements CanActivate, CanActivateChild {
  constructor(
    private _router: Router,
    private _injector: Injector,
    private _httpclient: HttpClient,
    private config: ConfigService,
    private _authService: AuthService
  ) {}

  async redirectAuth(route, state) {
    const authService = this._injector.get(AuthService);
    const moduleService = this._injector.get(ModuleService);
    const configService = this._injector.get(ConfigService);
    const routingService = this._injector.get(RoutingService);

    if (!authService.isLoggedIn()) {
      if (
        route.queryParams.access &&
        route.queryParams.access === 'public' &&
        configService.PUBLIC_ACCESS_USERNAME
      ) {
        const data = await authService
          .signinPublicUser()
          .toPromise()
          .catch(() => {
            authService.handleLoginError();
            return false;
          });
        if (data) {
          authService.manageUser(data);
          const modules = await moduleService.loadModules().toPromise();
          routingService.loadRoutes(modules, route._routerState.url.replace('access=public', ''));
        } else {
          return false;
        }
      } else if (configService.CAS_PUBLIC.CAS_AUTHENTIFICATION) {
        const url_redirection_cas = `${configService.CAS_PUBLIC.CAS_URL_LOGIN}?service=${configService.API_ENDPOINT}/gn_auth/login_cas`;
        document.location.href = url_redirection_cas;
        let data = await this._httpclient
          .get(`${this.config.API_ENDPOINT}/auth/get_current_user`)
          .toPromise();
        data = { ...data };
        this._authService.manageUser(data);
      } else {
        this._router.navigate(['/login'], {
          queryParams: { ...route.queryParams, ...{ route: state.url.split('?')[0] } },
        });
        return false;
      }
    } else if (moduleService.shouldLoadModules) {
      const modules = await moduleService.loadModules().toPromise();
      routingService.loadRoutes(modules, route._routerState.url);
    }

    return true;
  }
  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    return this.redirectAuth(route, state);
  }

  canActivateChild(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    return this.redirectAuth(route, state);
  }
}
