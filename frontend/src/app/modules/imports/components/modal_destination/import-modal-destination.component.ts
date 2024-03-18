import { Component, OnInit, OnDestroy } from '@angular/core';
import { NgbModal, NgbModalRef } from '@ng-bootstrap/ng-bootstrap';
import { FormControl, Validators } from '@angular/forms';
import { ImportDataService } from '../../services/data.service';
import { ImportProcessService } from '../import_process/import-process.service';
import { CruvedStoreService } from '@geonature_common/service/cruved-store.service';

@Component({
  selector: 'import-modal-destination',
  templateUrl: 'import-modal-destination.component.html',
  styleUrls: ['./import-modal-destination.component.scss'],
})
export class ImportModalDestinationComponent implements OnInit, OnDestroy {
  public selectDestinationForm: FormControl;
  public userDestinationResponse: any;
  public destinationResponse: JSON;
  public isUserDestinationError: Boolean = false;
  public DestinationError: string;
  private modalRef: NgbModalRef;

  constructor(
    private modalService: NgbModal,
    public _ds: ImportDataService,
    private importProcessService: ImportProcessService,
    public cruvedStore: CruvedStoreService
  ) {}

  ngOnInit() {
    this.selectDestinationForm = new FormControl(null, Validators.required);
  }

  onOpenModal(content) {
    this.modalRef = this.modalService.open(content, {
      size: 'lg',
    });
  }

  closeModal() {
    if (this.modalRef) this.modalRef.close();
  }

  onSubmit() {
    this.importProcessService.beginProcess(this.selectDestinationForm.value);
    this.closeModal();
  }

  ngOnDestroy(): void {
    this.closeModal();
  }
}
