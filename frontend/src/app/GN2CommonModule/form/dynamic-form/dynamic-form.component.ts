import {
  Component,
  OnInit,
  OnChanges,
  Input,
  Output,
  EventEmitter,
  SimpleChanges,
  OnDestroy,
} from '@angular/core';
import { UntypedFormGroup, UntypedFormControl } from '@angular/forms';
import { DynamicFormService } from '../dynamic-form-generator/dynamic-form.service';
import { distinctUntilChanged } from 'rxjs/operators';
import { Subscription } from 'rxjs';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-dynamic-form',
  templateUrl: './dynamic-form.component.html',
  styleUrls: ['./dynamic-form.component.scss'],
})
export class DynamicFormComponent implements OnInit, OnChanges, OnDestroy {
  @Input() formDef: any;
  @Input() form: UntypedFormGroup;

  @Input() update;

  @Output() change = new EventEmitter<any>();

  public rand = Math.ceil(Math.random() * 1e10);

  public formDefComp: any = {};
  public isValInSelectList: boolean = true;
  private _sub: Subscription;

  constructor(
    private _dynformService: DynamicFormService,
    public config: ConfigService
  ) {}

  ngOnInit() {
    this.setFormDefComp(true);
    // Disable the form if a value is provided and is not in the select list
    // In case list value change and data are still in database
    if (this.formDef.type_widget == 'select') {
      this._sub = this.form
        .get(this.formDefComp['attribut_name'])
        .valueChanges.pipe(distinctUntilChanged())
        .subscribe((val) => {
          // Cas ou la valeur n'est pas sélectionnée et que la valeur null n'est pas dans la liste
          if (val != null) {
            this.isValInSelectList = this.formDefComp['values']
              .map((val) => val.value)
              .includes(val);
          }
        });
    }
  }

  setFormDefComp(withDefaultValue = false) {
    const formDefComp: any = {};
    for (const key of Object.keys(this.formDef)) {
      this.formDefComp[key] = this._dynformService.getFormDefValue(
        this.formDef,
        key,
        this.form.value
      );
    }

    // traitement de values pour le type radio, select et multiselect
    // si on a une liste de valeur
    // - on la transforme en liste de dictionnaire [...{label, value}...]
    if (['radio', 'multiselect', 'select', 'checkbox'].includes(this.formDefComp.type_widget)) {
      this.formDefComp.values = this.formDefComp.values.map((val) => {
        let isValObject = typeof val === 'object' && !Array.isArray(val) && val !== null;
        return isValObject ? val : { label: val, value: val };
      });
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

  onCheckChange(event, formControl: UntypedFormControl, value) {
    let currentFormValue = Object.assign([], formControl.value);
    // Selected
    if (event.target.checked) {
      // Add a new control in the arrayForm
      currentFormValue.push(value);
      // Patch value to declench validators
      formControl.patchValue(currentFormValue);
    } else {
      // Find the unselected element
      // and patch value to declench validators
      formControl.patchValue(currentFormValue.filter((valItem) => valItem != value));
    }
  }

  onRadioChange(val, formControl: UntypedFormControl) {
    if (formControl.value === val) {
      // quand on clique sur un bouton déjà coché
      // cela décoche ce dernier
      formControl.setValue(null);
    } else {
      formControl.setValue(val);
    }
  }

  ngOnChanges(changes: SimpleChanges) {
    for (const propName of Object.keys(changes)) {
      // si le composant dynamic - form - generator annonce un update
      //   => on recalcule les propriétés
      if (propName === 'update' && this.update === true) {
        this.setFormDefComp();
      }
      if (propName !== 'update') {
        this.setFormDefComp();
      }
    }
  }

  ngOnDestroy(): void {
    if (this._sub !== undefined) {
      this._sub.unsubscribe();
    }
  }
}
