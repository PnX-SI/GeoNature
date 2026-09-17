import { Component, Input } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';

@Component({
  selector: 'gn-password-field',
  templateUrl: './password-field.component.html',
  styleUrls: ['./password-field.component.scss'],
})
export class PasswordFieldComponent {
  @Input() control: UntypedFormControl;
  @Input() label = 'Authentication.Password';
  @Input() showIcon = true;
}
