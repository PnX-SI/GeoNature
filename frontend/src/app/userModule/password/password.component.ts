import { Component, OnInit } from '@angular/core';
import { FormGroup, FormBuilder, Validators, ValidatorFn, AbstractControl } from '@angular/forms';
import { Router } from '@angular/router';
import { UserDataService } from '../services/user-data.service';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { similarValidator } from '@geonature/services/validators';

@Component({
  selector: 'pnx-user-password',
  templateUrl: './password.component.html',
  styleUrls: ['./password.component.scss']
})
export class PasswordComponent implements OnInit {
  form: FormGroup;

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private userService: UserDataService,
    private _toasterService: ToastrService
  ) {}

  ngOnInit() {
    this.initForm();
  }

  initForm() {
    this.form = this.fb.group({
      init_password: ['', Validators.required],
      password: ['', Validators.required],
      password_confirmation: ['', Validators.required]
    });
    this.form.setValidators([similarValidator('password', 'password_confirmation')]);
  }

  save() {
    if (this.form.valid) {
      this.userService.putPassword(this.form.value).subscribe(
        res => {
          this._toasterService.info(res.msg, '', {
            positionClass: 'toast-top-center',
            tapToDismiss: true,
            timeOut: 5000
          });
          this.router.navigate(['/user']);
        },
        error => {
          this._toasterService.error(error.error.msg, '', {
            positionClass: 'toast-top-center',
            tapToDismiss: true,
            timeOut: 5000
          });
        }
      );
    }
  }
}
