import { Injectable } from '@angular/core';
import { Observable, combineLatest, BehaviorSubject, of } from 'rxjs';
import { catchError, map, filter, switchMap } from 'rxjs/operators';

import { OcctaxFormService } from '../occtax-form.service';

@Injectable()
export class OcctaxFormCountingsService {
  public countings: any[];
  public additionalFields: BehaviorSubject<any[]> = new BehaviorSubject([]);

  private $_globalAdditionalFields: Observable<any[]>;
  private $_datasetAdditionalFields: Observable<any[]>;

  constructor(private occtaxFormService: OcctaxFormService) {
    this.setObservable();
  }

  setObservable() {
    /**
     * Get global addtional fields
     */
    this.$_globalAdditionalFields = this.occtaxFormService
      .getAdditionnalFields(['OCCTAX_DENOMBREMENT'])
      .pipe(catchError(() => of([])));

    /**
     * Observe dataset to get dataset's addtional fields
     */
    this.$_datasetAdditionalFields = this.occtaxFormService.occtaxData.asObservable().pipe(
      map((data) => (((data || {}).releve || {}).properties || {}).id_dataset),
      filter((id_dataset) => id_dataset !== undefined && id_dataset !== null),
      switchMap((id_dataset): Observable<any[]> => {
        return this.occtaxFormService
          .getAdditionnalFields(['OCCTAX_DENOMBREMENT'], id_dataset)
          .pipe(catchError(() => of([])));
      })
    );

    combineLatest(this.$_globalAdditionalFields, this.$_datasetAdditionalFields)
      .pipe(
        map(([globalFields, datasetFields]: [any[], any[]]): any[] =>
          [].concat(globalFields, datasetFields)
        )
      )
      .subscribe((fields) => this.additionalFields.next(fields));
  }
}
