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
  ) {
    /* TODO
    if (!AppConfig.ENABLE_SIGN_UP) {
      this._router.navigate(['/login']);
    }
    */
  }

  ngOnInit() {
  	this.createForm();
  }

  createForm() {
  	this.form = this.fb.group({
			nom_role: ['bob', Validators.required],
			prenom_role: ['dylan', Validators.required],
			identifiant: ['bob.dylan', Validators.required],
			email: ['jbrieuclp@gmail.com', [Validators.pattern('^[a-z0-9._-]+@[a-z0-9._-]{2,}\.[a-z]{2,4}$'), Validators.required]],
  		password: ['test', Validators.required],
			password_confirmation: ['test', [Validators.required, similarValidator('password')]],
			remarques: ['remaques', null],
			organisme: ['organisme', null]
    });
  }

  save() {
    console.log("submit");
    console.log(this.form.value);
  	if (this.form.valid) {
      this._authService.signupUser(this.form.value)
            .subscribe(
              data => {
                console.log(data);
              },
              // error callback
              error => { console.log(error); }
            );
    }
  }
}
