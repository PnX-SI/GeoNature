import { Component, OnInit, OnDestroy } from '@angular/core';
import {
  filter,
  tap,
  map,
  switchMap,
  distinctUntilChanged,
  catchError,
  skip,
} from 'rxjs/operators';
import { FormArray } from '@angular/forms';
import { Observable, empty, Subscription } from 'rxjs';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';

import { DataFormService } from '@geonature_common/form/data-form.service';
import { OcctaxFormOccurrenceService } from './occurrence.service';
import { OcctaxFormService } from '../occtax-form.service';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-occtax-profiles',
  templateUrl: './profiles.component.html',
  styleUrls: ['./profiles.component.scss'],
})
export class OcctaxProfilesComponent implements OnInit, OnDestroy {
  private appConfig = null;
  public profilErrors: any[] = [];
  public taxon: any = null;
  private _sub: Array<Subscription> = [];

  constructor(
    private dateParser: NgbDateParserFormatter,
    private _dataS: DataFormService,
    public occtaxFormService: OcctaxFormService,
    public occtaxFormOccurrenceService: OcctaxFormOccurrenceService,
    public cs: ConfigService
  ) {
    this.appConfig = this.cs;
  }

  ngOnInit() {
    const lifeStageObservable = this.occtaxFormOccurrenceService.lifeStage.pipe(
      distinctUntilChanged(),
      skip(1),
      filter((val) => val !== null),
      filter(() => {
        const taxon = this.occtaxFormOccurrenceService.taxref.getValue();
        return taxon !== null && taxon.cd_ref;
      }),
      map(() => this.occtaxFormOccurrenceService.taxref.getValue().cd_ref),
      switchMap((cdRef: number) => {
        return this.getProfiles(cdRef).pipe(
          catchError(() => {
            this.profilErrors = [];
            return empty();
          })
        );
      })
    );

    const taxonObservable = this.occtaxFormOccurrenceService.taxref.asObservable().pipe(
      //reinitialisation view variable
      tap(() => (this.taxon = null)),
      //filter on param
      filter(() => this.appConfig.FRONTEND['ENABLE_PROFILES']),
      //filter on data
      filter((taxon) => taxon !== null && taxon.cd_ref),
      //set variable for view usage
      tap((taxon: any) => (this.taxon = taxon)),
      //transform data
      map((taxon: any): number => taxon.cd_ref),
      //filter other cdRef value from previous taxon
      distinctUntilChanged(),
      //get data profiles from API
      switchMap((cdRef: number) => {
        return this.getProfiles(cdRef).pipe(
          catchError(() => {
            this.profilErrors = [];
            return empty();
          })
        );
      })
    );

    this._sub.push(taxonObservable.subscribe((data) => (this.profilErrors = data['errors'])));
    this._sub.push(lifeStageObservable.subscribe((data) => (this.profilErrors = data['errors'])));
  }

  ngOnDestroy() {
    this._sub.forEach((sub) => sub.unsubscribe());
  }

  /**
   * Return data profiles from API
   */
  getProfiles(cdRef: number): Observable<any[]> {
    const releve = this.occtaxFormService.occtaxData.getValue().releve;
    const dateMin = this.dateParser.format(releve.properties.date_min);
    const dateMax = this.dateParser.format(releve.properties.date_min);
    // find all distinct id_nomenclature_life_stage if countings
    let idNomenclaturesLifeStage = new Set();
    (
      this.occtaxFormOccurrenceService.form.get('cor_counting_occtax') as FormArray
    ).controls.forEach((counting) => {
      const control = counting.get('id_nomenclature_life_stage');
      if (control) {
        idNomenclaturesLifeStage.add(control.value);
      }
    });
    const postData = {
      cd_ref: cdRef,
      date_min: dateMin,
      date_max: dateMax,
      altitude_min: releve.properties.altitude_min,
      altitude_max: releve.properties.altitude_max,
      geom: releve.geometry,
      life_stages: Array.from(idNomenclaturesLifeStage),
    };

    return this._dataS.controlProfile(postData);
  }
}
