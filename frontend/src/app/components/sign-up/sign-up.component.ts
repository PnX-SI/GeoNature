import { Component, OnInit } from '@angular/core';
import { FormGroup, FormBuilder, Validators, ValidatorFn, AbstractControl } from '@angular/forms';
import { Router } from '@angular/router';
import { Observable } from 'rxjs';
import { AppConfig } from '@geonature_config/app.config';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { AuthService } from '../auth/auth.service';
import { similarValidator } from '@geonature/services/validators';

@Component({
  selector: 'pnx-signup',
  templateUrl: './sign-up.component.html',
  styleUrls: ['./sign-up.component.scss']
})
export class SignUpComponent implements OnInit {

	form: FormGroup;

  constructor(
  	private fb: FormBuilder,
    private _authService: AuthService,
    private _router: Router,
    private _toasterService: ToastrService
  ) {
    if (!(AppConfig['ENABLE_SIGN_UP'] || false)) {
      this._router.navigate(['/login']);
    }
  }

  ngOnInit() {
  	this.createForm();
  }

  createForm() {
  	this.form = this.fb.group({
			nom_role: ['', Validators.required],
			prenom_role: ['', Validators.required],
			identifiant: ['', Validators.required],
			email: ['', [Validators.pattern('^[a-z0-9._-]+@[a-z0-9._-]{2,}\.[a-z]{2,4}$'), Validators.required]],
  		password: ['', Validators.required],
			password_confirmation: ['', [Validators.required, similarValidator('password')]],
			remarques: ['', null],
      organisme: ['', null]
    });
  }

  save() {
  	if (this.form.valid) {
      this._authService.signupUser(this.form.value)
            .subscribe(
              res => {
                this._toasterService.info(
                  res.msg,
                  '',
                  {
                    positionClass: 'toast-top-center',
                    tapToDismiss: true,
                    timeOut: 5000
                  }
                );
                this._router.navigate(['/login']);
              },
              // error callback
              error => { 
                this._toasterService.error(
                  error.error.msg,
                  '',
                  {
                    positionClass: 'toast-top-center',
                    tapToDismiss: true,
                    timeOut: 5000
                  }
                );
              }
            );
    }
  }
}
