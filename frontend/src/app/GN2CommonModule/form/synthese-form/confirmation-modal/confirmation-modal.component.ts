import { Component, Inject } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';

export interface ConfiguredSearchFilter {
  field: string;
  values: Array<any> | null;
  message: string | null;
  confirmOnAbsence: boolean | null;
}

export interface SearchFilter {
  field: string;
  value: any;
  messages: string[];
}

@Component({
  selector: 'pnx-confirmation-modal',
  templateUrl: './confirmation-modal.component.html',
  styleUrls: ['./confirmation-modal.component.scss'],
})
export class ConfirmationModalComponent {
  constructor(
    public dialogRef: MatDialogRef<ConfirmationModalComponent>,
    @Inject(MAT_DIALOG_DATA) public searchFilter: SearchFilter[]
  ) {}

  onCancelClick(): void {
    this.dialogRef.close(false);
  }

  onConfirmClick(): void {
    this.dialogRef.close(true);
  }
}
