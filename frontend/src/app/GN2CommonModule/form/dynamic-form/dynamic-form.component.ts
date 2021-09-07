import {
  Component,
  OnInit,
  OnChanges,
  Input,
  Output,
  EventEmitter,
  SimpleChanges,
} from '@angular/core';
import { FormGroup, FormControl } from '@angular/forms';
import { DynamicFormService } from '../dynamic-form-generator/dynamic-form.service';
import { AppConfig } from '@geonature_config/app.config';

@Component({
  selector: 'pnx-dynamic-form',
  templateUrl: './dynamic-form.component.html',
  styleUrls: ['./dynamic-form.component.scss']
})
export class DynamicFormComponent implements OnInit, OnChanges {
  @Input() formDef: any;
  @Input() form: FormGroup;

  @Input() update;

  @Output() change = new EventEmitter<any>();

  public appConfig = AppConfig;
  public rand = Math.ceil(Math.random() * 1e10);

  public formDefComp = {};

  constructor(private _dynformService: DynamicFormService) { }

  ngOnInit() {
    this.setFormDefComp();
  }

  setFormDefComp() {
    this.formDefComp = {};
    for (const key of Object.keys(this.formDef)) {
      this.formDefComp[key] = this._dynformService.getFormDefValue(
        this.formDef,
        key,
        this.form.value
      );
    }

    if (this.form !== undefined) {
      // on met à jour les contraintes
      this._dynformService.setControl(
        this.form.controls[this.formDef.attribut_name],
        this.formDefComp
      );
    }
  }

  /** Cette méthode ne gère que les fichiers uniques. */
  onFileChange(event) {
    const files: FileList = event.target.files;
    if (files && files.length === 0) {
      return;
    }
    const file: File = files[0];
    const value = {};
    value[this.formDef.attribut_name] = file;
    this.form.patchValue(value);
  }

  onCheckChange(event, formControl: FormControl) {
    const currentFormValue = Object.assign([], formControl.value);
    // Selected
    if (event.target.checked) {
      // Add a new control in the arrayForm
      currentFormValue.push(event.target.value);
      // Patch value to declench validators
      formControl.patchValue(currentFormValue);
    } else {
      // Find the unselected element
      currentFormValue.forEach((val, index) => {
        if (val === event.target.value) {
          // Remove the unselected element from the arrayForm
          currentFormValue.splice(index, 1);
        }
      });
      // Patch value to declench validators
      formControl.patchValue(currentFormValue);
    }
  }

  onRadioChange(val, formControl: FormControl) {
    formControl.setValue(val);
  }

  ngOnChanges(changes: SimpleChanges) {    
    for (const propName of Object.keys(changes)) {
      // si le composant dynamic-form-generator annonce un update
      // => on recalcule les propriétés
      if (propName === 'update' && this.update === true) {
        this.setFormDefComp();
      }
      if (propName !== 'update') {
        this.setFormDefComp();
      }
    }
  }
}
