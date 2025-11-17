import { Component, OnInit } from '@angular/core';
import {
  UntypedFormGroup,
  UntypedFormBuilder,
  Validators,
  ValidatorFn,
  AbstractControl,
} from '@angular/forms';
import { Router } from '@angular/router';
import { UserDataService } from '../services/user-data.service';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { similarValidator } from '@geonature/services/validators';
import { CommonService } from '@geonature_common/service/common.service';

@Component({
  selector: 'pnx-user-password',
  templateUrl: './password.component.html',
  styleUrls: ['./password.component.scss'],
})
export class PasswordComponent implements OnInit {
  form: UntypedFormGroup;

  constructor(
    private fb: UntypedFormBuilder,
    private router: Router,
    private userService: UserDataService,
    private _commonService: CommonService
  ) {}

  ngOnInit() {
    this.initForm();
  }

  initForm() {
    this.form = this.fb.group({
      init_password: ['', Validators.required],
      password: ['', Validators.required],
      password_confirmation: ['', Validators.required],
    });
    this.form.setValidators([similarValidator('password', 'password_confirmation')]);
  }

  save() {
    if (this.form.valid) {
      this.userService.putPassword(this.form.value).subscribe(
        (res) => {
          this._commonService.translateToaster(
            'success',
            'Authentication.Messages.PasswordChanged'
          );
          this.router.navigate(['/user']);
        },
        (error) => {
          this._commonService.regularToaster('error', error.error.msg);
        }
      );
    }
  }
}
