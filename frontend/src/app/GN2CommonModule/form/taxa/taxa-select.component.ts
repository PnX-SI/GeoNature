import { Component, EventEmitter, Input, OnDestroy, OnInit, Output } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { Subject } from 'rxjs';
import { HigherTaxon } from '../../interfaces';
import { takeUntil } from 'rxjs/operators';

/**
 * Presentational multi-select of taxa: it only knows the items it receives, emits the
 * term typed by the user (``search``) and writes to the form control.
 * Use ``pnx-taxa`` to have the taxa fetched from the API.
 */
@Component({
  selector: 'pnx-taxa-select',
  templateUrl: 'taxa-select.component.html',
})
export class TaxaSelectComponent implements OnInit, OnDestroy {
  @Input() items: Array<HigherTaxon> = [];
  @Input() parentFormControl: UntypedFormControl;
  @Input() label: string;
  @Input() class: string = 'auto';
  @Input() loading: boolean = false;
  /** Attribute of the taxon written in the form control. ``null`` to get the whole object */
  @Input() valueFieldName: string = 'cd_nom';
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
