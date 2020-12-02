import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

// GeoNature
import { GN2CommonModule } from '@geonature_common/GN2Common.module';

// Components
import { AccessRequestComponent } from './access-request/access-request.component';
import { AccessRequestConventionComponent } from '../../../custom/components/access-request-convention/access-request-convention.component';
import { ConventiondModalContent } from './convention-modal/convention-modal.component'
import { PendingRequestListComponent } from './request-list/pending-request-list/pending-request-list.component'
import { PermissionDetailComponent } from './permission-detail/permission-detail.component'
import { PermissionListComponent } from './permission-list/permission-list.component'
import { ProcessedRequestListComponent } from './request-list/processed-request-list/processed-request-list.component'
import { RequestDetailComponent } from './request-detail/request-detail.component'
import { RequestDisplayComponent } from './request-display/request-display.component';
import { RequestListComponent } from './request-list/request-list.component'

// Dialog
import { AcceptRequestDialog } from './shared/accept-request-dialog/accept-request-dialog.component';
import { PendingRequestDialog } from './shared/pending-request-dialog/pending-request-dialog.component';
import { RefusalRequestDialog } from './shared/refusal-request-dialog/refusal-request-dialog.component';

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
    AcceptRequestDialog,
    AccessRequestComponent,
    AccessRequestConventionComponent,
    ConventiondModalContent,
    PendingRequestDialog,
    PendingRequestListComponent,
    PermissionDetailComponent,
    PermissionListComponent,
    ProcessedRequestListComponent,
    RefusalRequestDialog,
    RequestDetailComponent,
    RequestDisplayComponent,
    RequestListComponent,
  ],
  providers: [
    PermissionService,
  ],
  entryComponents: [
    AcceptRequestDialog,
    ConventiondModalContent,
    PendingRequestDialog,
    RefusalRequestDialog,
  ],
})
export class PermissionModule {}
