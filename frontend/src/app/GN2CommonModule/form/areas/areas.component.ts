import { Component, OnInit, Input } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { AppConfig } from '@geonature_config/app.config';
import { Subject, Observable, of, concat } from 'rxjs';
import { distinctUntilChanged, debounceTime, switchMap, tap, catchError, map } from 'rxjs/operators'

@Component({
  selector: 'pnx-areas',
  templateUrl: 'areas.component.html'
})
export class AreasComponent extends GenericFormComponent implements OnInit {
  public cachedAreas: any;
  @Input() typeCodes: Array<string> = []; // Areas type_code
  @Input() valueFieldName: string = 'id_area'; // Field name for value (default : id_area)
  areas_input$ = new Subject<string>();
  areas: Observable<any>;
  loading = false;


  constructor(
    private _dfs: DataFormService,
  ) {
    super();
  }

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
      return data.map(element => {
        element['area_name'] = `${element['area_name']} (${element.area_code.substr(0, 2)}) `;
        return element;
      });
    }

    return data;
  }
}
