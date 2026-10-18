import { Component, Input, EventEmitter, Output } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { NgbTypeaheadSelectItemEvent } from '@ng-bootstrap/ng-bootstrap';
import { buildAutocompleteRequest } from './autocomplete.utils';

/**
 * Typeahead componant to display data from an API
 * The API must return an Array<dict>
 * (connected to the API, the display part is in ``pnx-autocomplete-select``)
 */
@Component({
  selector: 'pnx-autocomplete',
  templateUrl: 'autocomplete.component.html',
})
export class AutoCompleteComponent {
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

  constructor(private _api: HttpClient) {}

  /** Search the items matching a term in the API */
  searchFn = (term: string) => {
    const { url, params } = buildAutocompleteRequest(this, term);
    return this._api.get<any>(url, { params });
  };
}
