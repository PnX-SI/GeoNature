import { Component, EventEmitter, Input, OnDestroy, OnInit, Output } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { NgbTypeaheadSelectItemEvent } from '@ng-bootstrap/ng-bootstrap';
import { DesignStyle } from '../items-select/items-select.component';
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
 *
 * Two designs are available (``designStyle``): ``material`` (the default, ``mat-autocomplete``)
 * and ``bootstrap`` (``ngbTypeahead``).
 */
@Component({
  selector: 'pnx-autocomplete-select',
  templateUrl: 'autocomplete-select.component.html',
})
export class AutoCompleteSelectComponent implements OnInit, OnDestroy {
  @Input() designStyle: DesignStyle = 'material';
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

  /** Items matching the text typed by the user (``material`` design) */
  results$: Observable<Array<any>>;
  public isLoading: boolean;
  public noResult: boolean;
  private _destroy$ = new Subject<void>();

  ngOnInit() {
    this.results$ = this.search(
      this.parentFormControl.valueChanges.pipe(
        filter((value): value is string => typeof value === 'string')
      )
    );
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

  /** Text displayed in the input for the value of the control (``material`` design) */
  displayWith = (value: any): string =>
    this.formatter ? this.formatter(value) : value != null ? String(value) : '';

  get showLoading(): boolean {
    return this.isLoading && this.parentFormControl.value?.length >= 3;
  }

  /** The item picked in the list (``material`` design), as the event of the typeahead */
  optionSelected(item: any) {
    this.itemSelected({ item, preventDefault: () => {} } as NgbTypeaheadSelectItemEvent);
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
