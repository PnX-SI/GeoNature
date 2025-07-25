import { Routes, RouterModule } from '@angular/router';

import { HomeContentComponent } from '../components/home-content/home-content.component';
import { PageNotFoundComponent } from '../components/page-not-found/page-not-found.component';
import { AuthGuard } from '@geonature/routing/auth-guard.service';
import { ModuleGuardService } from '@geonature/routing/module-guard.service';
import { SignUpGuard, UserPublicGuard } from '@geonature/modules/login/routes-guard.service';
import { SignUpComponent } from '../modules/login/sign-up/sign-up.component';

import { UserManagementGuard } from '@geonature/modules/login/routes-guard.service';
import { NewPasswordComponent } from '../modules/login/new-password/new-password.component';

import { LoginComponent } from '../modules/login/login/login.component';
import { NavHomeComponent } from '../components/nav-home/nav-home.component';
import { NotificationComponent } from '../components/notification/notification.component';
import { RulesComponent } from '../components/notification/rules/rules.component';

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
    canActivate: [],
    canActivateChild: [AuthGuard],
    children: [
      {
        path: '',
        component: HomeContentComponent,
      },
      {
        path: 'synthese',
        data: { module_code: 'synthese', module_label: 'Synthèse' },
        canActivate: [ModuleGuardService],
        loadChildren: () =>
          import(
            /* webpackChunkName: "synthese" */
            '@geonature/syntheseModule/synthese.module'
          ).then((m) => m.SyntheseModule),
      },
      {
        path: 'metadata',
        data: { module_code: 'metadata', module_label: 'Metadonnées' },
        canActivate: [ModuleGuardService],
        loadChildren: () =>
          import(
            /* webpackChunkName: "metadata" */
            '@geonature/metadataModule/metadata.module'
          ).then((m) => m.MetadataModule),
      },
      {
        path: 'user',
        data: { module_code: 'user', module_label: 'Utilisateur' },
        loadChildren: () =>
          import(
            /* webpackChunkName: "user" */
            '@geonature/userModule/user.module'
          ).then((m) => m.UserModule),
        canActivate: [UserPublicGuard],
      },
      {
        path: 'import',
        data: { module_code: 'import', module_label: 'Import' },
        canActivate: [ModuleGuardService],
        loadChildren: () =>
          import(
            /* webpackChunkName: "imports" */
            '@geonature/modules/imports/imports.module'
          ).then((m) => m.ImportsModule),
      },
      {
        path: 'notification',
        data: { module_label: 'Notifications' },
        component: NotificationComponent,
      },
      {
        path: 'notification/rules',
        component: RulesComponent,
      },
      {
        path: '**',
        component: PageNotFoundComponent,
      },
    ],
  },
];

export const routing = RouterModule.forRoot(defaultRoutes, {
  useHash: true,
  paramsInheritanceStrategy: 'always',
});
