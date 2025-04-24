import { ValidatorMessageService } from "@geonature_common/service/validator-message.service";
import { Component, Input, OnChanges, SimpleChanges } from "@angular/core";
import { AbstractControl } from "@angular/forms";
import { merge, of, Subscription } from "rxjs";


@Component({
    selector: 'gn-validation-error',
    template: `
      <div *ngIf="message">
        <small class="text-danger">{{ message }}</small>
      </div>
    `
  })
  export class GnValidationErrorComponent implements OnChanges {
    @Input() control!: AbstractControl;
    @Input() overrideMessages?: Record<string,string>;
    @Input() prefix: string = 'Errors';
    message: string|null = null;
    private sub = Subscription.EMPTY;
    
    constructor(private _vm: ValidatorMessageService) {}
  
    ngOnChanges(changes: SimpleChanges) {
      if (changes.control) {
        this.sub.unsubscribe();
        const ctrl: AbstractControl = changes.control.currentValue;
        if (!ctrl) return;
        this.sub = merge(
          of(ctrl.status),
          ctrl.statusChanges
        ).subscribe(() => this.updateMessage(ctrl));
      }
    }
  
    ngOnDestroy() {
      this.sub.unsubscribe();
    }
  
    private updateMessage(ctrl: AbstractControl) {
      this.message = null;
      if (ctrl.invalid && (ctrl.touched || ctrl.dirty)) {
        const key = Object.keys(ctrl.errors!)[0];
        const details = ctrl.getError(key);
        // priorité à overrideMessages si défini
        if (this.overrideMessages?.[key]) {
          this.message = this.overrideMessages[key]
            .replace('{{' + key + '}}', details?.[key] ?? '');
        } else {
          this.message = this._vm.getMessage(key, details);
        }
      }
    }
  }