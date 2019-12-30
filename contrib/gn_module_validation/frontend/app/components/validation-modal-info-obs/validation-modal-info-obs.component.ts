import { Component, OnInit, Input, Output, EventEmitter } from "@angular/core";
import { ValidationDataService } from "../../services/data.service";
import { SyntheseDataService } from "@geonature_common/form/synthese-form/synthese-data.service";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { AppConfig } from "@geonature_config/app.config";
import { MapListService } from "@geonature_common/map-list/map-list.service";
import { ModuleConfig } from "../../module.config";
import { FormGroup, FormBuilder, Validators } from "@angular/forms";
import { NgbActiveModal } from "@ng-bootstrap/ng-bootstrap";
import { CommonService } from "@geonature_common/service/common.service";

@Component({
  selector: "pnx-validation-modal-info-obs",
  templateUrl: "validation-modal-info-obs.component.html",
  styleUrls: ["./validation-modal-info-obs.component.scss"],
  providers: [MapListService]
})
export class ValidationModalInfoObsComponent implements OnInit {
  public selectObsTaxonInfo;
  public selectedObs;
  public selectedObsTaxonDetail;
  public validationHistory: any;
  public SYNTHESE_CONFIG = AppConfig.SYNTHESE;
  public APP_CONFIG = AppConfig;
  public filteredIds;
  public id_synthese;
  public position;
  public lastFilteredValue;
  public isNextButtonValid: any;
  public isPrevButtonValid: any;
  public VALIDATION_CONFIG = ModuleConfig;
  public statusForm: FormGroup;
  public edit;
  public validationStatus;
  public MapListService;
  public email;
  public mailto: String;
  public showEmail;
  public validationDate;
  public currentCdNomenclature;
 
  @Input() oneObsSynthese: any;
  @Output() modifiedStatus = new EventEmitter();
  @Output() valDate = new EventEmitter();
 
  constructor(
    public mapListService: MapListService,
    private _gnDataService: DataFormService,
    private _validatioDataService: ValidationDataService,
    private _syntheseDataService: SyntheseDataService,
    public activeModal: NgbActiveModal,
    private _fb: FormBuilder,
    private _commonService: CommonService
  ) {
    // form used for changing validation status
    this.statusForm = this._fb.group({
      statut: ["", Validators.required],
      comment: [""]
    });
  }
 
  ngOnInit() {
    this.id_synthese = this.oneObsSynthese.id_synthese;
    this.loadOneSyntheseReleve(this.oneObsSynthese);
    this.loadValidationHistory(this.oneObsSynthese.unique_id_sinp);

    // get all id_synthese of the filtered observations:
    this.filteredIds = [];
    for (let id in this.mapListService.tableData) {
      this.filteredIds.push(this.mapListService.tableData[id].id_synthese);
    }
    this.isNextButtonValid = true;
    this.isPrevButtonValid = true;
 
    // disable nextButton if last observation selected
    if (
      this.filteredIds.indexOf(this.id_synthese) ==
      this.filteredIds.length - 1
    ) {
      this.isNextButtonValid = false;
    } else {
      this.isNextButtonValid = true;
    }
 
    // disable previousButton if first observation selected
    if (this.filteredIds.indexOf(this.id_synthese) == 0) {
      this.isPrevButtonValid = false;
    } else {
      this.isPrevButtonValid = true;
    }
 
    this.edit = false;
    this.showEmail = false;
  }

