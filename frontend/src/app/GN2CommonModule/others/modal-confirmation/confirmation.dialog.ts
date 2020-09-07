import { Component, Inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material';

@Component({
  selector: 'gn-confirmation-dialog',
  templateUrl: './confirmation.dialog.html',
  styleUrls: ['./confirmation.dialog.scss']
})
export class ConfirmationDialog {

  data: any;
  _yesColor: string = 'warn';
  _noColor: string = 'basic';
  _message: string = null;

  get yesColor() { return this.data.yesColor ? this.data.yesColor : this._yesColor; }
  get noColor() { return this.data.noColor ? this.data.noColor : this._noColor; }
  get message() { return this.data.message ? this.data.message : this._message; }
  
  constructor(
    public dialogRef: MatDialogRef<ConfirmationDialog>,
    @Inject(MAT_DIALOG_DATA) public options: any
  ) { 
    this.data = options;
  }

  onNoClick(): void {
    this.dialogRef.close();
  }
}
