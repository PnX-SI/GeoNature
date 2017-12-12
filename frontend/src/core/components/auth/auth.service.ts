import { Router } from '@angular/router';
//import * as firebase from 'firebase';
import { Injectable } from '@angular/core';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { HttpClient } from '@angular/common/http';
import { AppConfig } from '../../../conf/app.config';
import { CookieService } from 'ng2-cookies';
import { Location } from '@angular/common';


export class User {

  constructor(public userName: string, public userId: number, public organismId: number,  public rights: any) {
    this.userName = userName;
    this.userId = userId;
    this.organismId = organismId;
    this.rights = rights;
}

  getRight(idApplication) {
    return this.rights[idApplication];
  }
}

@Injectable()
export class AuthService {
    authentified = false;
    currentUser: User;
    token: string;
    toastrConfig: ToastrConfig;
    loginError: boolean;
    constructor(private router: Router,  private toastrService: ToastrService, private _http: HttpClient,
    private _cookie: CookieService, private _router: Router) {
    }

  decodeObjectCookies(val) {
      if (val.indexOf('\\') === -1) {
          return val;  // not encoded
      }
      val = val.slice(1, -1).replace(/\\"/g, '"');
      val = val.replace(/\\(\d{3})/g, function(match, octal) {
          return String.fromCharCode(parseInt(octal, 8));
      });
      return val.replace(/\\\\/g, '\\');
  }
  setCurrentUser(user, expireDate) {
    this._cookie.set('currentUser', JSON.stringify(user), expireDate);
  }

  getCurrentUser(): User {
    const userString =  this._cookie.get('currentUser');
    let user = this.decodeObjectCookies(userString);
    user = user.split("'").join('"');
    user = JSON.parse(user);
    user = new User(user.userName, user.userId, user.organismId, user.rights);
    console.log(user);
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
        'userId': 2,
        'organismId': 2,
        'rights': {
          '14' : {'C': 3, 'R': 3, 'U': 3, 'V': 3, 'E': 3, 'D': 3 }
          }
        };

    } else {
       response = {
         'userName': 'contributeur',
         'userId': 6,
          'organismId': 1,
        'rights': {
          '14' : {'C': 2, 'R': 1, 'U': 1, 'V': 1, 'E': 1, 'D': 1 }
        }
      };
    }
    this.setCurrentUser(response, d2);
    this.setToken('1123345254', d2);
    this.router.navigate(['']);
  }


  signinUser(username: string, password: string) {
    const user = {
    'login': username,
    'password': password,
    'id_application': AppConfig.ID_APPLICATION_GEONATURE,
    'with_cruved': true
    };
    this._http.post<any>(`${AppConfig.API_ENDPOINT}auth/login`, user)
      .subscribe(data => {
      console.log(data);
      const userForFront = {
        userName : data.user.identifiant,
        userId : data.user.id_role,
        organismId:  data.user.id_organisme,
        rights : data.user.rights
      };
      this.setCurrentUser(userForFront, new Date(data.expires));
      this.loginError = false;
      this.router.navigate(['']);
    },
    error => {
      this.loginError = true;
    });

  }


deleteTokenCookie() {
  document.cookie = 'token=; path=/; expires' + new Date(0).toUTCString();
}
  logout() {
    this._cookie.delete('token', '/');
    if (AppConfig.CAS.CAS_AUTHENTIFICATION) {
      this.deleteTokenCookie();
      document.location.href = AppConfig.CAS.CAS_LOGOUT_URL;
    } else {
      this.router.navigate(['/login']);
    }
  }

  isAuthenticated(): boolean {
      return this._cookie.get('token') !== null;
  }

}
