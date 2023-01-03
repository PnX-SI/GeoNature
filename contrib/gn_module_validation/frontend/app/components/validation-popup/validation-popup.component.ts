import { Component, Input, Output, EventEmitter } from '@angular/core';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { ModuleConfig } from '../../module.config';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
//import { FILTERSLIST } from "./filters-list";
import { Router } from '@angular/router';
import { ValidationDataService } from '../../services/data.service';
import { CommonService } from '@geonature_common/service/common.service';
import { ValidationService } from '../../services/validation.service';

@Component({
  selector: 'pnx-validation-popup',
  templateUrl: 'validation-popup.component.html',
  styleUrls: ['./validation-popup.component.scss'],
  providers: [MapListService],
})
export class ValidationPopupComponent {
  error: any;
  public modalRef: any;
  string_observations: string;
  public statusForm: FormGroup;
  public VALIDATION_CONFIG = ModuleConfig;
  public status;
  public plurielObservations;
  public plurielNbOffPage;
  public nbOffPage;
  public validationDate;
  public currentCdNomenclature: string;

  @Input() observations: Array<number>;
  @Input() selectedPages: Array<number>;
  @Input() nbTotalObservation: number;
  @Input() validationStatus: Array<any>;
  @Input() currentPage: any;
  @Input() validation: any;
  @Output() valStatus = new EventEmitter();

  constructor(
    private modalService: NgbModal,
    private _fb: FormBuilder,
    public dataService: ValidationDataService,
    private _commonService: CommonService,
    private _validService: ValidationService
  ) {
    // form used for changing validation status
    this.statusForm = this._fb.group({
      statut: ['', Validators.required],
      comment: [''],
    });
  }

  onSubmit(value) {
    this._validService.postNewValidStatusAndUpdateUI(value, this.observations).subscribe((data) => {
      this.closeModal();
    });
  }

  setCurrentCdNomenclature(item) {
    this.currentCdNomenclature = item.cd_nomenclature;
  }

  definePlurielObservations() {
    if (this.observations.length == 1) {
      return '';
    } else {
      return 's';
    }
  }

  definePlurielNbOffPage() {
    if (this.nbOffPage <= 1) {
      return '';
    } else {
      return 's';
    }
  }

  isAccess() {
    // disable access validation button if no row is checked
    if (this.observations.length === 0) {
      return false;
    } else {
      return true;
    }
  }

  openVerticallyCentered(content) {
    // if no error : open popup for changing validation status
    this.modalRef = this.modalService.open(content, {
      centered: true,
      size: 'lg',
      backdrop: 'static',
      windowClass: 'dark-modal',
    });
    this.getObsNboffPage();
    this.plurielObservations = this.definePlurielObservations();
    this.plurielNbOffPage = this.definePlurielNbOffPage();
  }

  getObsNboffPage() {
    this.nbOffPage = 0;
    for (let page of this.selectedPages) {
      if (page != this.currentPage) {
        this.nbOffPage = this.nbOffPage + 1;
      }
    }
  }

  closeModal() {
    // close validation status popup
    this.statusForm.reset();
    this.modalRef.close();
  }
}
