import { Component, OnInit, OnDestroy, Inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  UntypedFormGroup,
  UntypedFormBuilder,
  Validators,
  ReactiveFormsModule,
} from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogRef, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatIconModule } from '@angular/material/icon';
import { TranslateModule } from '@ngx-translate/core';
import { Subject } from 'rxjs';
import { takeUntil, debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { MetadataDataService } from '../services/metadata-data.service';
import { ActorFormService } from '../services/actor-form.service';
import { CommonService } from '@geonature_common/service/common.service';

@Component({
  selector: 'pnx-remote-database-form-dialog',
  templateUrl: './remote-database-form-dialog.component.html',
  styleUrls: ['./remote-database-form-dialog.component.scss'],
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatDialogModule,
    MatButtonModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatIconModule,
    TranslateModule,
  ],
})
export class RemoteDatabaseFormDialogComponent implements OnInit, OnDestroy {
  form: UntypedFormGroup;
  roles: any[] = [];
  isSubmitting: boolean = false;
  private destroy$ = new Subject<void>();

  constructor(
    private _fb: UntypedFormBuilder,
    public dialogRef: MatDialogRef<RemoteDatabaseFormDialogComponent>,
    private metadataDataS: MetadataDataService,
    private actorFormS: ActorFormService,
    private _commonService: CommonService,
    @Inject(MAT_DIALOG_DATA) public data: any
  ) {
    this.initForm();
  }

  private initForm(): void {
    this.form = this._fb.group({
      name: ['', [Validators.required]],
      id_contact: [null],
    });
  }

  ngOnInit(): void {
    this.roles = this.actorFormS.roles;
    this.form
      .get('name')
      .valueChanges.pipe(takeUntil(this.destroy$), debounceTime(300), distinctUntilChanged())
      .subscribe((name) => {
        // todo add check on doublon
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  onCancel(): void {
    this.dialogRef.close();
  }

  onSubmit(): void {
    if (this.form.invalid || this.isSubmitting) {
      return;
    }

    this.isSubmitting = true;
    this.metadataDataS
      .createRemoteDatabase(this.form.value)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (result) => {
          this._commonService.translateToaster('success', 'MetaData.RemoteDatabase.CreatedSuccess');
          this.dialogRef.close(result);
        },
        error: (error) => {
          this._commonService.translateToaster('error', 'MetaData.RemoteDatabase.CreatedError');
          this.isSubmitting = false;
        },
      });
  }
}
