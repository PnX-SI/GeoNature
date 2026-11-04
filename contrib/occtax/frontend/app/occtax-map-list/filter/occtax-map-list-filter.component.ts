import { AfterViewInit, Component, OnInit, ViewChild } from '@angular/core';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { TaxonomyComponent } from '@geonature_common/form/taxonomy/taxonomy.component';
import { UntypedFormGroup } from '@angular/forms';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { FILTERSLIST } from './filters-list';
import { HttpParams } from '@angular/common/http';
import { OcctaxMapListService } from '../occtax-map-list.service';
import { ModuleService } from '@geonature/services/module.service';
import { OcctaxConfigService } from '../../services/occtax-config.service';

@Component({
  selector: 'pnx-occtax-map-list-filter',
  templateUrl: 'occtax-map-list-filter.component.html',
  styleUrls: ['./occtax-map-list-filter.component.scss'],
})
export class OcctaxMapListFilterComponent implements OnInit, AfterViewInit {
  public formsDefinition = FILTERSLIST;
  public dynamicFormGroup: UntypedFormGroup;
  public formsSelected = [];
  public displayParams: HttpParams = new HttpParams();
  @ViewChild(TaxonomyComponent)
  public taxonomyComponent: TaxonomyComponent;

  constructor(
    private mapListService: MapListService,
    private _dateParser: NgbDateParserFormatter,
    public occtaxMapListService: OcctaxMapListService,
    public moduleService: ModuleService,
    public occtaxConfig: OcctaxConfigService
  ) {}

  ngOnInit() {}

  ngAfterViewInit() {
    const savedFilters = localStorage.getItem('occtaxFilters');
    if (savedFilters) {
      const parsedFilters = JSON.parse(savedFilters);
      setTimeout(() => {
        this.occtaxMapListService.dynamicFormGroup.patchValue(parsedFilters);
        this.searchData();
      }, 500)
    }
  }

  searchData() {
    this.mapListService.zoomOnLayer = true;
    this.mapListService.refreshUrlQuery(this.occtaxMapListService.rowPerPage);
    const params = [];
    for (let key in this.occtaxMapListService.dynamicFormGroup.value) {
      let value = this.occtaxMapListService.dynamicFormGroup.value[key];
      if (key === 'cd_nom' && value) {
        value = this.occtaxMapListService.dynamicFormGroup.value[key].cd_nom;
        params.push({ param: key, value: value });
      } else if ((key === 'date_up' || key === 'date_low') && value) {
        value = this._dateParser.format(this.occtaxMapListService.dynamicFormGroup.value[key]);
        params.push({ param: key, value: value });
      } else if (key === 'observers' && value) {
        this.occtaxMapListService.dynamicFormGroup.value.observers.forEach((observer) => {
          params.push({ param: 'observers', value: observer.id_role });
        });
      } else if (value && value !== '') {
        params.push({ param: key, value: value });
      }
    }
    localStorage.setItem(
      'occtaxFilters',
      JSON.stringify(this.occtaxMapListService.dynamicFormGroup.value)
    );
    this.mapListService.refreshData(null, 'set', params);
  }

  refreshFilters() {
    this.taxonomyComponent.refreshAllInput();
    this.occtaxMapListService.dynamicFormGroup.reset();
    this.mapListService.refreshUrlQuery(12);
    localStorage.removeItem('occtaxFilters');
  }
}
