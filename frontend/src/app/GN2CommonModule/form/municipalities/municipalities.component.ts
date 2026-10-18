import { Component, Input } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';

@Component({
  selector: 'pnx-municipalities',
  templateUrl: './municipalities.component.html',
  styleUrls: ['./municipalities.component.scss'],
})
export class MunicipalitiesComponent {
  @Input() parentFormControl: UntypedFormControl;
  @Input() label: string;
  /**
   * @deprecated Do not use this input
   */
  @Input() searchBar = false;
  @Input() disabled: boolean;
  @Input() valueFieldName: string = 'id_area'; // Field name for value (default : id_area)
  @Input() multiSelect: boolean = false;

  /**
   * @deprecated Do not use this input
   */
  @Input() bindAllItem: false;
  /**
   * @deprecated Do not use this input
   */ @Input() debounceTime: number;
}
