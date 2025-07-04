import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Routes, RouterModule } from '@angular/router';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
//Components
import { UserComponent } from './user.component';
import { PasswordComponent } from './password/password.component';
//Services
import { RoleFormService, UserDataService } from './services';
import { UserEditGuard, UserManagementGuard } from '@geonature/modules/login/routes-guard.service';

const routes: Routes = [
  { path: '', component: UserComponent, canActivate: [UserEditGuard,UserManagementGuard] },
  { path: 'password', component: PasswordComponent, canActivate: [UserEditGuard,UserManagementGuard] },
];

@NgModule({
  imports: [RouterModule.forChild(routes), GN2CommonModule, CommonModule],
  declarations: [UserComponent, PasswordComponent],
  providers: [UserDataService, RoleFormService],
})
export class UserModule {}
