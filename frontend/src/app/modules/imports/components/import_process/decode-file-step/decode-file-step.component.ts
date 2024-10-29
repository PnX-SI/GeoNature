import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { ImportDataService } from '../../../services/data.service';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { ImportProcessService } from '../import-process.service';
import { Step } from '../../../models/enums.model';
import { Import } from '../../../models/import.model';
import { Observable } from 'rxjs';
import { finalize } from 'rxjs/operators';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'decode-file-step',
  styleUrls: ['decode-file-step.component.scss'],
  templateUrl: 'decode-file-step.component.html',
})
export class DecodeFileStepComponent implements OnInit {
  public step: Step;
  public importData: Import;
  public paramsForm: FormGroup;
  public isRequestPending: boolean = false; // spinner

  constructor(
    private fb: FormBuilder,
    private ds: ImportDataService,
    private importProcessService: ImportProcessService,
    private route: ActivatedRoute,
    public config: ConfigService
  ) {
    this.paramsForm = this.fb.group({
      encoding: [null, Validators.required],
      format: [null, Validators.required],
      srid: [null, Validators.required],
      separator: [null, Validators.required],
    });
  }

  ngOnInit() {
    this.step = this.route.snapshot.data.step;
    this.importData = this.importProcessService.getImportData();
    if (this.importData.encoding) {
      this.paramsForm.patchValue({ encoding: this.importData.encoding });
    } else if (this.importData.detected_encoding) {
      this.paramsForm.patchValue({ encoding: this.importData.detected_encoding });
    }
    if (this.importData.format_source_file) {
      this.paramsForm.patchValue({ format: this.importData.format_source_file });
    } else if (this.importData.detected_format) {
      this.paramsForm.patchValue({ format: this.importData.detected_format });
    }
    if (this.importData.srid) {
      this.paramsForm.patchValue({ srid: this.importData.srid });
    }
    if (this.importData.separator) {
      this.paramsForm.patchValue({ separator: this.importData.separator });
    } else if (this.importData.detected_separator) {
      this.paramsForm.patchValue({ separator: this.importData.detected_separator });
    }
  }

  onPreviousStep() {
    this.importProcessService.navigateToPreviousStep(this.step);
  }

  isNextStepAvailable() {
    return this.paramsForm.valid;
  }
  onSaveData(decode = 0): Observable<Import> {
    return this.ds.decodeFile(this.importData.id_import, this.paramsForm.value, decode);
  }
  onSubmit() {
    if (this.paramsForm.pristine && this.importData.step > Step.Decode) {
      this.importProcessService.navigateToNextStep(this.step);
      return;
    }
    this.isRequestPending = true;
    this.onSaveData(1)
      .pipe(
        finalize(() => {
          this.isRequestPending = false;
        })
      )
      .subscribe((res) => {
        this.importProcessService.setImportData(res);
        this.importProcessService.navigateToLastStep();
      });
  }
}
