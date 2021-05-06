import { Injectable } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent, HttpErrorResponse } from '@angular/common/http';
import { Observable } from 'rxjs';
import 'rxjs/add/operator/catch';
import 'rxjs/add/observable/empty';

@Injectable()
export class UnauthorizedInterceptor implements HttpInterceptor {
    constructor(
        private router: Router,
        private route: ActivatedRoute,
    ) {}

    intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
        return next.handle(request).catch((err: any) => {
            if (err instanceof HttpErrorResponse
                    && err.status === 401
                    && this.router.url != '/') {
                this.router.navigate(['/login'], { // TODO: put in config!
                    queryParams: { route: this.router.url, }
                });

                // this response is handled
                // stop the chain of handlers by returning empty
                return Observable.empty();
            }

            // rethrow so other error handlers may pick this up
            return Observable.throw(err);
        });
    }
}
