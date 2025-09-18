import { Component, Input, OnInit } from '@angular/core';
import { FormControl, Validators } from '@angular/forms';

@Component({
  selector: 'pnx-togglable-form-control',
  templateUrl: './togglable-form-control.component.html',
})
export class TogglableFormControlComponent {
  @Input()
  label: string = '';

  @Input()
  formControl: FormControl = null;

  private _toggled = false;
  @Input()
  get toggled(): boolean {
    return this._toggled;
  }

  set toggled(toggled: boolean) {
    this._toggled = toggled;

    if (!this.formControl) return;

    if (this.toggled) {
      this.formControl.addValidators(Validators.required);
    } else {
      this.formControl.removeValidators(Validators.required);
    }

    this.formControl.updateValueAndValidity();
  }
}
