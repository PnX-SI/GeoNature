import { NgModule } from '@angular/core';
import { RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';

import { GN2CommonModule } from '@geonature_common/GN2Common.module';

import { LoginComponent } from './login/login.component';
import { NewPasswordComponent } from './new-password/new-password.component';
import { SignUpComponent } from './sign-up/sign-up.component';

import { routes } from './login.routes';
import { SignUpGuard, UserEditGuard, UserManagementGuard } from './routes-guard.service';
import { LoginDialog } from './login/external-login-dialog';

@NgModule({
  imports: [CommonModule, GN2CommonModule, RouterModule.forChild(routes)],
  declarations: [LoginComponent, NewPasswordComponent, SignUpComponent, LoginDialog],
  providers: [SignUpGuard, UserManagementGuard, UserEditGuard],
})
export class LoginModule {}
