import {
  Component,
  OnInit,
  Input,
  Output,
  EventEmitter,
  OnChanges,
  SimpleChanges,
} from '@angular/core';
import { UntypedFormControl, UntypedFormGroup } from '@angular/forms';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { NgbModal, NgbModalRef, NgbTypeaheadSelectItemEvent } from '@ng-bootstrap/ng-bootstrap';
import { Individual } from './interfaces';
import { IndividualsService } from './individuals.service';
import { tap } from '@librairies/rxjs/operators';

@Component({
  selector: 'pnx-individuals',
  templateUrl: './individuals.component.html',
})
export class IndividualsComponent implements OnInit, OnChanges {
  @Input() parentFormControl: UntypedFormControl;
  @Input() idModule: number;
  @Input() label: string;
  @Input() idList: null | string = null;
  @Input() cdNom: null | number = null;
  @Input() showAddButton: boolean = true;
  @Input() displayAdvancedFilters: boolean = false;
  @Input() placeholder: string = '';
  @Input() multiselect: boolean = false;
  @Output() nbIndividuals = new EventEmitter<number>();

  keyLabel: string = 'individual_name';
  keyValue: string = 'id_individual';
  values: Individual[] = [];
  public isCollapseFilters = true;
  public modal: NgbModalRef;

  // Filters displayed in the advanced filters panel
  filtersForm = new UntypedFormGroup({
    id_nomenclature_sex: new UntypedFormControl(null),
    cd_nom: new UntypedFormControl(null),
  });
  // Temporary control required by pnx-taxonomy, the resulting cd_nom is
  // reported to filtersForm through the (onChange) event
  taxonomyFilterControl = new UntypedFormControl(null);

  constructor(
    private modalService: NgbModal,
    private _individualsService: IndividualsService
  ) {}

  ngOnInit(): void {
    this.filtersForm.patchValue({ cd_nom: this.cdNom }, { emitEvent: false });
    this.refreshIndividuals();
    this.filtersForm.valueChanges.subscribe(() => this.refreshIndividuals());
  }

  refreshIndividuals() {
    const { cd_nom, active, id_nomenclature_sex } = this.filtersForm.value;
    this.getIndividuals(cd_nom, active, id_nomenclature_sex).subscribe((data) => {
      this.values = data;
    });
  }

  refreshFilters() {
    this.filtersForm.reset();
  }

  getIndividuals(
    cd_nom: number | null = null,
    active: boolean | null = null,
    id_nomenclature_sex: number | null = null
  ) {
    return this._individualsService
      .getIndividuals(this.idModule, cd_nom, active, id_nomenclature_sex)
      .pipe(
        tap((individuals: Individual[]) => {
          this.nbIndividuals.emit(individuals.length);
        })
      );
  }

  taxonFilterSelected(event: NgbTypeaheadSelectItemEvent<Taxon>) {
    this.filtersForm.patchValue({ cd_nom: event.item.cd_nom });
  }

  openModal(content: any) {
    // if no error : open popup for changing validation status
    this.modal = this.modalService.open(content, {
      centered: true,
      size: 'lg',
    });
  }

  closeModal() {
    if (this.modal) this.modal.close();
  }

  individualCreated(value: Individual) {
    this.closeModal();
    this.refreshIndividuals();
    this.parentFormControl.setValue(value.id_individual);
  }

  ngOnChanges(changes: SimpleChanges) {
    if (changes.cdNom && !changes.cdNom.firstChange) {
      this.filtersForm.patchValue({ cd_nom: changes.cdNom.currentValue });
    }
  }
}
