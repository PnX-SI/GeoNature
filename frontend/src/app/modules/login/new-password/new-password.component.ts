import { Component, OnInit } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { UntypedFormGroup, UntypedFormBuilder, Validators } from '@angular/forms';
import { MAT_FORM_FIELD_DEFAULT_OPTIONS } from '@angular/material/form-field';

import { similarValidator } from '@geonature/services/validators';

import { AuthService } from '../../../components/auth/auth.service';
import { PasswordService } from '../../../userModule/services/password.service';
import { ConfigService } from '@geonature/services/config.service';
import { CommonService } from '@geonature_common/service/common.service';

@Component({
  selector: 'pnx-new-password',
  templateUrl: 'new-password.component.html',
  styleUrls: ['./new-password.component.scss'],
  providers: [
    // Avoid the fixed-height blank space mat-form-field reserves below each field
    // for hints/errors when there is none to show on this page.
    { provide: MAT_FORM_FIELD_DEFAULT_OPTIONS, useValue: { subscriptSizing: 'dynamic' } },
  ],
})
export class NewPasswordComponent implements OnInit {
  token: string;
  form: UntypedFormGroup;
  password_recovery: boolean = false;
  login_recovery: boolean = false;

  constructor(
    private _authService: AuthService,
    private fb: UntypedFormBuilder,
    private router: Router,
    private activatedRoute: ActivatedRoute,
    public config: ConfigService,
    private _commonService: CommonService,
    private passwordService: PasswordService
  ) {
    this.activatedRoute.queryParams.subscribe((params) => {
      let token = params['token'];
      if (!RegExp('^[0-9]+$').test(token)) {
        this.router.navigate(['/login']);
      }
      this.token = token;
    });
  }

  ngOnInit() {
    this.setForm();
  }

  setForm() {
    this.form = this.fb.group({
      password: ['', [this.passwordService.passwordValidator()]],
      password_confirmation: ['', [Validators.required]],
    });
    this.form.setValidators([similarValidator('password', 'password_confirmation')]);
  }

  submit() {
    if (this.form.valid) {
      let data = this.form.value;
      data['token'] = this.token;
      this._authService.passwordChange(data).subscribe(
        (res) => {
          this._commonService.translateToaster(
            'success',
            'Authentication.Messages.PasswordChanged'
          );
          this.router.navigate(['/login']);
        },
        // error callback
        (error) => {
          this._commonService.regularToaster('error', error.error.msg);
        }
      );
    }
  }
}
