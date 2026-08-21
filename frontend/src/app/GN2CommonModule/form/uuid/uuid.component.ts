import { Component, Input } from '@angular/core';
import { FormControl } from '@angular/forms';
import { GenericFormComponent } from '../genericForm.component';

@Component({
  selector: 'gn-uuid',
  templateUrl: './uuid.component.html',
})
export class UUIDComponent extends GenericFormComponent {
  @Input()
  label: string = 'UUID';
  @Input()
  placeholder: string = '';
  @Input() designStyle: 'bootstrap' | 'material' = 'bootstrap';
}
