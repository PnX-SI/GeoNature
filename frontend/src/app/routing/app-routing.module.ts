import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { HomeContentComponent } from '../components/home-content/home-content.component';
import { PageNotFoundComponent } from '../components/page-not-found/page-not-found.component';
import { AuthGuard } from '../components/auth/auth-guard.service';
import { LoginComponent } from '../components/login/login.component';
import { NavHomeComponent } from '../components/nav-home/nav-home.component';
import { ExportsComponent } from '../exportsModule/exports.component';
import { AppConfig } from '@geonature_config/app.config';

const defaultRoutes: Routes = [
  { path: 'login', component: LoginComponent },
  // uncomment to activate login
  {
    path: '',
    component: NavHomeComponent,
    canActivateChild: [AuthGuard],
    children: [
      {
        path: 'occtax',
        loadChildren:
          '/home/theo/workspace/GN2/GeoNature/contrib/occtax/frontend/app/gnModule.module#GeonatureModule'
      },

      { path: '', component: HomeContentComponent },
      { path: 'exports', loadChildren: '@geonature/exportsModule/exports.module#ExportsModule' },
      { path: '**', component: PageNotFoundComponent }
    ]
  }
];

export const routing = RouterModule.forRoot(defaultRoutes, { useHash: true });
