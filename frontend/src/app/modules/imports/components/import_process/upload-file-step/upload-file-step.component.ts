import { Component, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { combineLatest, Observable } from 'rxjs';
import { ImportDataService } from '../../../services/data.service';
import { CommonService } from '@geonature_common/service/common.service';
import { FormGroup, FormBuilder, Validators, FormControl } from '@angular/forms';
import { Step } from '../../../models/enums.model';
import { Destination, Import } from '../../../models/import.model';
import { ImportProcessService } from '../import-process.service';
import { ConfigService } from '@geonature/services/config.service';
import { NgbModal } from '@librairies/@ng-bootstrap/ng-bootstrap';
import { ModalData } from '@geonature/modules/imports/models/modal-data.model';
import { switchMap } from 'rxjs/operators';
import { FieldMappingValues } from '@geonature/modules/imports/models/mapping.model';
import { formatQueryParams } from '@geonature/modules/imports/utils/format-to-fieldsmapping';

@Component({
  selector: 'upload-file-step',
  styleUrls: ['upload-file-step.component.scss'],
  templateUrl: 'upload-file-step.component.html',
})
export class UploadFileStepComponent implements OnInit {
  @ViewChild('editModal') editModal!: TemplateRef<any>;
  public step: Step;
  public importData: Import;
  public uploadForm: FormGroup;
  public file: File | null = null;
  public fileName: string;
  public isUploadRunning: boolean = false;
  public maxFileSize: number = 0;
  public emptyError: boolean = false;
  public columnFirstError: boolean = false;
  public maxFileNameLength: number = 255;
  public acceptedExtensions: string = null;
  public destination: Destination = null;
  public modalData: ModalData;
  public paramsFieldMapping: FieldMappingValues;

  constructor(
    private ds: ImportDataService,
    private commonService: CommonService,
    private fb: FormBuilder,
    private importProcessService: ImportProcessService,
    private route: ActivatedRoute,
    public config: ConfigService,
    private modal: NgbModal
  ) {
    this.acceptedExtensions = this.config.IMPORT.ALLOWED_EXTENSIONS.toString();
    this.maxFileSize = this.config.IMPORT.MAX_FILE_SIZE;

    this.uploadForm = this.fb.group({
      file: [null, Validators.required],
      fileName: [null, [Validators.required, Validators.maxLength(this.maxFileNameLength)]],
    });
  }

  ngOnInit() {
    this.setupDatasetSelect();
  }

  setupDatasetSelect() {
    combineLatest([this.route.parent.queryParams, this.route.parent?.params || []])
      .pipe(
        switchMap(([queryParams, parentParams]) => {
          this.paramsFieldMapping = formatQueryParams(queryParams);
          const destinationLabel = parentParams['destination'];
          return this.ds.getDestination(destinationLabel);
        })
      )
      .subscribe((destination) => {
        this.destination = destination;
      });
    this.step = this.route.snapshot.data.step;
    this.importData = this.importProcessService.getImportData();
    if (this.importData) {
      this.fileName = this.importData.full_file_name;
    }
  }

  isNextStepAvailable() {
    if (this.isUploadRunning) {
      return false;
    } else if (this.importData && this.uploadForm.pristine) {
      return true;
    } else {
      return (
        this.uploadForm.valid &&
        this.file &&
        this.file.size < this.maxFileSize * 1024 * 1024 &&
        this.file.size
      );
    }
  }

  onFileSelected(file: File) {
    this.emptyError = this.columnFirstError = false;
    this.file = file;
    this.fileName = file.name;
    this.uploadForm.patchValue({
      file: this.file,
      fileName: this.fileName,
    });
    this.uploadForm.markAsDirty();
  }
  onSaveData(): Observable<Import> {
    if (this.importData) {
      return this.ds.updateFile(this.importData.id_import, this.file, this.paramsFieldMapping);
    } else {
      return this.ds.addFile(this.file, this.paramsFieldMapping);
    }
  }

  onNextStep() {
    if (this.uploadForm.pristine) {
      this.importProcessService.navigateToNextStep(this.step);
      return;
    }
    this.isUploadRunning = true;
    this.onSaveData().subscribe(
      (res) => {
        this.isUploadRunning = false;
        this.importProcessService.setImportData(res);
        this.importProcessService.navigateToLastStep();
      },
      (error) => {
        this.isUploadRunning = false;
        this.commonService.regularToaster('error', error.error.description);
        if (error.status === 400) {
          if (error.error && error.error.description === 'Impossible to upload empty files') {
            this.emptyError = true;
          }
          if (error.error && error.error.description === 'File must start with columns') {
            this.columnFirstError = true;
          }
        }
      }
    );
  }

  checkBeforeNextStep() {
    if (this.importData?.fieldmapping) {
      this.openModal(this.editModal);
      return;
    } else {
      this.onNextStep();
    }
  }

  openModal(editModal: TemplateRef<any>) {
    this.modalData = {
      title: 'Modification',
      bodyMessage: 'Le fichier existant en base de données sera supprimé !',
      additionalMessage: 'Êtes-vous sûr de continuer ?',
      cancelButtonText: 'Annuler',
      confirmButtonText: 'Confirmer',
      confirmButtonColor: 'warn',
      headerDataQa: 'import-modal-edit',
      confirmButtonDataQa: 'modal-edit-validate',
    };
    this.modal.open(editModal);
  }

  handleModalAction(event: { confirmed: boolean; actionType: string; data?: any }) {
    if (event.confirmed) {
      if (event.actionType === 'edit') {
        this.onNextStep();
      }
    }
  }
}
