import { Routes } from '@angular/router';

import { LoginComponent } from './login/login.component';
import { NewPasswordComponent } from './new-password/new-password.component';
import { SignUpComponent } from './sign-up/sign-up.component';
import { SignUpGuard, UserManagementGuard } from './routes-guard.service';

export const routes: Routes = [
  {
    path: 'login',
    component: LoginComponent,
  },
  {
    path: 'login/inscription',
    component: SignUpComponent,
    canActivate: [SignUpGuard], // enable_sign_up
  },
  {
    path: 'login/new-password',
    component: NewPasswordComponent,
    canActivate: [UserManagementGuard], // enable_user_management
  },
];
