import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

// GeoNature
import { GN2CommonModule } from '@geonature_common/GN2Common.module';

// Components
import { PermissionDetailComponent } from './permission-detail/permission-detail.component'
import { PermissionListComponent } from './permission-list/permission-list.component'


// Dialog
import { DeletePermissionDialog } from './permission-detail/delete-permission-dialog/delete-permission-dialog.component';
import { EditPermissionModal } from './permission-detail/edit-permission-modal/edit-permission-modal.component';

// Services
import { PermissionService } from './permission.service';
import { routes } from './permissions.routes'

@NgModule({
  imports: [
    RouterModule.forChild(routes),
    GN2CommonModule,
    CommonModule,
  ],
  declarations: [
    DeletePermissionDialog,
    EditPermissionModal,
    PermissionDetailComponent,
    PermissionListComponent,
  ],
  providers: [
    PermissionService
  ],
  entryComponents: [
    DeletePermissionDialog,
    EditPermissionModal,
  ],
})
export class PermissionModule {}
