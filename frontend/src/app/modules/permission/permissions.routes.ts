import { Routes } from '@angular/router';

// Module components
import { PermissionDetailComponent } from './permission-detail/permission-detail.component';
import { PermissionListComponent } from "./permission-list/permission-list.component";

export const routes: Routes = [
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
];
