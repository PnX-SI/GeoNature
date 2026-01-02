import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Routes, RouterModule } from '@angular/router';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
//Components
import { UserComponent } from './user.component';
import { PasswordComponent } from './password/password.component';
import { ChangeMailAddressComponent } from './mail-address/change-mail-address.component';
//Services
import { RoleFormService, UserDataService } from './services';
import { UserEditGuard, UserManagementGuard } from '@geonature/modules/login/routes-guard.service';
import { ValidateMailAddressChangeComponent } from '@geonature/userModule/mail-address/validate-mail-adress-change.component';

const routes: Routes = [
  { path: '', component: UserComponent, canActivate: [UserEditGuard, UserManagementGuard] },
  {
    path: 'password',
    component: PasswordComponent,
    canActivate: [UserEditGuard, UserManagementGuard],
  },
  {
    path: 'mail_address',
    component: ChangeMailAddressComponent,
    canActivate: [UserEditGuard, UserManagementGuard],
  },
  {
    path: 'new-mail',
    component: ValidateMailAddressChangeComponent,
    canActivate: [UserEditGuard, UserManagementGuard],
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes), GN2CommonModule, CommonModule],
  declarations: [
    UserComponent,
    PasswordComponent,
    ChangeMailAddressComponent,
    ValidateMailAddressChangeComponent,
  ],
  providers: [UserDataService, RoleFormService],
})
export class UserModule {}
