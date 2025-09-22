import { Component, Input } from '@angular/core';
import { FormControl } from '@angular/forms';

@Component({
  selector: 'gn-uuid',
  templateUrl: './uuid.component.html',
})
export class UUIDComponent {
  @Input()
  label: string = 'UUID';

  @Input()
  formControl: FormControl = null;
}
