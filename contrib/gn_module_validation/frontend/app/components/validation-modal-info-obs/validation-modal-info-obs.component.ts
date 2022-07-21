import { Component, OnInit, Input, Output, EventEmitter } from "@angular/core";
import { ValidationDataService } from "../../services/data.service";
import { MapListService } from "@geonature_common/map-list/map-list.service";
import { ModuleConfig } from "../../module.config";
import { FormGroup, FormBuilder, Validators } from "@angular/forms";
import { NgbActiveModal } from "@ng-bootstrap/ng-bootstrap";
import { CommonService } from "@geonature_common/service/common.service";
import { ValidationService } from "../../services/validation.service";
@Component({
  selector: "pnx-validation-modal-info-obs",
  templateUrl: "validation-modal-info-obs.component.html",
  styleUrls: ["./validation-modal-info-obs.component.scss"],
  providers: [MapListService]
})
export class ValidationModalInfoObsComponent implements OnInit {
  public selectObsTaxonInfo;
  public filteredIds;
  public position;
  public isNextButtonValid: any;
  public isPrevButtonValid: any;
  public VALIDATION_CONFIG = ModuleConfig;
  public statusForm: FormGroup;
  public edit = false;
  public validationStatus;
  public MapListService;
  public validationDate;
  public currentCdNomenclature;
  public currentValidationStatus;

  @Input() id_synthese: any;
  @Input() uuidSynthese: any;
  @Output() modifiedStatus = new EventEmitter();
  @Output() valDate = new EventEmitter();
  @Output() onCloseModal = new EventEmitter();

  constructor(
    public mapListService: MapListService,
    private _validatioDataService: ValidationDataService,
    public activeModal: NgbActiveModal,
    private _fb: FormBuilder,
    private _commonService: CommonService,
    private _validService: ValidationService
  ) {
    // form used for changing validation status
    this.statusForm = this._fb.group({
      statut: ["", Validators.required],
      comment: [""]
    });
  }

  ngOnInit() {

    // get all id_synthese of the filtered observations:
    this.filteredIds = [];
    for (let id in this.mapListService.tableData) {
      this.filteredIds.push(this.mapListService.tableData[id].id_synthese);
    }
    this.isNextButtonValid = true;
    this.isPrevButtonValid = true;

    // disable nextButton or previousButton if first last observation selected
    this.activateNextPrevButton(this.filteredIds.indexOf(this.id_synthese));
    // call status only once on init
    this.getStatusNames();
    // to get color
    this.setValidationStatus(this.currentValidationStatus);
  }

  setValidationStatus(validStatus) {
    const color = this.VALIDATION_CONFIG.STATUS_INFO[validStatus.cd_nomenclature].color;
    this.currentValidationStatus = { ...validStatus, color: color };
  }

  setCurrentCdNomenclature(item) {
    this.currentCdNomenclature = item;
  }

  getStatusNames() {
    this._validatioDataService.getStatusNames().subscribe(
      result => {
        // get status names
        this.validationStatus = result;
        //this.validationStatus[0]
        // order item
        // put "en attente de la validation" at the end
        this.validationStatus.push(this.validationStatus[0]);
        // end remove it
        this.validationStatus.shift();
      },
      err => {
        if (err.statusText === "Unknown Error") {
          // show error message if no connexion
          this._commonService.translateToaster(
            "error",
            "ERROR: IMPOSSIBLE TO CONNECT TO SERVER (check your connection)"
          );
        } else {
          // show error message if other server error
          this._commonService.translateToaster("error", err.error);
        }
      },
    );
  }

  editStatus() {
    this.edit = !this.edit;
  }

  changeObsIndex(increment: number) {
    // add 1 to find new position
    this.position = this.filteredIds.indexOf(this.id_synthese) + increment;
    // disable next button if last observation
    this.activateNextPrevButton(this.position);

    // array value (=id_synthese) of the new position
    this.id_synthese = this.filteredIds[
      this.filteredIds.indexOf(this.id_synthese) + 1
    ];

    const syntheseRow = this.mapListService.tableData[this.position];
    this.uuidSynthese = syntheseRow.unique_id_sinp;
    this.statusForm.reset();
    this.edit = false;
  }

  closeModal() {
    this.activeModal.close();
    this.onCloseModal.emit();
  }

  backToModule(url_source, id_pk_source) {
    const link = document.createElement("a");
    link.target = "_blank";
    link.href = url_source + "/" + id_pk_source;
    link.setAttribute("visibility", "hidden");
    link.click();
  }

  onSubmit(value) {
    // post validation status form ('statusForm') for the current observation
    this._validService
      .postNewValidStatusAndUpdateUI(value, [this.id_synthese])
      .subscribe(newValidationStatus => {
        this.setValidationStatus(newValidationStatus);
        this.statusForm.reset();
        this.editStatus();
      })
  }

  cancel() {
    this.statusForm.reset();
    this.edit = false;
  }

  activateNextPrevButton(position) {
    // disable nextButton if last observation selected
    if (position == this.filteredIds.length - 1) {
      this.isNextButtonValid = false;
    } else {
      this.isNextButtonValid = true;
    }

    // disable previousButton if first observation selected
    if (position == 0) {
      this.isPrevButtonValid = false;
    } else {
      this.isPrevButtonValid = true;
    }
  }
}
