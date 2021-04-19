import { Injectable } from '@angular/core';
import { DataFormService } from '@geonature_common/form/data-form.service';

import { Observable, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

@Injectable()
export class CruvedStoreService {
  public cruved: any = null;

  constructor(private _api: DataFormService) { }

  fetchCruved(): Observable<any> {
    // Generally errors are 401 because we are not logged-in yet.
    // We should check authentication status before fetching the cruved,
    // but importing the AuthService create a cycle inclusion.
    // This may be solved by adding a dedicated service which do not
    // requires Router or ActivatedRoute.
    // For now, simply ignore all errors…
    return this._api.getCruved().pipe(
        catchError(err => of([])),
        map(cruved => {
            this.cruved = cruved;
            return cruved;
        }),
    );
  }

  clearCruved(): void {
    this.cruved = null;
  }
}
