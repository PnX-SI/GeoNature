import { STEPPER_GLOBAL_OPTIONS } from '@angular/cdk/stepper';
import { Component, Inject, OnInit } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA } from '@angular/material';
import { ActivatedRoute } from '@angular/router';

import { BehaviorSubject } from 'rxjs';

import { IPermission } from '../../permission.interface';
import { PermissionService } from '../../permission.service';

@Component({
  selector: 'gn-edit-permission-modal',
  templateUrl: './edit-permission-modal.component.html',
  styleUrls: ['./edit-permission-modal.component.scss'],
  providers: [
    { provide: STEPPER_GLOBAL_OPTIONS, useValue: {showError: true} },
  ]
})
export class EditPermissionModal implements OnInit {

  // Current permission gathering
  public gathering: BehaviorSubject<string> = new BehaviorSubject(null);
  // Boolean to check if its updateMode
  public updateMode: BehaviorSubject<boolean> = new BehaviorSubject(false);
  private uuid_regexp = /^[0-9A-F]{8}-[0-9A-F]{4}-[4][0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/i;
  public formGroup;
  public modules;
  public actionsOjects;
  public filters = [];
  public filtersValues;
  public geographicFilterTypes: Array<Number>;
  public taxonomicFilterRank: string;
  public datePickerMin;
  public datePickerMax;

  constructor(
    @Inject(MAT_DIALOG_DATA) public permission: IPermission,
    private route: ActivatedRoute,
    private permissionService: PermissionService,
    private formBuilder: FormBuilder,
  ) {
    // TODO: use code instead of id ! Use config parameter with token Dependency Injection !
    this.geographicFilterTypes = [25,26];
    // TODO: use config parameter with token Dependency Injection !
    this.taxonomicFilterRank = 'GN';

    this.loadModules();
    this.prepareFilters();
    this.buildFormGroups();
  }

  private loadModules() {
    this.permissionService.getModules().subscribe( modules => {
      this.modules = modules;
    });
  }

  ngOnInit(): void {
    // If update, get gathering from URL
    let gathering = this.route.snapshot.paramMap.get('gathering');
    if (gathering && gathering.match(this.uuid_regexp)) {
      this.gathering.next(gathering);
    } else {
      this.gathering.next(null);
    }
  }

  private prepareFilters() {
    const today = new Date();
    const dayDuration = 864e5;

    this.datePickerMin = this.transformToDateObject(today);

    // TODO: improve pnx-date to not set maxDate for unlimited future date
    const maxAccessDuration = dayDuration * 3650;// 10 years
    const in2YearsDate = new Date(today.valueOf() + maxAccessDuration);
    this.datePickerMax = this.transformToDateObject(in2YearsDate);
  }

  // TODO: move this function in PermissionService. Refactor with access-request.component.
  private transformToDateObject(date: Date) {
    return {
      year: date.getFullYear(),
      month: date.getMonth() + 1,
      day: date.getDate(),
    };
  }

  private buildFormGroups() {
    this.formGroup = this.formBuilder.group({
      modules: this.formBuilder.group({
        module: ['', Validators.required],
      }),
      actionsObjects: this.formBuilder.group({
        actionObject: [''],
      }),
      filters: this.formBuilder.group({
        geographic: [''],
        taxonomic: [''],
        precision: [''],
        scope: [''],
      }),
      validating: this.formBuilder.group({
        endDate: [''],
      }),
    });
    console.log(this.formGroup.controls)
  }
}
