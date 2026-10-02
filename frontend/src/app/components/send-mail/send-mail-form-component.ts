import { Component, OnInit, Inject } from '@angular/core';
import {
  AbstractControl,
  FormArray,
  FormBuilder,
  FormGroup,
  ValidationErrors,
  Validators,
} from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { forkJoin, of } from 'rxjs';
import { catchError, finalize, map } from 'rxjs/operators';
import { CommonService } from '@geonature_common/service/common.service';
import { ConfigService } from '@geonature/services/config.service';
import { TranslateService } from '@ngx-translate/core';
import { Observer } from '@geonature/syntheseModule/observer-sheet/observer';

interface SendResult {
  observer: Observer;
  ok: boolean;
}

function atLeastOneSelected(control: AbstractControl): ValidationErrors | null {
  const values = (control as FormArray).value as boolean[];
  return values.some((v) => v) ? null : { noObserver: true };
}

@Component({
  selector: 'pnx-send-mail-form',
  templateUrl: './send-mail-form.component.html',
})
export class SendMailFormComponent implements OnInit {
  selectedObs: any;
  selectedObsTaxonDetail: any;
  observers: Observer[] = [];

  public mailForm: FormGroup;
  public isLoading = false;

  constructor(
    private fb: FormBuilder,
    private http: HttpClient,
    private commonService: CommonService,
    public config: ConfigService,
    public dialogRef: MatDialogRef<SendMailFormComponent>,
    public translate: TranslateService,
    @Inject(MAT_DIALOG_DATA)
    public data: { selectedObs: any; selectedObsTaxonDetail: any; observers?: Observer[] }
  ) {
    this.selectedObs = data?.selectedObs;
    this.selectedObsTaxonDetail = data?.selectedObsTaxonDetail;

    this.observers = data?.observers || [];

    this.mailForm = this.fb.group({
      subject: ['', [Validators.required]],
      message: ['', [Validators.required, Validators.minLength(10)]],
      observers: this.fb.array(
        this.observers.map(() => this.fb.control(true)),
        atLeastOneSelected
      ),
    });
  }

  ngOnInit() {
    if (this.selectedObs) {
      this.mailForm.patchValue({
        subject: `Observation: ${this.selectedObsTaxonDetail.nom_valide}`,
        message: `${this.getObservationUrl()}`,
      });
    }
  }

  get observersArray(): FormArray {
    return this.mailForm.get('observers') as FormArray;
  }

  getSelectedObservers(): Observer[] {
    return this.observers.filter((_, i) => this.observersArray.at(i).value);
  }

  onSubmit() {
    if (this.mailForm.invalid) {
      return;
    }

    const selectedObservers = this.getSelectedObservers();
    const payload = {
      subject: this.mailForm.get('subject').value,
      message: this.mailForm.get('message').value,
    };

    this.isLoading = true;
    const requests = selectedObservers.map((observer) =>
      this.http.post(`api/gn_commons/send_mail/${observer.id_role}`, payload).pipe(
        map((): SendResult => ({ observer, ok: true })),
        catchError(() => {
          return of<SendResult>({ observer, ok: false });
        })
      )
    );

    forkJoin(requests)
      .pipe(finalize(() => (this.isLoading = false)))
      .subscribe((results) => {
        const failed = results.filter((r) => !r.ok);

        if (failed.length === 0) {
          this.commonService.translateToaster(
            'success',
            selectedObservers.length > 1
              ? 'Mail.Messages.MultipleEmailsSent'
              : 'Mail.Messages.EmailSent',
            { count: selectedObservers.length }
          );
          this.dialogRef.close(true);
          return;
        }

        const names = failed.map((r) => r.observer.nom_complet).join(', ');
        this.commonService.translateToaster('error', 'Mail.Messages.SendFailed', { names });
      });
  }

  private getObservationUrl(): string {
    if (this.selectedObs?.id_synthese) {
      return `${this.config.URL_APPLICATION}/#/synthese/occurrence/${this.selectedObs.id_synthese}`;
    }
    return '';
  }

  onCancel() {
    this.dialogRef.close(false);
  }
}
