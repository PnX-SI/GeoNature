import { Component, OnInit } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { UntypedFormGroup, UntypedFormBuilder, Validators } from '@angular/forms';

import { ToastrService } from 'ngx-toastr';
import { similarValidator } from '@geonature/services/validators';

import { AuthService } from '../../../components/auth/auth.service';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-new-password',
  templateUrl: 'new-password.component.html',
  styleUrls: ['./new-password.component.scss'],
})
export class NewPasswordComponent implements OnInit {
  token: string;
  form: UntypedFormGroup;
  public casLogin;

  constructor(
    private _authService: AuthService,
    private fb: UntypedFormBuilder,
    private router: Router,
    private activatedRoute: ActivatedRoute,
    private _toasterService: ToastrService,
    public config: ConfigService
  ) {
    this.activatedRoute.queryParams.subscribe((params) => {
      let token = params['token'];
      if (!RegExp('^[0-9]+$').test(token)) {
        this.router.navigate(['/login']);
      }
      this.token = token;
    });
    this.casLogin = this.config.CAS_PUBLIC.CAS_AUTHENTIFICATION;
  }

  ngOnInit() {
    this.setForm();
  }

  setForm() {
    this.form = this.fb.group({
      password: ['', [Validators.required]],
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
          this._toasterService.info(res.msg, '', {
            positionClass: 'toast-top-center',
            tapToDismiss: true,
            timeOut: 10000,
          });
          this.router.navigate(['/login']);
        },
        // error callback
        (error) => {
          this._toasterService.error(error.error.msg, '');
        }
      );
    }
  }
}
