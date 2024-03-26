import { Component } from '@angular/core';
import { FieldMapping } from 'external_modules/WA/app/models/mapping.model';

@Component({
  selector: 'pnx-mapping-selection',
  templateUrl: './mapping-selection.component.html',
  styleUrls: ['./mapping-selection.component.scss'],
})
export class MappingSelectionComponent {
  public userFieldMappings: Array<FieldMapping>;
}
