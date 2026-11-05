import { Injectable, OnDestroy } from '@angular/core';
import { BehaviorSubject, Subject, combineLatest, of } from 'rxjs';
import { catchError, map, filter, switchMap, takeUntil } from 'rxjs/operators';

import { CommonService } from '@geonature_common/service/common.service';
import { OcctaxFormService } from '../../occtax-form.service';
import { AdditionalFieldDefinition, Counting, PhytoData } from '../utils/interfaces';

@Injectable()
export class PhytoCountingStateService implements OnDestroy {
  public countings: Counting[] = [];
  public additionalFields = new BehaviorSubject<AdditionalFieldDefinition[]>([]);

  private readonly destroy$ = new Subject<void>();

  constructor(
    private occurrenceFormService: OcctaxFormService,
    private commonService: CommonService
  ) {
    this.setObservables();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
    this.additionalFields.complete();
  }

  private setObservables(): void {
    const globalAdditionalFields$ = this.occurrenceFormService
      .getAdditionnalFields(['OCCTAX_DENOMBREMENT'])
      .pipe(
        catchError((error: unknown) => {
          this.reportAdditionalFieldsError(error);
          return of([] as AdditionalFieldDefinition[]);
        })
      );

    const datasetAdditionalFields$ = this.occurrenceFormService.occtaxData.asObservable().pipe(
      map((data: PhytoData) => data?.releve?.properties?.id_dataset),
      filter((id_dataset) => id_dataset !== undefined && id_dataset !== null),
      switchMap((id_dataset) => {
        return this.occurrenceFormService
          .getAdditionnalFields(['OCCTAX_DENOMBREMENT'], String(id_dataset))
          .pipe(
            catchError((error: unknown) => {
              this.reportAdditionalFieldsError(error);
              return of([] as AdditionalFieldDefinition[]);
            })
          );
      })
    );

    combineLatest(globalAdditionalFields$, datasetAdditionalFields$)
      .pipe(
        map(([globalFields, datasetFields]) => globalFields.concat(datasetFields)),
        takeUntil(this.destroy$)
      )
      .subscribe((fields) => this.additionalFields.next(fields));
  }

  private reportAdditionalFieldsError(error: unknown): void {
    console.error('Error loading phyto counting additional fields:', error);
    this.commonService.translateToaster('error', 'Errors.ErrorOccurs');
  }
}
