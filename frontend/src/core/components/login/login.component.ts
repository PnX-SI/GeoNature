import { Component, OnInit } from '@angular/core';
import { AppConfig } from '../../../conf/app.config';
import { AuthService } from '../auth/auth.service';
import { Router } from '@angular/router';

@Component({
  selector: 'pnx-login',
  templateUrl: 'login.component.html'
})

export class LoginComponent implements OnInit {
  constructor(private _authService: AuthService, private _router: Router) {
    if (AppConfig.CAS_AUTHENTIFICATION) {
      // document.location.href = 'https://inpn.mnhn.fr/auth/login?service=https://geonature.fr ';
    }
   }

    ngOnInit() {

   }
  register(user) {
    this._authService.signinUser(user.username, user.password);
    if (this._authService.isAuthenticated()) {
      this._router.navigate(['']);
    }

  }
}