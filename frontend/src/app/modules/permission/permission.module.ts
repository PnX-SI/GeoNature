import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Routes, RouterModule } from '@angular/router';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';

//Components
import { AccessRequestComponent } from './access-request/access-request.component';

//Services
//import { RoleFormService, UserDataService } from './services';

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
    AccessRequestComponent,
  ],
  providers: []
})
export class PermissionModule {}
