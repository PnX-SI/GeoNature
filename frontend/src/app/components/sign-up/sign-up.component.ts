import { Component, OnInit } from '@angular/core';
import { FormGroup, FormBuilder, Validators, ValidatorFn, AbstractControl } from '@angular/forms';
import { Router } from '@angular/router';
import { Observable } from 'rxjs';
import { AppConfig } from '@geonature_config/app.config';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { AuthService } from '../auth/auth.service';

@Component({
  selector: 'pnx-signup',
  templateUrl: './sign-up.component.html',
  styleUrls: ['./sign-up.component.scss']
})
export class SignUpComponent implements OnInit {

	form: FormGroup;

  constructor(
  	private fb: FormBuilder,
    private _authService: AuthService
  ) {
    //if (AppConfig.CAS_PUBLIC.)

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
			password_confirmation: ['', Validators.required],
			remarques: ['', null],
			organisme: ['', null]
    });
  }

  save() {
  	
  }
}
