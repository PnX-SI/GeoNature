import { Routes, RouterModule } from '@angular/router';

import { HomeContentComponent } from '../components/home-content/home-content.component';
import { PageNotFoundComponent } from '../components/page-not-found/page-not-found.component';
import { AuthGuard } from '@geonature/routing/auth-guard.service';
import { ModuleGuardService } from '@geonature/routing/module-guard.service';
import { SignUpGuard } from '@geonature/modules/login/routes-guard.service';
import { SignUpComponent } from '../modules/login/sign-up/sign-up.component';

import { UserManagementGuard } from '@geonature/modules/login/routes-guard.service';
import { NewPasswordComponent } from '../modules/login/new-password/new-password.component';

import { LoginComponent } from '../modules/login/login/login.component';
import { NavHomeComponent } from '../components/nav-home/nav-home.component';

const defaultRoutes: Routes = [
  {
    path: 'login',
    component: LoginComponent,
  },

  {
    path: 'inscription',
    component: SignUpComponent,
    canActivate: [SignUpGuard],
  },

  {
    path: 'new-password',
    component: NewPasswordComponent,
    canActivate: [UserManagementGuard],
  },

  {
    path: '',
    component: NavHomeComponent,
    canActivateChild: [AuthGuard],
    children: [
      {
        path: '',
        component: HomeContentComponent,
      },
      {
        path: 'synthese',
        data: { module_code: 'synthese' },
        canActivate: [ModuleGuardService],
        loadChildren: () =>
          import(
            /* webpackChunkName: "synthese" */
            '@geonature/syntheseModule/synthese.module'
          ).then((m) => m.SyntheseModule),
      },
      {
        path: 'metadata',
        data: { module_code: 'metadata' },
        canActivate: [ModuleGuardService],
        loadChildren: () =>
          import(
            /* webpackChunkName: "metadata" */
            '@geonature/metadataModule/metadata.module'
          ).then((m) => m.MetadataModule),
      },
      {
        path: 'admin',
        data: { module_code: 'admin' },
        loadChildren: () =>
          import(
            /* webpackChunkName: "admin" */
            '@geonature/adminModule/admin.module'
          ).then((m) => m.AdminModule),
        canActivate: [ModuleGuardService],
      },

      {
        path: 'user',
        data: { module_code: 'user' },
        loadChildren: () =>
          import(
            /* webpackChunkName: "user" */
            '@geonature/userModule/user.module'
          ).then((m) => m.UserModule),
      },
      {
        path: '**',
        component: PageNotFoundComponent,
      },
    ],
  },
];

export const routing = RouterModule.forRoot(defaultRoutes, { useHash: true });
