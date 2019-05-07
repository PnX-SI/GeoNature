import { Component, OnInit } from '@angular/core';
import { FormGroup, FormBuilder, Validators, ValidatorFn, AbstractControl } from '@angular/forms';
import { Router } from '@angular/router';
import { Observable } from 'rxjs';
import { AppConfig } from '@geonature_config/app.config';
import { ToastrService, ToastrConfig } from 'ngx-toastr';

@Component({
  selector: 'pnx-signin',
  templateUrl: './sign-in.component.html',
  styleUrls: ['./sign-in.component.scss']
})
export class SignInComponent implements OnInit {


  constructor(
  ) {}

  ngOnInit() {
  }
}
