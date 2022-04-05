import { Component, Input, OnInit } from '@angular/core';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { CommonService } from '@geonature_common/service/common.service';
import { debounceTime, distinctUntilChanged, filter } from 'rxjs/operators';

@Component({
  selector: 'pnx-map-list-generic-filter',
  templateUrl: 'generic-filters.component.html',
  styleUrls: ['generic-filters.component.scss'],
})
export class MapListGenericFiltersComponent implements OnInit {
  @Input() availableColumns: Array<any>;
  @Input() displayColumns: Array<any>;
  @Input() filterableColumns: Array<any>;
  @Input() apiEndPoint: string;
  public colSelected: any;
  constructor(public mapListService: MapListService, private _commonService: CommonService) {}

  ngOnInit() {
    this.mapListService.genericFilterInput.valueChanges
      .pipe(
        distinctUntilChanged(),
        debounceTime(400),
        filter((value) => value !== null)
      )
      .subscribe((value) => {
        if (value !== null && this.mapListService.colSelected.name === '') {
          this._commonService.translateToaster('warning', 'MapList.NoColumnSelected');
        } else {
          this.mapListService.urlQuery = this.mapListService.urlQuery.delete(
            this.mapListService.colSelected.prop
          );
          if (value.length > 0) {
            this.mapListService.refreshData(this.apiEndPoint, 'set', [
              { param: this.mapListService.colSelected.prop, value: value },
            ]);
          } else {
            this.mapListService.deleteAndRefresh(
              this.apiEndPoint,
              this.mapListService.colSelected.prop
            );
          }
        }
      });
  }

  toggle(col) {
    const isChecked = this.isChecked(col);
    if (isChecked) {
      this.mapListService.displayColumns = this.mapListService.displayColumns.filter((c) => {
        return c.prop !== col.prop;
      });
    } else {
      this.mapListService.displayColumns = [...this.mapListService.displayColumns, col];
    }
  }

  onChangeFilterOps(col) {
    // reset url query
    this.mapListService.urlQuery.delete(this.mapListService.colSelected.prop);
    this.mapListService.colSelected = col; // change filter selected
  }

  isChecked(col) {
    let i = 0;
    while (i < this.displayColumns.length && this.displayColumns[i].prop !== col.prop) {
      i = i + 1;
    }
    return i === this.displayColumns.length ? false : true;
  }
}
