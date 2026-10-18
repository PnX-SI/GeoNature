import { Component, Input, OnChanges, SimpleChanges, TemplateRef } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { selectSingleItem } from './items-select.utils';

/**
 * Presentational select over a list of items: it only knows the items it receives and the form
 * control it writes to. It is the display part of the components fetching items from the API
 * (``pnx-datasets``, ``pnx-nomenclature``, ``pnx-observers``, ``pnx-acquisition-frameworks``).
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
@Component({
  selector: 'pnx-items-select',
  templateUrl: './items-select.component.html',
})
export class ItemsSelectComponent implements OnChanges {
  @Input() items: Array<any> = [];
  @Input() parentFormControl: UntypedFormControl;
  @Input() label: string;
  @Input() class: string = 'auto';
  @Input() multiSelect: boolean = false;
  @Input() clearable: boolean = true;
  @Input() loading: boolean = false;
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

  ngOnChanges(changes: SimpleChanges) {
    if (changes.items && this.autoSelectKey) {
      selectSingleItem(this.items, this.parentFormControl, this.multiSelect, this.autoSelectKey);
    }
  }
}
