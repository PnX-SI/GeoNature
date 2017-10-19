import { Router } from '@angular/router';
import * as firebase from 'firebase';
import { Injectable } from '@angular/core';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { Http } from '@angular/http';


export interface User {
  userName: string;
  rights: Array<any>;
  organism: string;
}

@Injectable()
export class AuthService {
    currentUser: User;
    token: string;
    toastrConfig: ToastrConfig;
    constructor(private router: Router,  private toastrService: ToastrService, private _http: Http) {
        this.toastrConfig = {
            positionClass: 'toast-top-center',
            tapToDismiss: true,
            timeOut: 2000
        };
    }

  signinUser(username: string, password: string) {
    this._http.post('/login',
      {'username': username,
       'password': password
    }).map (response => {
      const json = response.json();
      this.currentUser = <User>({
        userName : json.username,
        rights: json.rigths,
        organism : json.organism
      });
    });
    // firebase.auth().signInWithEmailAndPassword(email, password)
    //   .then(
    //     response => {
    //       this.router.navigate(['/']);
    //       this.toastrService.success('', 'Login success', this.toastrConfig);
    //       firebase.auth().currentUser.getIdToken()
    //         .then(
    //           (token: string) => this.token = token,
    //         );
    //     }
    //   )
    //   .catch(
    //     error => this.toastrService.error('', 'Login failed', this.toastrConfig)
    //   );

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
