import { Component, OnInit, Output, EventEmitter } from '@angular/core';
import { OccHabMapListService } from '../../services/occhab-map-list.service';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { ConfigService } from '@geonature/services/config.service';
import { ActivatedRoute } from '@angular/router';
import { DYNAMIC_FORM_DEF } from './dynamicFormConfig';

@Component({
  selector: 'pnx-occhab-map-list-filter',
  templateUrl: './occhab-map-list-filter.component.html',
  styleUrls: ['./occhab-map-list-filter.component.scss'],
})
export class OcchabMapListFilterComponent implements OnInit {
  @Output() onSearch = new EventEmitter<any>();

  public dynamycFormDef: Array<any>;
  public processedDefaultFilters: any;

  constructor(
    public mapListFormService: OccHabMapListService,
    private _dateParser: NgbDateParserFormatter,
    public config: ConfigService,
    private _route: ActivatedRoute
  ) {}

  ngOnInit() {
    this.filterIdImport();
    this.dynamycFormDef = DYNAMIC_FORM_DEF;
  }

  filterIdImport() {
    this._route.queryParamMap.subscribe((params) => {
      if (params.get('id_import')) {
        this.mapListFormService.searchForm.controls['id_dataset'].setValue(
          Number(params.get('id_dataset'))
        );
        this.mapListFormService.searchForm.controls['id_import'].setValue(
          Number(params.get('id_import'))
        );
        this.processedDefaultFilters = { id_import: [Number(params.get('id_import'))] };
        this.onSearch.emit(this.cleanFilter());
      }
    });
  }

  formatter(item) {
    return item.search_name;
  }

  searchEvent($event) {
    this.onSearch.emit(this.cleanFilter());
  }

  resetFilterForm() {
    this.mapListFormService.searchForm.reset();
  }

  cleanFilter() {
    const cleanedObject = {};
    Object.keys(this.mapListFormService.searchForm.value).forEach((key) => {
      /** return only the form items where value is not null or empty array */
      if (
        this.mapListFormService.searchForm.value[key] ||
        (Array.isArray(this.mapListFormService.searchForm.value[key]) &&
          this.mapListFormService.searchForm.value[key] > 0)
      ) {
        if (key == 'habitat') {
          cleanedObject['cd_hab'] = this.mapListFormService.searchForm.value[key]['cd_hab'];
        } else if (key === 'date_low' || key === 'date_up') {
          cleanedObject[key] = this._dateParser.format(
            this.mapListFormService.searchForm.value[key]
          );
        } else {
          cleanedObject[key] = this.mapListFormService.searchForm.value[key];
        }
      }
    });
    return cleanedObject;
  }
}
