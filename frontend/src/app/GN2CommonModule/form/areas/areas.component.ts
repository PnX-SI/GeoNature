import { Component, OnInit, Input } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { FormControl } from '@angular/forms';
import { CommonService } from '@geonature_common/service/common.service';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { AppConfig } from '@geonature_config/app.config';

@Component({
  selector: 'pnx-areas',
  templateUrl: 'areas.component.html'
})
export class AreasComponent extends GenericFormComponent implements OnInit {
  public areas: any;
  public cachedAreas: any;
  @Input() idTypes: Array<number>; // Areas id_type

  constructor(
    private _dfs: DataFormService, 
    private _commonService: CommonService
  ) {
    super();
  }

  ngOnInit() {
    this._dfs.getAreas(this.idTypes).subscribe(data => {
      this.cachedAreas = data;
      this.formatAreas(data);
    });
  }
  /**
   * Set the departement number if the id_type is municipalities
   * @param data
   */
  formatAreas(data) {
    if (data.length > 0 && data[0]['id_type'] === AppConfig.BDD.id_area_type_municipality) {
      this.areas = data.map(element => {
        element['area_name'] = `${element['area_name']} (${element.area_code.substr(0, 2)}) `;
        return element;
      });
    } else {
      this.areas = data;
    }
  }

  refreshAreas(area_name) {
    // refresh area API call only when area_name >= 2 character
    if (area_name && area_name.length >= 2) {
      this._dfs.getAreas(this.idTypes, area_name).subscribe(
        data => {
          this.formatAreas(data);
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
