import { Component, Inject } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';

import { SearchFilter } from './confirmation-modal-utils';

@Component({
  selector: 'pnx-confirmation-modal',
  templateUrl: './confirmation-modal.component.html',
  styleUrls: ['./confirmation-modal.component.scss'],
})
export class ConfirmationModalComponent {
  constructor(
    public dialogRef: MatDialogRef<ConfirmationModalComponent>,
    @Inject(MAT_DIALOG_DATA) public searchFilters: SearchFilter[]
  ) {
    searchFilters = searchFilters.map((filter) => {
      if (typeof filter.message !== 'string' || filter.message.length === 0) {
        filter.message = 'Filters.ConfirmSearch.DefaultMessage';
      }
      return filter;
    });
  }

  onCancelClick(): void {
    this.dialogRef.close({ confirmed: false });
  }

  onConfirmClick(): void {
    this.dialogRef.close({ confirmed: true });
  }
}
