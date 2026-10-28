import { Component, OnInit, OnDestroy } from '@angular/core';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { Subject } from 'rxjs';
import { takeUntil, map } from 'rxjs/operators';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { ModuleService } from '@geonature/services/module.service';
import { OcctaxMapListService } from '../occtax-map-list.service';
import { OcctaxConfigService } from '../../services/occtax-config.service';
import { OcctaxMapListFilterComponent } from '../filter/occtax-map-list-filter.component';

@Component({
  selector: 'pnx-phyto-list-filter',
  templateUrl: 'phyto-list-filter.component.html',
  styleUrls: ['phyto-list-filter.component.scss'],
})
export class PhytoListFilterComponent extends OcctaxMapListFilterComponent implements OnInit, OnDestroy {
  private readonly destroy$ = new Subject<void>();

  public organisms: Array<any> = [];
  public isCollapsePeriod = true;

  constructor(
    mapListService: MapListService,
    _dateParser: NgbDateParserFormatter,
    occtaxMapListService: OcctaxMapListService,
    moduleService: ModuleService,
    occtaxConfig: OcctaxConfigService,
    private _api: DataFormService,
  ) {
    super(
      mapListService,
      _dateParser,
      occtaxMapListService,
      moduleService,
      occtaxConfig
    )
  }

  ngOnInit(): void {
    this._api.getOrganismsDatasets()
    .pipe(takeUntil(this.destroy$))
    .subscribe((data: any[]) => {
      this.organisms = data;
    });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

}
