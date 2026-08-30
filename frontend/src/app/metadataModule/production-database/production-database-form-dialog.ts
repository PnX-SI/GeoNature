import { Component, OnInit, OnDestroy, Inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  UntypedFormGroup,
  UntypedFormBuilder,
  Validators,
  ReactiveFormsModule,
  ValidationErrors,
  AbstractControl,
} from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogRef, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatIconModule } from '@angular/material/icon';
import { TranslateModule } from '@ngx-translate/core';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { MetadataDataService } from '../services/metadata-data.service';
import { ActorFormService } from '../services/actor-form.service';
import { CommonService } from '@geonature_common/service/common.service';
import { FormService } from '@geonature_common/form/form.service';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { ErrorStateMatcher, ShowOnDirtyErrorStateMatcher } from '@angular/material/core';

@Component({
  selector: 'pnx-production-database-form-dialog',
  templateUrl: './production-database-form-dialog.component.html',
  styleUrls: ['./production-database-form-dialog.component.scss'],
  providers: [{ provide: ErrorStateMatcher, useClass: ShowOnDirtyErrorStateMatcher }],
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
    GN2CommonModule,
  ],
})
export class ProductionDatabaseFormDialogComponent implements OnInit, OnDestroy {
  form: UntypedFormGroup;
  roles: any[] = [];
  isSubmitting: boolean = false;
  private destroy$ = new Subject<void>();
  private existingDatabases: any[] = [];

  constructor(
    private _fb: UntypedFormBuilder,
    public dialogRef: MatDialogRef<ProductionDatabaseFormDialogComponent>,
    private metadataDataS: MetadataDataService,
    private actorFormS: ActorFormService,
    private _commonService: CommonService,
    private formService: FormService,
    @Inject(MAT_DIALOG_DATA) public data: any
  ) {
    this.initForm();
    if (data?.productionDatabases) {
      data.productionDatabases.pipe(takeUntil(this.destroy$)).subscribe((databases) => {
        this.existingDatabases = databases;
        this.form.get('name').updateValueAndValidity();
      });
    }
  }

  private initForm(): void {
    this.form = this._fb.group({
      name: ['', [Validators.required, this.nameExistsValidator.bind(this)]],
      id_contact: [null],
      uuid_production_database: ['', [this.formService.uuidValidator()]],
    });
  }

  ngOnInit(): void {
    this.roles = this.actorFormS.roles;
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  nameExistsValidator(control: AbstractControl): ValidationErrors | null {
    if (!control.value || control.value.trim() === '') {
      return null;
    }

    const nameExists = this.existingDatabases.some(
      (db) => db.name.toLowerCase().trim() === control.value.toLowerCase().trim()
    );

    return nameExists ? { nameExists: true } : null;
  }

  onCancel(): void {
    this.dialogRef.close();
  }

  onSubmit(): void {
    if (this.form.invalid || this.isSubmitting) {
      return;
    }
    this.isSubmitting = true;
    const formData = this.form.value;

    // delete uuid_production_database if empty
    if (!formData.uuid_production_database || formData.uuid_production_database.trim() === '') {
      delete formData.uuid_production_database;
    }
    this.isSubmitting = true;
    this.metadataDataS
      .createProductionDatabase(this.form.value)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (result) => {
          this._commonService.translateToaster(
            'success',
            'MetaData.ProductionDatabase.CreatedSuccess'
          );
          this.dialogRef.close(result);
        },
        error: (error) => {
          this._commonService.translateToaster('error', 'MetaData.ProductionDatabase.CreatedError');
          this.isSubmitting = false;
        },
      });
  }
}
