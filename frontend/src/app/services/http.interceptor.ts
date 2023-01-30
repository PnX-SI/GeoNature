import { throwError, Observable } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { Injectable, Injector } from '@angular/core';
import {
  HttpInterceptor,
  HttpRequest,
  HttpHandler,
  HttpEvent,
  HttpErrorResponse,
} from '@angular/common/http';
import { ToastrService } from 'ngx-toastr';
import { Router } from '@angular/router';
import { ConfigService } from './config.service';

@Injectable()
export class MyCustomInterceptor implements HttpInterceptor {
  constructor(
    public inj: Injector,
    public router: Router,
    private _toastrService: ToastrService,
    public config: ConfigService
  ) {}

  private handleError(error: any) {
    let errTitle: string;
    let errMsg: string;
    let enableHtml: boolean = false;
    if (error instanceof HttpErrorResponse) {
      if ([401, 404].includes(error.status)) return;
      if (
        typeof error.error === 'object' &&
        'name' in error.error &&
        'description' in error.error
      ) {
        errTitle = error.error.name;
        errMsg = error.error.description;
        enableHtml = true;
        if ('request_id' in error.error) {
          errMsg += `<br><b>Requête :</b> ${error.error.request_id}`;
        }
      } else {
        errTitle = error.name;
        errMsg = error.message;
      }
    } else {
      errTitle = 'Erreur';
      errMsg = 'Une erreur inconnue est survenue.';
    }
    this._toastrService.error(errMsg, errTitle, {
      disableTimeOut: true,
      tapToDismiss: false,
      closeButton: true,
      easeTime: 0,
      enableHtml: enableHtml,
    });
  }

  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    // set withCredential = true to send and accept cookie from the API
    if (
      this.config.API_ENDPOINT &&
      this.extractHostname(this.config.API_ENDPOINT) == this.extractHostname(request.url)
    ) {
      request = request.clone({
        withCredentials: true,
      });
    }

    // pass on the modified request object
    // and intercept error
    return next.handle(request).pipe(
      catchError((err) => {
        this.handleError(err);
        return throwError(err);
      })
    );
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