  setCurrentCdNomenclature(item) {
    this.currentCdNomenclature = item.cd_nomenclature;
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
      () => {
        this.edit = true;
      }
    );
  }
 
  loadOneSyntheseReleve(oneObsSynthese) {
    this._syntheseDataService
      .getOneSyntheseObservation(oneObsSynthese.id_synthese)
      .subscribe(data => {
        this.selectedObs = data;
        this.selectedObs["municipalities"] = [];
        this.selectedObs["other_areas"] = [];
        const date_min = new Date(this.selectedObs.date_min);
        this.selectedObs.date_min = date_min.toLocaleDateString("fr-FR");
        const date_max = new Date(this.selectedObs.date_max);
        this.selectedObs.date_max = date_max.toLocaleDateString("fr-FR");
        if (this.selectedObs.cor_observers) {
          this.email = this.selectedObs.cor_observers
            .map(el => el.email)
            .join();
          this.mailto = String("mailto:" + this.email);
        }
      });

    this._gnDataService
      .getTaxonAttributsAndMedia(
        oneObsSynthese.cd_nom,
        this.SYNTHESE_CONFIG.ID_ATTRIBUT_TAXHUB
      )
      .subscribe(data => {
        this.selectObsTaxonInfo = data;
      });

    this._gnDataService.getTaxonInfo(oneObsSynthese.cd_nom).subscribe(data => {
      this.selectedObsTaxonDetail = data;
    });
  }
 
  loadValidationHistory(uuid) {
    this._validatioDataService.getValidationHistory(uuid).subscribe(
      data => {
        this.validationHistory = data;
        for (let row in this.validationHistory) {
          // format date
          const date = new Date(this.validationHistory[row].date);
          this.validationHistory[row].date = date.toLocaleDateString("fr-FR");
          // format comments
          if (
            this.validationHistory[row].comment == "None" ||
            this.validationHistory[row].comment == "auto = default value"
          ) {
            this.validationHistory[row].comment = "";
          }
          // format validator
          if (this.validationHistory[row].typeValidation == "True") {
            this.validationHistory[row].validator = "Attribution automatique";
            //this.mapListService.tableData[row]['validation_auto'] = '';
          }
        }
      },
      err => {
        console.log(err);
        if (err.status == 404) {
          this._commonService.translateToaster(
            "warning",
            "Aucun historique de validation"
          );
        } else if (err.statusText === "Unknown Error") {
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
      () => {
        //console.log(this.statusNames);
      }
    );
  }

  increaseObs() {
    this.showEmail = false;
    // add 1 to find new position
    this.position = this.filteredIds.indexOf(this.id_synthese) + 1;
    // disable next button if last observation
    if (this.position == this.filteredIds.length - 1) {
      this.isNextButtonValid = false;
    } else {
      this.isNextButtonValid = true;
    }
 
    // array value (=id_synthese) of the new position
    this.id_synthese = this.filteredIds[
      this.filteredIds.indexOf(this.id_synthese) + 1
    ];
    const syntheseRow = this.mapListService.tableData[this.position]
    
    this.loadOneSyntheseReleve(syntheseRow);
    this.loadValidationHistory(syntheseRow.unique_id_sinp);
    this.isPrevButtonValid = true;
    this.statusForm.reset();
    this.edit = false;
  }
 
  decreaseObs() {
    this.showEmail = false;
    // substract 1 to find new position
    this.position = this.filteredIds.indexOf(this.id_synthese) - 1;
    // disable previous button if first observation
    if (this.position == 0) {
      this.isPrevButtonValid = false;
    } else {
      this.isPrevButtonValid = true;
    }
 
    // array value (=id_synthese) of the new position
    this.id_synthese = this.filteredIds[
      this.filteredIds.indexOf(this.id_synthese) - 1
    ];
    const syntheseRow = this.mapListService.tableData[this.position]

    this.loadOneSyntheseReleve(syntheseRow);
    this.loadValidationHistory(syntheseRow.unique_id_sinp);
    this.isNextButtonValid = true;
    this.statusForm.reset();
    this.edit = false;
  }
 
  isEmail() {
    this.showEmail = true;
    return this.showEmail;
  }
 
  closeModal() {
    this.showEmail = false;
    this.activeModal.close();
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
    return this._validatioDataService
      .postStatus(value, this.id_synthese)
      .toPromise()
      .then(data => {
        /** TODO à virer ? ** this.promiseResult = data as JSON; **/
        //console.log('retour du post : ', this.promiseResult);
        return new Promise((resolve, reject) => {
          // show success message indicating the number of observation(s) with modified validation status
          this._commonService.translateToaster(
            "success",
            "Nouveau statut de validation enregistré"
          );
          this.update_status();
          this.getValidationDate(this.oneObsSynthese.unique_id_sinp);
          this.loadOneSyntheseReleve(this.oneObsSynthese);
          this.loadValidationHistory(this.oneObsSynthese.unique_id_sinp);
          // bind statut value with validation-synthese-list component
          this.statusForm.reset();
          resolve("data updated");
        });
      })
      .catch(err => {
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
        Promise.reject();
      })
      .then(data => {
        //console.log(data);
        return new Promise((resolve, reject) => {
          // close validation status popup
          this.edit = false;
          resolve("process finished");
        });
      })
      .then(data => {
        //console.log(data);
      });
  }
 
  update_status() {
    // send valstatus value to validation-synthese-list component
    this.modifiedStatus.emit({
      id_synthese: this.id_synthese,
      new_status: this.currentCdNomenclature
    });
  }
 
  cancel() {
    this.statusForm.reset();
    this.edit = false;
  }
 
  getValidationDate(uuid) {
    this._validatioDataService.getValidationDate(uuid).subscribe(
      result => {
        // get status names
        this.validationDate = result;
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
      () => {
        this.valDate.emit(this.validationDate);
      }
    );
  }
}