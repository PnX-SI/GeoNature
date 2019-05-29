import { stringify } from 'wellknown';
import { Component, OnInit, Input, Output, EventEmitter, ViewChild } from '@angular/core';
import { DataService } from '../../services/data.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { AppConfig } from '@geonature_config/app.config';
import { MatTabsModule } from '@angular/material/tabs';
import { ToastrService } from 'ngx-toastr';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { ModuleConfig } from "../../module.config";
import { FormControl, FormGroup, FormBuilder, Validators } from '@angular/forms';
import { NgbModal, NgbActiveModal, ModalDismissReasons } from "@ng-bootstrap/ng-bootstrap";

@Component({
  selector: 'pnx-validation-modal-info-obs',
  templateUrl: 'validation-modal-info-obs.component.html',
  styleUrls: ["./validation-modal-info-obs.component.scss"],
  providers: [MapListService]
})

export class ValidationModalInfoObsComponent implements OnInit {

  public selectObsTaxonInfo;
  public selectedObs;
  public selectedObsTaxonDetail;
  public validationHistory: any;
  public SYNTHESE_CONFIG = AppConfig.SYNTHESE;
  public filteredIds;
  public id_synthese;
  public position;
  public lastFilteredValue;
  public isNextButtonValid: any;
  public isPrevButtonValid: any;
  public VALIDATION_CONFIG = ModuleConfig;
  public statusForm: FormGroup;
  public edit;
  //public statusKeys2;
  public statusKeys;
  public statusNames;
  public MapListService;
  public email;
  public mailto: String;
  public showEmail;
  public validationDate;


  @Input() inputSyntheseData: GeoJSON;
  @Input() oneObsSynthese: any;
  @Output() modifiedStatus = new EventEmitter();
  @Output() valDate = new EventEmitter();
  @ViewChild('table') table: DatatableComponent;

  constructor(
    public mapListService: MapListService,
    private _gnDataService: DataFormService,
    private _dataService: DataService,
    public activeModal: NgbActiveModal,
    private toastr: ToastrService,
    private _fb: FormBuilder
  ) {
    // form used for changing validation status
    this.statusForm = this._fb.group({
      statut: ['', Validators.required],
      comment: ['']
    });
  }

