import { throwError as observableThrowError, Observable } from 'rxjs';
import { Injectable, Injector } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent } from '@angular/common/http';
import { AuthService } from '@geonature/components/auth/auth.service';
import { ToastrService } from 'ngx-toastr';
import { Router } from '@angular/router';

const WHITE_LIST = ['nominatim.openstreetmap.org'];

@Injectable()
export class MyCustomInterceptor implements HttpInterceptor {
  constructor(public inj: Injector, public router: Router, private _toastrService: ToastrService) {}

  private handleError(error: Response | any) {
    let errMsg: string;
    let errName: string;
    if (error.status !== 404) {
      if (error instanceof Response || error['error']) {
        errMsg = `${error.status} - ${error.statusText || ''} ${error['error'].description}
        id requete: ${error['error'].request_id}`;
        errName = error['error'].name;
      } else {
        errMsg = error.message ? error.message : error.toString();
        errName = 'Une erreur est survenue';
      }
      this._toastrService.error(errMsg, errName, { timeOut: 6000 });
    }
  }

  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    // add a custom header
    const customReq = request.clone({
      withCredentials: true,
    });

    //Creation d'une liste blanche pour autoriser les CROS request.
    if (WHITE_LIST.indexOf(this.extractHostname(request.url)) === -1) {
      // add a custom header
      request = request.clone({
        withCredentials: true,
      });
    }

    // pass on the modified request object
    // and intercept error
    return next.handle(request).catch((err: any) => {
      this.handleError(err);
      return observableThrowError(err);
    });
  }

  private extractHostname(url) {
    var hostname;
    //find & remove protocol (http, ftp, etc.) and get hostname

    if (url.indexOf('//') > -1) {
      hostname = url.split('/')[2];
    } else {
      hostname = url.split('/')[0];
    }

    //find & remove port number
    hostname = hostname.split(':')[0];
    //find & remove "?"
    hostname = hostname.split('?')[0];

    return hostname;
  }
}
