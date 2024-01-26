import { Component, OnInit, Input, EventEmitter, Output, KeyValueDiffers } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { HttpClient, HttpParams } from '@angular/common/http';
import { CommonService } from '@geonature_common/service/common.service';
import { Observable } from 'rxjs';
import { of } from 'rxjs/observable/of';
import { NgbTypeaheadSelectItemEvent } from '@ng-bootstrap/ng-bootstrap';
import {
  filter,
  debounceTime,
  distinctUntilChanged,
  tap,
  switchMap,
  map,
  timeout,
} from 'rxjs/operators';

@Component({
  selector: 'pnx-autocomplete',
  templateUrl: 'autocomplete.component.html',
})

/**
 * Typeahead componant to display data from an API
 * The API must return an Array<dict>
 */
export class AutoCompleteComponent implements OnInit {
  /** URL de l'API à appeler */
  @Input() apiEndPoint: string;
  @Input() parentFormControl: UntypedFormControl;
  @Input() label: string;
  @Input() charNumber = 2;
  @Input() placeholder = '';
  /** number of typeahead results */
  @Input() listLength = 20;
  /** The key of the dict to display in the typehead */
  @Input() keyValue;
  @Input() queryParamSearch: string;
  /** Put the result of the autocomplete in the URL parameter - Not in GET param */
  @Input() searchAsParameter = false;
  /** Other query string to pass to the URL {'key': 'value}
   * @type: dict
   */
  @Input() othersGetParams: any;
  /** Function to format the result of the API
   * @type function
   */
  @Input() formatter: any;
  /** Callback function to map the result of the API
   * @type function
   */
  @Input() mapFunc: any;

  /**
   * Pass a custom template for the displayed items,
   * if null the default template is taken (cf #rt in template)
   */
  @Input() resultTemplate: any;
  @Output() onChange = new EventEmitter<NgbTypeaheadSelectItemEvent>(); // renvoie l'evenement, le taxon est récupérable grâce à e.item
  @Output() onDelete = new EventEmitter<any>();

  public isLoading: boolean;
  public noResult: boolean;

  constructor(
    private _api: HttpClient,
    private _commonService: CommonService
  ) {}

  ngOnInit() {
    this.parentFormControl.valueChanges
      .pipe(filter((value) => value !== null && value.length === 0))
      .subscribe((value) => {
        this.onDelete.emit();
      });
  }

  itemSelected(e: NgbTypeaheadSelectItemEvent) {
    this.onChange.emit(e);
    this.parentFormControl.reset();
  }

  search = (text$: Observable<string>) =>
    text$.pipe(
      tap(() => (this.isLoading = true)),
      debounceTime(400),
      distinctUntilChanged(),
      switchMap((search_name) => {
        if (search_name.length >= this.charNumber) {
          let url = this.apiEndPoint;
          let getParams = new HttpParams();
          if (this.searchAsParameter) {
            url = url + '/' + search_name;
          } else {
            getParams = getParams.append(this.queryParamSearch, search_name);
          }
          if (this.othersGetParams) {
            // add other params in query string
            for (let param in this.othersGetParams) {
              // check if the param is not null
              if (this.othersGetParams[param]) {
                getParams = getParams.append(param, this.othersGetParams[param].toString());
              }
            }
          }
          return this._api.get<any>(url, { params: getParams }).catch(() => {
            return of([]);
          });
        } else {
          this.isLoading = false;
          return [[]];
        }
      }),
      map((data) => {
        this.noResult = data.length === 0;
        this.isLoading = false;
        if (this.mapFunc) {
          data = data.map(this.mapFunc);
        }
        return data;
      })
    );
}
