import { Component, Output, EventEmitter, Input, OnInit } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { Validators } from '@angular/forms';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { NgbTypeaheadSelectItemEvent } from '@ng-bootstrap/ng-bootstrap';
import { IndividualsService } from '../individuals.service';
import { Individual } from '../interfaces';
import { throwError } from 'rxjs';
@Component({
  selector: 'pnx-individuals-create',
  templateUrl: './individuals-create.component.html',
  styleUrls: ['./individuals-create.component.scss'],
})
export class IndividualsCreateComponent implements OnInit {
  @Input() idModule: null | number = null;
  @Input() idList: null | string = null;
  @Input() cdNom: null | number = null;
  @Output() individualEvent = new EventEmitter<Individual>();
  @Output() cancelEvent = new EventEmitter();

  form: FormGroup<{
    individual_name: FormControl<string>;
    id_nomenclature_sex: FormControl<number | null>;
    cd_nom: FormControl<number | null>;
    cd_nom_temp: FormControl<number | null>;
    comment: FormControl<string>;
  }>;

  constructor(private _individualsService: IndividualsService) {}

  ngOnInit() {
    this.form = new FormGroup({
      individual_name: new FormControl<string>('', {
        validators: [Validators.required],
      }),
      id_nomenclature_sex: new FormControl<number | null>(null),
      cd_nom: new FormControl<number | null>(this.cdNom, {
        validators: [Validators.required],
      }),
      // Normally we could avoid providing a form to taxonomy
      // widget, but it needs it and affecting the entire taxon
      // to the form control. Creating a temp one to fix this problem
      cd_nom_temp: new FormControl<number | null>(this.cdNom, {
        validators: [Validators.required],
      }),
      comment: new FormControl<string>(''),
    });
  }

  taxonSelected(value: NgbTypeaheadSelectItemEvent<Taxon>) {
    this.form.patchValue({ cd_nom: value.item.cd_nom });
  }

  createIndividual() {
    const value = this.form.getRawValue();
    delete value.cd_nom_temp;
    this._individualsService
      .postIndividual(value as Individual, this.idModule)
      .subscribe((value) => this.individualEvent.emit(value));
  }

  cancelCreate() {
    this.cancelEvent.emit();
  }
}
