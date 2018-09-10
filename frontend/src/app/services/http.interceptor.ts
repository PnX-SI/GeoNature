import { Injectable, Injector } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent } from '@angular/common/http';
import { Observable } from 'rxjs/Observable';
import { AuthService } from '@geonature/components/auth/auth.service';
import { Router } from '@angular/router';

@Injectable()
export class MyCustomInterceptor implements HttpInterceptor {
  constructor(public inj: Injector, public router: Router) {}

  private handleError(error: Response | any) {
    console.log(error);
    let errMsg: string;
    if (error instanceof Response) {
      const body = error.json() || '';
      const err = JSON.stringify(body);
      errMsg = `${error.status} - ${error.statusText || ''} ${err}`;
    } else {
      errMsg = error.message ? error.message : error.toString();
    }
    console.error(errMsg);
  }

  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    // Interceptor to redirect to the login page if token is expired
    // also put a withCredentials header
    const auth = this.inj.get(AuthService);
    if (!auth.getToken()) {
      this.router.navigate(['/login']);
    }
    // add a custom header
    const customReq = request.clone({
      withCredentials: true
    });
    // pass on the modified request object
    // and intercept error
    return next.handle(customReq).catch((err: any) => {
      this.handleError(err);
      return Observable.throw(err);
    });
  }
}
