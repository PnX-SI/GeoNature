import {
  Component,
  EventEmitter,
  Input,
  OnChanges,
  OnDestroy,
  OnInit,
  Output,
  SimpleChanges,
} from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { Subject } from 'rxjs';
import { Area } from '../../interfaces';
import { takeUntil } from 'rxjs/operators';
import { DesignStyle } from '../items-select/items-select.component';

/**
 * Presentational select of geographic areas: it only knows the items it receives, emits the
 * term typed by the user (``search``) and writes to the form control.
 * Use ``pnx-areas`` to have the areas fetched from the API.
 */
@Component({
  selector: 'pnx-areas-select',
  templateUrl: 'areas-select.component.html',
  styleUrls: ['areas-select.component.scss'],
})
export class AreasSelectComponent implements OnInit, OnChanges, OnDestroy {
  /** Design of the select: ``material`` by default, ``bootstrap`` gives the ``ng-select`` one */
  @Input() designStyle: DesignStyle = 'material';
  @Input() items: Array<Area> = [];
  @Input() parentFormControl: UntypedFormControl;
  @Input() label: string;
  @Input() class: string = 'auto';
  @Input() multiSelect: boolean = false;
  @Input() clearable: boolean = true;
  @Input() loading: boolean = false;
  /** Attribute of the area written in the form control. ``null`` to get the whole object */
  @Input() valueFieldName: string = 'id_area';
  @Input() compareWith = (item, selected) => item[this.valueFieldName] === selected;
  /** Term typed in the search box */
  @Output() search = new EventEmitter<string>();
  /** Selected items */
  @Output() selectionChange = new EventEmitter<any>();

  typeahead$ = new Subject<string>();
  /** Term typed in the search box (``material`` design) */
  term = '';
  private destroy$ = new Subject<void>();
  /** Every area received so far, so that the selected ones stay in the options of the select */
  private known = new Map<any, Area>();

  /** Value written in the control for an area */
  valueOf(area: Area): any {
    return this.valueFieldName ? area[this.valueFieldName] : area;
  }

  /** Comparison of the ``material`` design between an option and the control value */
  compare = (option: any, selected: any): boolean =>
    this.valueFieldName
      ? option === selected
      : option === selected || (!!option && !!selected && option.id_area === selected.id_area);

  /** Areas found by the search, with the selected ones (the select would lose their label) */
  get options(): Array<Area> {
    const value = this.parentFormControl?.value;
    const selected = (Array.isArray(value) ? value : [value])
      .filter((v) => v !== null && v !== undefined)
      .map((v) => (this.valueFieldName ? this.known.get(v) : v))
      .filter((area) => !!area);
    const items = this.items ?? [];
    return [
      ...selected.filter((a) => !items.some((i) => this.compare(this.valueOf(i), this.valueOf(a)))),
      ...items,
    ];
  }

  get hasValue(): boolean {
    const value = this.parentFormControl?.value;
    return Array.isArray(value) ? value.length > 0 : value !== null && value !== undefined;
  }

  termChanged(term: string) {
    this.term = term;
    this.typeahead$.next(term);
  }

  openedChanged(opened: boolean) {
    if (!opened) {
      this.termChanged('');
    }
  }

  selectionChanged(value: any) {
    const selected = (Array.isArray(value) ? value : [value]).filter((v) => v != null);
    this.selectionChange.emit(
      this.multiSelect
        ? selected.map((v) => this.areaOf(v))
        : selected.length
          ? this.areaOf(selected[0])
          : null
    );
  }

  clear(event: Event) {
    event.stopPropagation();
    this.parentFormControl.setValue(this.multiSelect ? [] : null);
    this.selectionChange.emit(this.multiSelect ? [] : null);
  }

  private areaOf(value: any): Area {
    return this.valueFieldName ? this.known.get(value) : value;
  }

  ngOnChanges(changes: SimpleChanges) {
    if (changes.items) {
      if (this.valueFieldName) {
        (this.items ?? []).forEach((area) => this.known.set(area[this.valueFieldName], area));
      }
    }
  }

  ngOnInit() {
    this.typeahead$.pipe(takeUntil(this.destroy$)).subscribe((term) => this.search.emit(term));
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
