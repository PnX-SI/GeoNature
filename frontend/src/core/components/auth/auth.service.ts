import { Router } from '@angular/router';
//import * as firebase from 'firebase';
import { Injectable } from '@angular/core';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { HttpClient } from '@angular/common/http';import { AppConfig } from '../../../conf/app.config';
import { CookieService } from 'ng2-cookies';
import { Location } from '@angular/common';


export class User {

  constructor(public userName: string, public rights: any, public organism: any) {
    this.userName = userName;
    this.rights = rights;
    this.organism = organism;
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
    console.log(user);
    user = user.split("'").join('"');
    console.log(user);
    user = JSON.parse(user);
    console.log(user);
    user = new User(user['userName'], user['rights'], user['organism']);
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
        'organism': {
          'organismName': 'PNE',
          'organismId': 2
        },
        'rights': {
          '14' : {'C': 3, 'R': 3, 'U': 3, 'V': 3, 'E': 3, 'D': 3 }
          }
        };

    } else {
       response = {
         'userName': 'contributeur',
          'organism': {
            'organismName': 'PNF',
            'organismId': 1
          },
      'rights': {
         '14' : {'C': 2, 'R': 1, 'U': 1, 'V': 1, 'E': 1, 'D': 1 }
        }
      };
    }
    this.setCurrentUser(response, d2);
    this.setToken('1123345254', d2);
    this.getCurrentUser();
    this.router.navigate(['']);
  }

  signinUser(username: string, password: string) {
    this._http.post<any>(`${AppConfig.API_ENDPOINT}/api/auth/login`,
      {'login': username,
       'password': password,
       'id_application': 14
    }).subscribe(data => {
      this.setCurrentUser(data.user, data.expires);
    });

  }
  logout() {
    this.router.navigate(['/login']);
    this._cookie.delete('token');
    if (AppConfig.CAS.CAS_AUTHENTIFICATION) {
      this._http.get(AppConfig.CAS.CAS_LOGOUT_URL)
        .subscribe(data => {
          console.log(data);
        });
    }
  }

  isAuthenticated(): boolean {
      return this._cookie.get('token') !== null;
  }

}
