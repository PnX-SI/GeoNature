import { Component, Inject, Output, EventEmitter } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { HttpClient } from '@angular/common/http';
import { AuthService } from '@geonature/components/auth/auth.service';
import { ConfigService } from '@geonature/services/config.service';
import { CommonService } from '@geonature_common/service/common.service';

export interface DialogData {
  provider: any;
}

@Component({
  selector: 'login-dialog',
  templateUrl: 'external-login-dialog.html',
  styleUrls: ['./login.component.scss'],
})
export class LoginDialog {
  @Output() userLogged = new EventEmitter<any>();
  constructor(
    public dialogRef: MatDialogRef<LoginDialog>,
    private _http: HttpClient,
    private _authService: AuthService,
    @Inject(MAT_DIALOG_DATA) public data: DialogData,
    public config: ConfigService,
    private _commonService: CommonService
  ) {}

  async externalLogin(form) {
    this._http
      .post(this.config.API_ENDPOINT + '/auth/login/' + this.data.provider.id_provider, form)
      .subscribe(
        (data) => {
          this.userLogged.emit(data);
        },
        (error) => {
          console.log(error);
          this._commonService.regularToaster('error', error.error.description);
        }
      );
  }
}
