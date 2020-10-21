import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Routes, RouterModule } from '@angular/router';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';

//Components
import { AccessRequestComponent } from './access-request/access-request.component';
import { AccessRequestConventionComponent } from '../../../custom/components/access-request-convention/access-request-convention.component';
import { ConventiondModalContent } from './convention-modal/convention-modal.component'

//Services
import { PermissionService } from './permission.service';

const routes: Routes = [
  { path: 'access-request', component: AccessRequestComponent },
];

@NgModule({
  imports: [
    RouterModule.forChild(routes),
    GN2CommonModule,
    CommonModule,
  ],
  declarations: [
    AccessRequestConventionComponent,
    ConventiondModalContent,
    AccessRequestComponent,
  ],
  providers: [
    PermissionService,
  ],
  entryComponents: [
    ConventiondModalContent
  ],
})
export class PermissionModule {}
