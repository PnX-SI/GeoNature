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
import { HttpClient } from '@angular/common/http';

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
    const httpclient = this._injector.get(HttpClient);

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
      } else {
        let data = await httpclient
          .get(`${configService.API_ENDPOINT}/auth/get_current_user`)
          .toPromise();
        data = { ...data };
        authService.manageUser(data);
        const modules = await moduleService.loadModules().toPromise();
        routingService.loadRoutes(modules, route._routerState.url);
        return authService.isLoggedIn();
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
