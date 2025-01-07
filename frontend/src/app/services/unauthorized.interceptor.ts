import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import {
  HttpInterceptor,
  HttpRequest,
  HttpHandler,
  HttpEvent,
  HttpErrorResponse,
} from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import 'rxjs/add/operator/catch';
import 'rxjs/add/observable/empty';
import { replace } from '@librairies/cypress/types/lodash';

@Injectable()
export class UnauthorizedInterceptor implements HttpInterceptor {
  constructor(private router: Router) {}

  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    return next.handle(request).catch((err: any) => {
      if (err instanceof HttpErrorResponse && err.status === 401) {
        // Do not redirect if the url contain login
        // recovery password and inscriptio nare under 'login' prefix
        if (!document.location.href.includes('/login')) {
          this.router.navigate(['/login'], {
            queryParams: { next: document.location.href },
            replaceUrl: true,
            queryParamsHandling: 'merge',
          });
        }
      }

      // rethrow so other error handlers may pick this up
      return throwError(err);
    });
  }
}
