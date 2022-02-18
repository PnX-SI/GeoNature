import { Injectable } from '@angular/core';

import { Routes, Router } from '@angular/router';
import { ConfigService } from './config.service'
import { ModuleService } from './module.service'

import { LoginComponent } from '../components/login/login.component';
import { NewPasswordComponent } from '../components/new-password/new-password.component'
import { SignUpComponent } from '../components/sign-up/sign-up.component';
import { UserManagementGuard } from '@geonature/routing/routes-guards.service';
import { NavHomeComponent } from '../components/nav-home/nav-home.component';
import { PageNotFoundComponent } from '../components/page-not-found/page-not-found.component';
import { HomeContentComponent } from '../components/home-content/home-content.component';

import { SignUpGuard } from '@geonature/routing/routes-guards.service';
import { AuthGuard, ModuleGuardService } from '@geonature/routing/routes-guards.service';

import externalModules from '../../../../external_modules'

@Injectable()
export class RoutingService {
  constructor(
    private _configService: ConfigService,
    private _moduleService: ModuleService,
    private _router: Router,
  ) {};

  init() {
    this._router.resetConfig(this.getRoutes());
    console.log(this.getRoutes())
    this._router.navigateByUrl(this._router.url);
    // reload route
  }

  getRoutes(): Routes {
    const routes: Routes = [];

    // definitions

    const login = {
      path: 'login',
      component: LoginComponent,
    };

    const signUp = {
      path: 'inscription',
      component: SignUpComponent,
      canActivate: [SignUpGuard],
    };

    const newPassword = {
      path: 'new-password',
      component: NewPasswordComponent,
      canActivate: [UserManagementGuard],
    };

    const sideBar = {
      path: '',
      component: NavHomeComponent,
      canActivateChild: [AuthGuard],
      children: this.getSideBarRoutes()
    }

    const notFound = {
      path: '**',
      component: PageNotFoundComponent,
    };

    // set routes

    routes.push(login);

    if (this._configService.config?.ACCOUNT_MANAGEMENT?.ENABLE_SIGN_UP) {
      routes.push(signUp);
    }

    if (this._configService.config?.ACCOUNT_MANAGEMENT?.ENABLE_USER_MANAGEMENT) {
      routes.push(newPassword);
    }

    routes.push(sideBar);
    routes.push(notFound);
    return routes;
  }

  getSideBarRoutes(): Routes {
    const sideBarRoutes:Routes = []

    const home = {
      path: '',
      component: HomeContentComponent,
    };

    const synthese = {
      path: 'synthese',
      data: { module_code: 'synthese' },
      canActivate: [ModuleGuardService],
      loadChildren: () => import('@geonature/syntheseModule/synthese.module').then(m => m.SyntheseModule)
    };

    const metadata = {
      path: 'metadata',
      data: { module_code: 'metadata' },
      canActivate: [ModuleGuardService],
      loadChildren: () => import('@geonature/metadataModule/metadata.module').then(m => m.MetadataModule)
    };

    const admin = {
      path: 'admin',
      data: { module_code: 'admin' },
      loadChildren: () => import('@geonature/adminModule/admin.module').then(m => m.AdminModule),
      canActivate: [ModuleGuardService],
    }

    const user = {
      path: 'user',
      data: { module_code: 'user' },
      loadChildren: () => import('@geonature/userModule/user.module').then(m => m.UserModule),
    };

    sideBarRoutes.push(home);
    sideBarRoutes.push(synthese);
    sideBarRoutes.push(metadata);
    sideBarRoutes.push(admin);

    if(this._configService.config?.ACCOUNT_MANAGEMENT?.ENABLE_USER_MANAGEMENT) {
      sideBarRoutes.push(user)
    }

    for (const externalModule of this.getExternalModules()) {
      sideBarRoutes.push(externalModule)
    }

    return sideBarRoutes;
  }

  getExternalModules():Routes {
    const modules: Routes = [];
    for  (const [moduleCode, moduleComponent] of Object.entries(externalModules)) {
      const module = this._moduleService.getModule(moduleCode)
      if (!module) {
        continue;
      }
      modules.push({
        path: module.module_path,
        loadChildren: () => moduleComponent,
        canActivate: [ModuleGuardService],
        data: {
          module_code: moduleCode
        }
      })
    }
    return modules;
  }
}
