import { Component, OnInit, Input } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { FormControl } from '@angular/forms';
import { CommonService } from '@geonature_common/service/common.service';

@Component({
  selector: 'pnx-areas',
  templateUrl: 'areas.component.html'
})
export class AreasComponent implements OnInit {
  public areas: any;
  public cachedAreas: any;
  @Input() idType: number; // Areas id_type
  @Input() label: string;
  @Input() searchBar = false;
  @Input() parentFormControl: FormControl;
  @Input() bindAllItem: false;
  @Input() debounceTime: number;
  constructor(private _dfs: DataFormService, private _commonService: CommonService) {}

  ngOnInit() {
    this._dfs.getAreas(this.idType).subscribe(data => {
      this.cachedAreas = data;
      this.areas = data;
    });
  }

  refreshAreas(area_name) {
    // refresh area API call only when area_name >= 2 character
    if (area_name && area_name.length >= 2) {
      this._dfs.getAreas(this.idType, area_name).subscribe(
        data => {
          this.areas = data;
        },
        err => {
          if (err.status === 404) {
            this.areas = [{ area_name: 'No data to display' }];
          } else {
            this.areas = [];
            this._commonService.translateToaster('error', 'ErrorMessage');
          }
        }
      );
      // and reset areas when delete search or select a area
    } else if (!area_name) {
      this.areas = this.cachedAreas;
    }
  }
}
