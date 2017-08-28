import { Router } from '@angular/router';
import * as firebase from 'firebase';
import { Injectable } from '@angular/core';
import { ToastrService, ToastrConfig } from 'ngx-toastr';

@Injectable()
export class AuthService {
    token: string;
    toastrConfig: ToastrConfig;
    constructor(private router: Router,  private toastrService: ToastrService) {
        this.toastrConfig = {
            positionClass: 'toast-top-center',
            tapToDismiss: true,
            timeOut: 2000
        };
    }
  signinUser(email: string, password: string) {
    firebase.auth().signInWithEmailAndPassword(email, password)
      .then(
        response => {
          this.router.navigate(['/']);
          this.toastrService.success('', 'Login success', this.toastrConfig);
          firebase.auth().currentUser.getIdToken()
            .then(
              (token: string) => this.token = token,
            );
        }
      )
      .catch(
        error => this.toastrService.error('', 'Login failed', this.toastrConfig)
      );
  }

  logout() {
    this.router.navigate(['/']);
    firebase.auth().signOut();
    this.token = null;
  }
    isAuthenticated() {
        return this.token != null;
  }
}
