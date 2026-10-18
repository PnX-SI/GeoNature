import { Component, EventEmitter, Input, OnDestroy, OnInit, Output } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { Subject } from 'rxjs';
import { Area } from '../../interfaces';
import { takeUntil } from 'rxjs/operators';

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
export class AreasSelectComponent implements OnInit, OnDestroy {
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
  private destroy$ = new Subject<void>();

  ngOnInit() {
    this.typeahead$.pipe(takeUntil(this.destroy$)).subscribe((term) => this.search.emit(term));
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
