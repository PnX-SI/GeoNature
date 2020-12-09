import { Component, Inject } from '@angular/core';

import { MAT_DIALOG_DATA } from '@angular/material';

import { IPermission } from '../../permission.interface';

@Component({
  selector: 'gn-permission-delete-dialog',
  templateUrl: 'delete-permission-dialog.component.html',
})
export class DeletePermissionDialog {

  constructor(
    @Inject(MAT_DIALOG_DATA) public permission: IPermission,
  ) { }
}
