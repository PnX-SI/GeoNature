import {
  Component,
  EventEmitter,
  Input,
  OnChanges,
  Output,
  SimpleChanges,
  TemplateRef,
} from '@angular/core';
import { UntypedFormControl, Validators } from '@angular/forms';
import { selectSingleItem } from './items-select.utils';

/**
 * Presentational select over a list of items: it only knows the items it receives and the form
 * control it writes to. It is the display part of the components fetching items from the API
 * (``pnx-datasets``, ``pnx-nomenclature``, ``pnx-observers``, ``pnx-acquisition-frameworks``).
 *
 * Two designs are available (``designStyle``): ``material`` (the default: ``mat-form-field`` with ``mat-select``,
 * with a search box, a clear button and a loading spinner) and ``bootstrap`` (``ng-select``).
 * ``appendTo`` and ``clearAllText`` only apply to the ``bootstrap`` design.
 *
 * By default an option displays the ``bindLabel`` attribute of the item, with a tooltip.
 * Give an ``optionTemplate`` to display something else.
 *
 * @example
 * <pnx-items-select
 *   [items]="datasets"
 *   bindLabel="dataset_name"
 *   bindValue="id_dataset"
 *   [parentFormControl]="control"
 *   label="Datasets">
 * </pnx-items-select>
 */
export type DesignStyle = 'bootstrap' | 'material';

@Component({
  selector: 'pnx-items-select',
  templateUrl: './items-select.component.html',
})
export class ItemsSelectComponent implements OnChanges {
  /** Design of the select: ``material`` by default, only ``bootstrap`` gives the ``ng-select`` one */
  @Input() designStyle: DesignStyle = 'material';
  @Input() items: Array<any> = [];
  @Input() parentFormControl: UntypedFormControl;
  @Input() label: string;
  @Input() class: string = 'auto';
  @Input() multiSelect: boolean = false;
  @Input() clearable: boolean = true;
  @Input() loading: boolean = false;
  /** Allow to filter the items by their label */
  @Input() searchable: boolean = true;
  /** Attribute of the item displayed as label */
  @Input() bindLabel: string;
  /** Attribute of the item written in the form control. ``null`` to get the whole item */
  @Input() bindValue: string = null;
  /** Placeholder, the label by default */
  @Input() placeholder: string;
  /** Function comparing the items with the control value. Needed to write whole items with ``bindValue`` */
  @Input() compareWith: (item: any, selected: any) => boolean;
  @Input() appendTo: string = null;
  @Input() clearAllText: string = 'Clear all';
  /** ``data-qa`` attribute of the select */
  @Input() dataQa: string;
  /** ``qa-test`` attribute of the select */
  @Input() qaTest: string;
  /** Template of an option, the item is its implicit context */
  @Input() optionTemplate: TemplateRef<{ $implicit: any }>;
  /**
   * Attribute of the item to write in the control when it is the only item, the control is required and empty.
   * The feature is disabled without this input.
   */
  @Input() autoSelectKey: string;

  /** Emits the item that has just been added to a multiple selection */
  @Output() itemAdded = new EventEmitter<any>();
  /** Emits ``{ value: item }`` when an item has just been removed from a multiple selection */
  @Output() itemRemoved = new EventEmitter<{ value: any }>();

  /** Term typed in the search box (``material`` design) */
  search = '';

  /** Selection before the last change (``material`` design), to find out what has been added or removed */
  private previousSelection: Array<any> = [];

  get required(): boolean {
    return !!this.parentFormControl?.hasValidator(Validators.required);
  }

  get hasValue(): boolean {
    const value = this.parentFormControl?.value;
    return Array.isArray(value) ? value.length > 0 : value !== null && value !== undefined;
  }

  /** Items matching the search term, without hiding the selected ones (the select would lose their label) */
  get filteredItems(): Array<any> {
    const term = this.search.trim().toLowerCase();
    if (!term) {
      return this.items ?? [];
    }
    return (this.items ?? []).filter(
      (item) =>
        String(item[this.bindLabel] ?? '')
          .toLowerCase()
          .includes(term) || this.isSelected(item)
    );
  }

  /** Value written in the control for an item */
  valueOf(item: any): any {
    return this.bindValue ? item[this.bindValue] : item;
  }

  isSelected(item: any): boolean {
    const value = this.parentFormControl?.value;
    const selected = this.multiSelect ? (Array.isArray(value) ? value : []) : [value];
    return selected.some((s) => this.compare(this.valueOf(item), s));
  }

  /** Comparison of the ``material`` design between an option and the control value */
  compare = (option: any, selected: any): boolean =>
    this.compareWith && !this.bindValue ? this.compareWith(option, selected) : option === selected;

  openedChanged(opened: boolean) {
    if (opened) {
      const value = this.parentFormControl?.value;
      this.previousSelection = Array.isArray(value) ? [...value] : [];
    } else {
      this.searchChanged('');
    }
  }

  /** Emits the items added to and removed from a multiple selection (``material`` design) */
  selectionChanged(selection: any) {
    if (!this.multiSelect || !Array.isArray(selection)) {
      return;
    }
    const itemOf = (value: any) => this.items?.find((i) => this.compare(this.valueOf(i), value));
    selection
      .filter((v) => !this.previousSelection.some((p) => this.compare(v, p)))
      .forEach((v) => this.itemAdded.emit(itemOf(v)));
    this.previousSelection
      .filter((p) => !selection.some((v) => this.compare(v, p)))
      .forEach((p) => this.itemRemoved.emit({ value: itemOf(p) }));
    this.previousSelection = [...selection];
  }

  searchChanged(term: string) {
    this.search = term;
  }

  clear(event: Event) {
    event.stopPropagation();
    this.parentFormControl.setValue(this.multiSelect ? [] : null);
  }

  ngOnChanges(changes: SimpleChanges) {
    if (changes.items && this.autoSelectKey) {
      selectSingleItem(this.items, this.parentFormControl, this.multiSelect, this.autoSelectKey);
    }
  }
}
