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
import { PermissionListComponent } from './permission-list/permission-list.component'
import { PermissionDetailComponent } from './permission-detail/permission-detail.component'
import { ProcessedRequestListComponent } from './request-list/processed-request-list/processed-request-list.component'
import { RequestListComponent } from './request-list/request-list.component'
import { RequestDetailComponent } from './request-detail/request-detail.component'

// Services
import { routes } from './permissions.routes'
import { PermissionService } from './permission.service';


@NgModule({
  imports: [
    RouterModule.forChild(routes),
    GN2CommonModule,
    CommonModule,
  ],
  declarations: [
    AccessRequestComponent,
    AccessRequestConventionComponent,
    ConventiondModalContent,
    PendingRequestListComponent,
    PermissionDetailComponent,
    PermissionListComponent,
    ProcessedRequestListComponent,
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