  ngOnInit() {
    this.id_synthese = this.oneObsSynthese.id_synthese;
    this.loadOneSyntheseReleve(this.oneObsSynthese);
    this.loadValidationHistory(this.id_synthese);


    // get all id_synthese of the filtered observations:
    this.filteredIds = [];
    for (let id in this.mapListService.tableData) {
      this.filteredIds.push(this.mapListService.tableData[id].id_synthese);
    }
    this.isNextButtonValid = true;
    this.isPrevButtonValid = true;

    // disable nextButton if last observation selected
    if (this.filteredIds.indexOf(this.id_synthese) == this.filteredIds.length - 1) {
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

  getStatusNames() {
    this._dataService.getStatusNames().subscribe(
      result => {
        // get status names
        this.statusNames = result;
        this.statusKeys = Object.keys(this.VALIDATION_CONFIG.STATUS_INFO);
      },
      err => {
        if (err.statusText === 'Unknown Error') {
          // show error message if no connexion
          this.toastr.error('ERROR: IMPOSSIBLE TO CONNECT TO SERVER (check your connexion)');
        } else {
          // show error message if other server error
          this.toastr.error(err.error);
        }
      },
      () => {
        this.edit = true;
      }
    );
  }

  loadOneSyntheseReleve(oneObsSynthese) {
    this._dataService.getOneSyntheseObservation(oneObsSynthese.id_synthese)
      .subscribe(
        data => {
          this.selectedObs = data;          
          this.selectedObs['municipalities'] = [];
          this.selectedObs['other_areas'] = [];
          const date_min = new Date(this.selectedObs.date_min);
          this.selectedObs.date_min = date_min.toLocaleDateString('fr-FR');
          const date_max = new Date(this.selectedObs.date_max);
          this.selectedObs.date_max = date_max.toLocaleDateString('fr-FR');
          this.email = this.selectedObs.cor_observers.map(el => el.email).join();
          this.mailto = String("mailto:" + this.email);
          console.log(this.selectedObs);
          
        }
      );

    this._gnDataService.getTaxonAttributsAndMedia(oneObsSynthese.cd_nom, this.SYNTHESE_CONFIG.ID_ATTRIBUT_TAXHUB)
      .subscribe(
        data => {
          this.selectObsTaxonInfo = data;
        }
      );

    this._gnDataService.getTaxonInfo(oneObsSynthese.cd_nom)
      .subscribe(
        data => {
          this.selectedObsTaxonDetail = data;
        }
      );
  }

  loadValidationHistory(id) {
    this._dataService.getValidationHistory(id)
      .subscribe(
        data => {
          this.validationHistory = data;
          for (let row in this.validationHistory) {
            // format date
            const date = new Date(this.validationHistory[row].date);
            this.validationHistory[row].date = date.toLocaleDateString('fr-FR');
            // format comments
            if (this.validationHistory[row].comment == 'None' || this.validationHistory[row].comment == 'auto = default value') {
              this.validationHistory[row].comment = '';
            }
            // format validator
            if (this.validationHistory[row].typeValidation == 'True' {
              this.validationHistory[row].validator = 'Attribution automatique';
              //this.mapListService.tableData[row]['validation_auto'] = '';
            }
          }
        },
        err => {
          console.log(err.error);
          if (err.statusText === 'Unknown Error') {
            // show error message if no connexion
            this.toastr.error('ERROR: IMPOSSIBLE TO CONNECT TO SERVER (check your connexion)');
          } else {
            // show error message if other server error
            this.toastr.error(err.error);
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
    this.id_synthese = this.filteredIds[this.filteredIds.indexOf(this.id_synthese) + 1];
    this.loadOneSyntheseReleve(this.mapListService.tableData[this.position]);
    this.loadValidationHistory(this.id_synthese);
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
    this.id_synthese = this.filteredIds[this.filteredIds.indexOf(this.id_synthese) - 1];

    this.loadOneSyntheseReleve(this.mapListService.tableData[this.position]);
    this.loadValidationHistory(this.id_synthese);
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
    const link = document.createElement('a');
    link.target = '_blank';
    link.href = url_source + '/' + id_pk_source;
    link.setAttribute('visibility', 'hidden');
    link.click();
  }

  onSubmit(value) {
    // post validation status form ('statusForm') for the current observation
    return this._dataService.postStatus(value, this.id_synthese).toPromise()
      .then(
        data => {
          this.promiseResult = data as JSON;
          //console.log('retour du post : ', this.promiseResult);
          return new Promise((resolve, reject) => {
            // show success message indicating the number of observation(s) with modified validation status
            this.toastr.success('Nouveau statut de validation enregistré');
            this.update_status();
            this.getValidationDate(this.id_synthese);
            this.loadOneSyntheseReleve(this.oneObsSynthese);
            this.loadValidationHistory(this.id_synthese);
            // bind statut value with validation-synthese-list component
            this.statusForm.reset();
            resolve('data updated');
          }
      })
      .catch(
        err => {
          if (err.statusText === 'Unknown Error') {
            // show error message if no connexion
            this.toastr.error('ERROR: IMPOSSIBLE TO CONNECT TO SERVER (check your connexion)');
          } else {
            // show error message if other server error
            this.toastr.error(err.error);
          }
          reject();
        }
      )
      .then(
        data => {
          //console.log(data);
          return new Promise((resolve, reject) => {
            // close validation status popup
            this.edit = false;
            resolve('process finished');
          }
    })
      .then(
        data => {
          //console.log(data);
        }
      );
  }

  update_status() {
    // send valstatus value to validation-synthese-list component
    this.modifiedStatus.emit({
      id_synthese: this.id_synthese,
      new_status: this.statusForm.controls['statut'].value
    });
  }

  cancel() {
    this.statusForm.reset();
    this.edit = false;
  }

  getValidationDate(id) {
    this._dataService.getValidationDate(id).subscribe(
      result => {
        // get status names
        this.validationDate = result;
      },
      err => {
        if (err.statusText === 'Unknown Error') {
          // show error message if no connexion
          this.toastr.error('ERROR: IMPOSSIBLE TO CONNECT TO SERVER (check your connexion)');
        } else {
          // show error message if other server error
          this.toastr.error(err.error);
        }
      },
      () => {
        this.valDate.emit(this.validationDate);
      }
    );
  }

}
