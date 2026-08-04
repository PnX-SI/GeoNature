import {
  Component,
  OnInit,
  Input,
  Output,
  EventEmitter,
  OnChanges,
  SimpleChanges,
} from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { Individual } from './interfaces';
import { IndividualsService } from './individuals.service';
import { NgbModal, NgbModalRef } from '@ng-bootstrap/ng-bootstrap';
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
  @Output() nbIndividuals = new EventEmitter<number>();

  keyLabel: string = 'individual_name';
  keyValue: string = 'id_individual';
  values: Individual[] = [];
  public modal: NgbModalRef;

  constructor(
    private modalService: NgbModal,
    private _individualsService: IndividualsService
  ) {}
  ngOnInit(): void {
    this.getIndividuals().subscribe((data) => {
      this.values = data.filter((item) => item.active);
    });
  }

  getIndividuals(cd_nom: number | null = null) {
    return this._individualsService.getIndividuals(this.idModule, cd_nom).pipe(
      tap((individuals: any) => {
        this.nbIndividuals.emit(individuals.length);
      })
    );
  }

  openModal(content) {
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
    this.getIndividuals().subscribe((data) => {
      this.values = data;
      this.parentFormControl.setValue(value.id_individual);
    });
  }

  ngOnChanges(changes: any) {
    if (changes.cdNom && changes.cdNom.currentValue) {
      this.getIndividuals(changes.cdNom.currentValue).subscribe((data) => {
        this.values = data;
      });
    }
  }
}
