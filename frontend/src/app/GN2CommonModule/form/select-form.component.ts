import { Component, Input, OnDestroy, OnInit } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { Observable, Subject, Subscription, combineLatest, of } from 'rxjs';
import {
  catchError,
  debounceTime,
  distinctUntilChanged,
  finalize,
  map,
  startWith,
  switchMap,
} from 'rxjs/operators';
import { GenericFormComponent } from './genericForm.component';

/**
 * Base of the form components used to select one or several items (users, organisms...).
 *
 * - ``appearance`` (see ``GenericFormComponent``): the ``material`` appearance only supports
 *   values that are the whole item (no ``bindValue``).
 * - ``autocomplete``: request the items matching what is typed to the API instead of loading
 *   them all. Independent of ``appearance``.
 *
 * A subclass tells how to load the items (``allItems``), how to search them (``fetch``) and how
 * to identify / label an item (``itemId``, ``itemLabel``).
 */
// a Component and not a Directive: Angular forbids a Directive to extend a Component
@Component({ template: '' })
export abstract class SelectFormComponent
  extends GenericFormComponent
  implements OnInit, OnDestroy
{
  /** Request the items to the API while typing instead of loading them all. */
  @Input() autocomplete: boolean = false;
  /** Number of characters from which the API is requested (autocomplete). */
  @Input() minSearchLength: number = 2;
  /** Maximum number of items requested to the API for a search (autocomplete). */
  @Input() searchLimit: number = 20;

  /** Terms typed by the user (``ng-select`` typeahead, Material input). */
  public readonly search$ = new Subject<string>();
  /** Items proposed in the dropdown. */
  public selectOptions$: Observable<any[]>;
  public loading: boolean = false;
  /** Text of the Material input. */
  public searchCtrl = new UntypedFormControl('');
  /** Whether the Material input has the focus. */
  public inputFocused = false;
  private selectSubs = new Subscription();
  private typing = false;

  /** All the items, used when the autocomplete is not requested. */
  protected abstract allItems(): Observable<any[]>;
  /** Request the items whose label matches ``term`` (autocomplete). */
  protected abstract fetch(term: string): Observable<any[]>;
  /** Value used to tell whether two items are the same one. */
  protected abstract itemId(item: any): any;
  /** Text displayed for an item. */
  abstract itemLabel(item: any): string;

  get isMaterial(): boolean {
    return this.appearance === 'material';
  }

  get isRemote(): boolean {
    return this.autocomplete;
  }

  ngOnInit() {
    super.ngOnInit();
    if (this.isRemote) {
      this.initRemoteSearch();
    } else if (this.isMaterial) {
      this.initLocalOptions();
    }
    if (this.isMaterial) {
      this.initMaterialInput();
    }
  }

  ngOnDestroy() {
    super.ngOnDestroy();
    this.selectSubs.unsubscribe();
    this.search$.complete();
  }

  /** Options of the Material input without autocomplete: the loaded items matching the text. */
  private initLocalOptions() {
    const normalize = (text: string) => text.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
    this.selectOptions$ = combineLatest([
      this.allItems(),
      this.searchCtrl.valueChanges.pipe(startWith('')),
    ]).pipe(
      map(([items, text]) =>
        typeof text === 'string'
          ? items.filter((item) => normalize(this.itemLabel(item)).includes(normalize(text)))
          : items
      )
    );
  }

  private initRemoteSearch() {
    this.selectOptions$ = this.search$.pipe(
      map((term) => (term ?? '').trim()),
      debounceTime(300),
      distinctUntilChanged(),
      switchMap((term) => {
        if (term.length < this.minSearchLength) {
          this.loading = false;
          return of([]);
        }
        this.loading = true;
        return this.fetch(term).pipe(
          catchError(() => of([])),
          finalize(() => (this.loading = false))
        );
      })
    );
  }

  /** Link the Material text input with the form control. */
  private initMaterialInput() {
    this.syncInputWithValue(this.parentFormControl.value);
    this.selectSubs.add(
      this.parentFormControl.valueChanges.subscribe((value) => this.syncInputWithValue(value))
    );
    this.selectSubs.add(
      this.searchCtrl.valueChanges.subscribe((text) => {
        // the autocomplete also emits the selected item
        if (typeof text !== 'string') return;
        this.search$.next(text);
        const current = this.parentFormControl.value;
        if (!this.multiSelect && current && text !== this.itemLabel(current)) {
          // the user is changing the selected item: keep what he is typing
          this.typing = true;
          this.parentFormControl.setValue(null);
          this.typing = false;
        }
      })
    );
  }

  private syncInputWithValue(value: any) {
    if (this.typing) return;
    if (this.multiSelect) {
      // the input holds what is typed while focused, the summary of the selection otherwise
      if (!this.inputFocused) {
        this.searchCtrl.setValue(this.selectionSummary, { emitEvent: false });
      }
      return;
    }
    this.searchCtrl.setValue(value ? this.itemLabel(value) : '', { emitEvent: false });
  }

  onInputFocus() {
    this.inputFocused = true;
    if (this.multiSelect) {
      this.searchCtrl.setValue('', { emitEvent: false });
    }
  }

  onInputBlur() {
    this.inputFocused = false;
    if (this.multiSelect) {
      this.searchCtrl.setValue(this.selectionSummary, { emitEvent: false });
    }
  }

  /** Items already selected (``material`` appearance, multiple selection). */
  get selectedItems(): any[] {
    return this.parentFormControl.value ?? [];
  }

  isSelected(item: any): boolean {
    return this.selectedItems.some((i) => this.itemId(i) === this.itemId(item));
  }

  /** e.g. "DUPONT Anny +2": the first selected item and the number of the other ones. */
  get selectionSummary(): string {
    const items = this.selectedItems;
    if (!items.length) return '';
    return this.itemLabel(items[0]) + (items.length > 1 ? ` +${items.length - 1}` : '');
  }

  /** Every selected item, displayed in a tooltip. */
  get selectionLabels(): string {
    return this.selectedItems.map((item) => this.itemLabel(item)).join(', ');
  }

  /**
   * Multiple selection with the mouse: add or remove an item without going through the
   * autocomplete, which would close its panel (the click is stopped in the template).
   */
  toggleItem(item: any) {
    if (this.isSelected(item)) {
      this.removeItem(item);
    } else {
      this.parentFormControl.setValue([...this.selectedItems, item]);
    }
  }

  onOptionSelected(item: any) {
    if (this.multiSelect) {
      // the options of the selected items are checked: selecting them again unselects them
      this.toggleItem(item);
      this.searchCtrl.setValue(this.inputFocused ? '' : this.selectionSummary, {
        emitEvent: false,
      });
    } else {
      this.parentFormControl.setValue(item);
      this.searchCtrl.setValue(this.itemLabel(item), { emitEvent: false });
    }
  }

  removeItem(item: any) {
    this.parentFormControl.setValue(
      this.selectedItems.filter((i) => this.itemId(i) !== this.itemId(item))
    );
  }

  /**
   * Text kept in the Material input once an option is chosen. The autocomplete calls it with
   * the selected item but also with the text of the input, which must be left untouched.
   */
  displayWith = (item: any): string => {
    if (typeof item === 'string') return item;
    return item && !this.multiSelect ? this.itemLabel(item) : '';
  };
}
