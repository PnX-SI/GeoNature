import { Component, EventEmitter, Input, OnDestroy, OnInit, Output } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { NgbTypeaheadSelectItemEvent } from '@ng-bootstrap/ng-bootstrap';
import { Observable, of, Subject } from 'rxjs';
import {
  catchError,
  debounceTime,
  distinctUntilChanged,
  filter,
  map,
  switchMap,
  takeUntil,
  tap,
} from 'rxjs/operators';

/**
 * Presentational typeahead: it only knows the function searching items for a term.
 * Use ``pnx-autocomplete`` to search items through an API.
 */
@Component({
  selector: 'pnx-autocomplete-select',
  templateUrl: 'autocomplete-select.component.html',
})
export class AutoCompleteSelectComponent implements OnInit, OnDestroy {
  /** Search the items matching a term. Must return an array */
  @Input() searchFn: (term: string) => Observable<Array<any>> = () => of([]);
  @Input() parentFormControl: UntypedFormControl;
  @Input() label: string;
  @Input() charNumber = 2;
  @Input() placeholder = '';
  /** The key of the dict to display in the typehead */
  @Input() keyValue;
  /** Function to format the item displayed in the input once selected */
  @Input() formatter: any;
  /** Callback function to map the result of the search */
  @Input() mapFunc: any;
  /**
   * Pass a custom template for the displayed items,
   * if null the default template is taken (cf #rt in template)
   */
  @Input() resultTemplate: any;
  /** Emits the typeahead event, the item is ``e.item`` */
  @Output() onChange = new EventEmitter<NgbTypeaheadSelectItemEvent>();
  @Output() onDelete = new EventEmitter<any>();

  public isLoading: boolean;
  public noResult: boolean;
  private _destroy$ = new Subject<void>();

  ngOnInit() {
    this.parentFormControl.valueChanges
      .pipe(
        filter((value) => value !== null && value.length === 0),
        takeUntil(this._destroy$)
      )
      .subscribe(() => this.onDelete.emit());
  }

  ngOnDestroy() {
    this._destroy$.next();
    this._destroy$.complete();
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
      switchMap((term) => {
        if (term.length >= this.charNumber) {
          return this.searchFn(term).pipe(catchError(() => of([])));
        } else {
          this.isLoading = false;
          return of([]);
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
