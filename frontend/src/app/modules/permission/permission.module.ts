import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Routes, RouterModule } from '@angular/router';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';

//Components
import { AccessRequestComponent } from './access-request/access-request.component';
import { AccessRequestConventionComponent } from '../../../custom/components/access-request-convention/access-request-convention.component';
import { BreadcrumbsComponent } from './breadcrumbs/breadcrumbs.component'
import { ConventiondModalContent } from './convention-modal/convention-modal.component'
import { PermissionListComponent } from './permission-list/permission-list.component'
import { PermissionDetailComponent } from './permission-detail/permission-detail.component'
import { RequestListComponent } from './request-list/request-list.component'
import { RequestDetailComponent } from './request-detail/request-detail.component'

//Services
import { PermissionService } from './permission.service';

const routes: Routes = [
  {
    path: '',
    redirectTo: 'roles',
    pathMatch: 'full',
  },
  {
    path: 'roles',
    data: {
      breadcrumb: {
        label: 'Permissions',
        title: 'Liste des permissions par utilisateurs et groupes.',
        iconClass: 'admin_panel_settings',
      },
    },
    children: [
      {
        path: '',
        component: PermissionListComponent,
      },
      {
        path: ':idRole',
        data: {
          breadcrumb: {
            label: 'Rôle: :idRole',
            title: 'Détail des permissions d\'un rôle.',
            iconClass: 'account_circle',
          },
        },
        children: [
          {
            path: '',
            component: PermissionDetailComponent,
          },
        ],
      },
    ],
  },
  {
    path: 'requests',
    data: {
      breadcrumb: {
        label: 'Demandes',
        title: 'Listes des demandes de permissions d\'accès.',
        iconClass: 'admin_panel_settings',
      },
    },
    children: [
      {
        path: '',
        component: RequestListComponent,
      },
      {
        path: 'add',
        component: AccessRequestComponent,
      },
      {
        path: ':requestToken',
        data: {
          breadcrumb: {
            label: 'Demande: :requestToken',
            title: 'Détail d\'une demande de permissions d\'accès.',
            iconClass: 'check_circle',
          },
        },
        children: [
          {
            path: '',
            component: RequestDetailComponent,
          },
        ],
      },
    ],
  },
];

@NgModule({
  imports: [
    RouterModule.forChild(routes),
    GN2CommonModule,
    CommonModule,
  ],
  declarations: [
    AccessRequestComponent,
    AccessRequestConventionComponent,
    BreadcrumbsComponent,
    ConventiondModalContent,
    PermissionDetailComponent,
    PermissionListComponent,
    RequestDetailComponent,
    RequestListComponent,
  ],
  providers: [
    PermissionService,
  ],
  entryComponents: [
    ConventiondModalContent
  ],
})
export class PermissionModule {}
