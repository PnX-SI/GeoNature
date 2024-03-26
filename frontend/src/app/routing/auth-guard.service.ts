import {
  ActivatedRouteSnapshot,
  CanActivate,
  CanActivateChild,
  Router,
  RouterStateSnapshot,
} from '@angular/router';
import { Injectable, Injector } from '@angular/core';
import { AuthService } from '@geonature/components/auth/auth.service';
import { ModuleService } from '@geonature/services/module.service';
import { ConfigService } from '@geonature/services/config.service';
import { RoutingService } from './routing.service';

import * as moment from 'moment';

@Injectable()
export class AuthGuard implements CanActivate, CanActivateChild {
  constructor(
    private _router: Router,
    private _injector: Injector
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
          await authService.manageUser(data).toPromise();
          const modules = await moduleService.loadModules().toPromise();
          routingService.loadRoutes(modules, route._routerState.url);
        } else {
          return false;
        }
        // } else if (configService.CAS_PUBLIC.CAS_AUTHENTIFICATION) {
        //   // if token not here here, redirection to CAS login page
        //   const url_redirection_cas = `${configService.CAS_PUBLIC.CAS_URL_LOGIN}?service=${configService.API_ENDPOINT}/gn_auth/login_cas`;
        //   if (!authService.isLoggedIn()) {
        //     // TODO: set the local storage item 'expires_at' in the API route "gn_auth/login_cas"
        //     localStorage.setItem('gn_expires_at', moment().add(1, 'days').toISOString());
        //     document.location.href = url_redirection_cas;
        //   }
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
