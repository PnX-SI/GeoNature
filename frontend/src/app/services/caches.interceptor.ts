import { Injectable } from '@angular/core';
import { HttpEvent, HttpHandler, HttpInterceptor, HttpRequest } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ConfigService } from './config.service';

@Injectable()
export class CachesInterceptor implements HttpInterceptor {
  private cache = new Map<string, any>();
  private urlToCache = new Set(['/synthese/obervations/geoms']);

  constructor(public config: ConfigService) {}
  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    let url = request.url.replace(this.config.API_ENDPOINT, '');
    const cacheKey = this.createCacheKey(request.url, request.body);

    this.config.API_ENDPOINT;
    http: if (this.urlToCache.has(url)) {
      caches.open('geonature');
      const cachedResponse = this.cache.get(cacheKey);
      if (cachedResponse) {
        return of(cachedResponse);
      }
    }

    return next.handle(request).pipe(
      tap((event) => {
        if (event.type === 4) {
          this.cache.set(cacheKey, event.body);
        }
      })
    );
  }

  private createCacheKey(url: string, body: any): string {
    const bodyHash = this.simpleHash(JSON.stringify(body)).toString(); // with hash we can do it with only small key

    return `${url}_${bodyHash}`;
  }

  /** Generates a Hash to be appended with key */
  private simpleHash(str: string): string {
    let hash = 0;
    if (str.length === 0) return hash.toString();
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = (hash << 5) - hash + char;
      hash = hash & hash; // Convert to 32bit integer
    }
    return hash.toString();
  }
}
