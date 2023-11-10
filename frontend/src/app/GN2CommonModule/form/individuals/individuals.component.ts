import { Component, OnInit, Input } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { Individual } from './interfaces';
import { IndividualsService } from './individuals.service';
import { NgbModal, NgbModalRef } from '@ng-bootstrap/ng-bootstrap';
@Component({
  selector: 'pnx-individuals',
  templateUrl: './individuals.component.html',
  styleUrls: ['./individuals.component.scss'],
})
export class IndividualsComponent implements OnInit {
  @Input() parentFormControl: UntypedFormControl;
  @Input() idModule: number;
  @Input() label: string;
  @Input() idList: null | string = null;
  @Input() cdNom: null | number = null;

  keyLabel: string = 'individual_name';
  keyValue: string = 'id_individual';
  values: Individual[] = [];
  public modal: NgbModalRef;

  constructor(private modalService: NgbModal, private _individualsService: IndividualsService) {}
  ngOnInit(): void {
    console.log(this.idList);
    this.getIndividuals().subscribe((data) => {
      this.values = data;
    });
  }

  getIndividuals() {
    return this._individualsService.getIndividuals(this.idModule);
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
}
