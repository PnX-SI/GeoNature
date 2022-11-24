import { Directive, Input } from '@angular/core';
import { NgControl } from '@angular/forms';

@Directive({
  selector: '[disableControl]',
})
export class DisableControlDirective {
  @Input()
  set disableControl(condition: boolean) {
    const action = condition ? 'disable' : 'enable';
    if (this.ngControl?.control) {
      this.ngControl.control[action]();
    }
  }

  constructor(private ngControl: NgControl) {}
}
