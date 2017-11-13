import { Router } from '@angular/router';
//import * as firebase from 'firebase';
import { Injectable } from '@angular/core';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { Http } from '@angular/http';
import { AppConfig } from '../../../conf/app.config';
import { CookieService } from 'ng2-cookies';
import { Location } from '@angular/common';


export class User {

  constructor(public userName: string, public rights: Array<any>, public organism: any) {
    this.userName = userName;
    this.rights = rights;
    this.organism = organism;
}

  getRight(idApplication) {
    return this.rights.find(obj => obj.idApplication = idApplication);
  }
}

@Injectable()
export class AuthService {
    authentified = false;
    currentUser: User;
    token: string;
    toastrConfig: ToastrConfig;
    constructor(private router: Router,  private toastrService: ToastrService, private _http: Http,
    private _cookie: CookieService, private _location: Location) {
      console.log('init auth service');
      
      _location.subscribe(val => {
          console.log('location change');
          console.log(val);
        });
    }

  setCurrentUser(user, expireDate) {
    this._cookie.set('currentUser', JSON.stringify(user), expireDate);
  }

  getCurrentUser(): User {
    const userString =  this._cookie.get('currentUser');
    let user =  <User>JSON.parse(userString);

    user = new User(user.userName, user.rights, user.organism);
    return user;
  }

  setToken(token, expireDate) {
    this._cookie.set('token', token, expireDate);
  }

  getToken() {
    const token = this._cookie.get('token');
    const response = token.length === 0 ? null : token;
    return response;
  }

  fakeSigninUser(username: string, password: string) {
    const d1 = new Date();
    const d2 = new Date(d1);
    d2.setMinutes(d1.getMinutes() + 60);
    let response;
    if (username === 'admin') {
       response = {
        'userName': 'admin',
        'organism': {
          'organismName': 'PNE',
          'organismId': 2
        },
        'rights': [
         {'idApplication': 14, 'C': 3, 'R': 3, 'U': 3, 'V': 3, 'E': 3, 'D': 3 }
        ]};

    } else {
       response = {'userName': 'contributeur',
      'organism': {
        'organismName': 'PNF',
        'organismId': 1
      },
      'rights': [
         {'idApplication': 14, 'C': 2, 'R': 1, 'U': 1, 'V': 1, 'E': 1, 'D': 1 }
        ]};

    }
    this.setCurrentUser(response, d2);
    this.setToken('1123345254', d2);
    this.getCurrentUser();
    this.router.navigate(['']);
  }

  signinUser(username: string, password: string) {
    this._http.post(`${AppConfig.API_ENDPOINT}/api/auth/login`,
      {'login': username,
       'password': password,
       'id_application': 14
    }).subscribe(response => {
      const data = response.json();
      this.setCurrentUser(data.user, data.expires);
    });

  }
  logout() {
    this.router.navigate(['/login']);
    this._cookie.delete('token');
  }
  isAuthenticated(): boolean {
      return this._cookie.get('token') !== null;
  }

}
