import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Routes, RouterModule } from '@angular/router';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
//Components
import { UserComponent } from './user.component';
import { PasswordComponent } from './password/password.component';
//Services
import { RoleFormService, UserDataService } from './services';

const routes: Routes = [
  { path: '', component: UserComponent },
  { path: 'password', component: PasswordComponent }
];

@NgModule({
  imports: [RouterModule.forChild(routes), GN2CommonModule, CommonModule],
  declarations: [UserComponent, PasswordComponent],
  providers: [UserDataService, RoleFormService]
})
export class UserModule {}
