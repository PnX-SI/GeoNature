import { Router } from '@angular/router';
//import * as firebase from 'firebase';
import { Injectable } from '@angular/core';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { Http } from '@angular/http';
import { AppConfig } from '../../../conf/app.config';
import { CookieService } from 'ng2-cookies';


export class User {
  constructor(
    public userName: string,
    public rigths: any,
    public organism: any,
) {
}
}

@Injectable()
export class AuthService {
    authentified = false;
    currentUser: User;
    token: string;
    toastrConfig: ToastrConfig;
    constructor(private router: Router,  private toastrService: ToastrService, private _http: Http,
    private _cookie: CookieService) {
        this.toastrConfig = {
            positionClass: 'toast-top-center',
            tapToDismiss: true,
            timeOut: 2000
        };
    }

  setCurrentUser(user, expireDate) {
    this._cookie.set('currentUser', user);
  }

  setToken(token) {
    this._cookie.set('token', token);
  }

  fakeSigninUser(username: string, password: string) {
    // call api
    if (username === 'admin') {
      const response = {
        'userName': 'admin',
        'organism': {
          'organism_name': 'PNE',
          'organism_id': 2
        },
        'applications_rigths': [
         {'id_application': 14, 'C': 3, 'R': 3, 'U':3, 'V': 3, 'E': 3, 'D': 3 }
        ]};
        this.currentUser = new User(response.userName, response.applications_rigths, response.organism);
    } else {
      const response = {'userName': 'contributeur',
      'organism': {
        'organism_name': 'IGN',
        'organism_id': 3
      },
      'applications_rigths': [
         {'id_application': 14, 'C': 2, 'R': 1, 'U': 1, 'V': 1, 'E': 1, 'D': 1 }
        ]};
      this.currentUser = new User(response.userName, response.applications_rigths, response.organism);
    }
    this.authentified = true;
    this.router.navigate(['']);
  }

  signinUser(username: string, password: string) {
    this._http.post(`${AppConfig.API_ENDPOINT}/api/auth/login`,
      {'login': username,
       'password': password,
       'id_application': 14
    }).subscribe(response => {
      const data = response.json();
      console.log(data);

      this.setCurrentUser(data.user, data.expires);
      // this.router.navigate(['']);
      // this.toastrService.success('', 'Login success', this.toastrConfig);
      // this.authentified = true;
      // catch error
      //error => this.toastrService.error('', 'Login failed', this.toastrConfig)

    });

  }

  getUserRigths() {
    
  }

  logout() {
    this.router.navigate(['/login']);
    //firebase.auth().signOut();
    // this.token = null;
    this.authentified = false;
  }
    isAuthenticated(): boolean {
        return this.authentified;
  }
}
