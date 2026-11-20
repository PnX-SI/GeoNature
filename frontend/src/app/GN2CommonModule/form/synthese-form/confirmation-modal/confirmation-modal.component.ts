import { Component, Inject } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';

export interface SearchFilter {
  field: string;
  message: string;
  confirmOnAbsence: boolean | null;
  values: Array<unknown> | null;
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
    this.dialogRef.close({ canceled: true });
  }

  onConfirmClick(): void {
    this.dialogRef.close({ confirmed: true });
  }
}
