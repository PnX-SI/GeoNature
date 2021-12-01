import { Component, OnInit, Input } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { FormControl } from '@angular/forms';
import { CommonService } from '@geonature_common/service/common.service';
import { AppConfig } from '@geonature_config/app.config';

@Component({
  selector: 'pnx-areas',
  templateUrl: 'areas.component.html'
})
export class AreasComponent implements OnInit {
  public areas: any;
  public cachedAreas: any;
  @Input() idTypes: Array<number>; // Areas id_type
  /** Désactive le composant. */
  @Input() disabled: boolean = false;
  @Input() label: string;
  @Input() searchBar = false;
  @Input() parentFormControl: FormControl;
  @Input() bindAllItem: false;
  @Input() debounceTime: number;

  constructor(
    private _dfs: DataFormService,
    private _commonService: CommonService,
  ) {}

  ngOnInit() {
    // patch pour bien avoir 'id_area' en valeur par defaut
    // si l'input est defini dans le html mais que sa valeur est undefined
    this.valueFieldName = this.valueFieldName == undefined
      ? 'id_area'
      : this.valueFieldName;

    this.getAreas();
  }

  getAreas() {
    this.areas = concat(
        this._dfs.getAreas(this.typeCodes).pipe(map(data=>this.formatAreas(data))), // default items
        this.areas_input$.pipe(
            debounceTime(200),
            distinctUntilChanged(),
            tap(() => this.loading = true),
            switchMap(term => {
              return term.length >= 2 ?
                this._dfs.getAreas(this.typeCodes, term).pipe(
                  map(data=>this.formatAreas(data)),
                  catchError(() => of([])), // empty list on error
                  tap(() => this.loading = false)
                ) : [];
            })
        )
    );
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
