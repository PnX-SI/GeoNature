import { Component, OnInit } from "@angular/core";
import { ActivatedRoute } from "@angular/router";
import { Observable } from "rxjs";
import { DataService } from "../../../services/data.service";
import { CommonService } from "@geonature_common/service/common.service";
import { FormGroup, FormBuilder, Validators } from "@angular/forms";
import { Step } from "../../../models/enums.model";
import { Import } from "../../../models/import.model";
import { ImportProcessService } from "../import-process.service";
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: "upload-file-step",
  styleUrls: ["upload-file-step.component.scss"],
  templateUrl: "upload-file-step.component.html"
})
export class UploadFileStepComponent implements OnInit {
  public step: Step;
  public importData: Import;
  public datasetId: number = null;
  public uploadForm: FormGroup;
  public file: File | null = null;
  public fileName: string;
  public isUploadRunning: boolean = false;
  public maxFileSize: number = 0;
  public emptyError: boolean = false;
  public columnFirstError: boolean = false;
  public maxFileNameLength: number = 255;
  public acceptedExtensions: string = null;

  constructor(
    private ds: DataService,
    private commonService: CommonService,
    private fb: FormBuilder,
    private importProcessService: ImportProcessService,
    private route: ActivatedRoute,
    public config: ConfigService
  ) {
    this.acceptedExtensions = this.config.IMPORT.ALLOWED_EXTENSIONS.toString();
    this.maxFileSize = this.config.IMPORT.MAX_FILE_SIZE;

    this.uploadForm = this.fb.group({
      file: [null, Validators.required],
      fileName: [null, [Validators.required, Validators.maxLength(this.maxFileNameLength)]],
    });
  }

  ngOnInit() {
    this.step = this.route.snapshot.data.step;
    this.importData = this.importProcessService.getImportData();
    if (this.importData === null) {
      this.datasetId = this.route.snapshot.queryParams["datasetId"];
    } else {
      this.fileName = this.importData.full_file_name;
    }
  }

  isNextStepAvailable() {
    if (this.isUploadRunning) {
      return false;
    } else if (this.importData && this.uploadForm.pristine) {
      return true;
    } else {
      return this.uploadForm.valid && this.file && this.file.size < this.maxFileSize * 1024 * 1024 && this.file.size;
    }
  }

  onFileSelected(file: File) {
    this.emptyError = this.columnFirstError = false;
    this.file = file;
    this.fileName = file.name;
    this.uploadForm.setValue({
        file: this.file,
        fileName: this.fileName,
    });
    this.uploadForm.markAsDirty();
  }
  onSaveData(): Observable<Import> {
      if (this.importData) {
          return this.ds.updateFile(this.importData.id_import, this.file);
      } else {
          return this.ds.addFile(this.datasetId, this.file);
      }
  }
  onNextStep() {
      if (this.uploadForm.pristine) {
          this.importProcessService.navigateToNextStep(this.step);
          return;
      }
      this.isUploadRunning = true;
      this.onSaveData().subscribe(
            res => {
              this.isUploadRunning = false;
              this.importProcessService.setImportData(res);
              this.importProcessService.navigateToLastStep();
            },
            error => {
              this.isUploadRunning = false;
              this.commonService.regularToaster("error", error.error.description);
              if (error.status === 400) {
                  if (error.error && error.error.description === "Impossible to upload empty files") {
                      this.emptyError = true
                  }
                  if (error.error && error.error.description === "File must start with columns") {
                      this.columnFirstError = true
                  }
              }
            },
        );
  }
}
