import { Component, OnInit } from '@angular/core';
import { FormGroup, FormBuilder, Validators, ValidatorFn, AbstractControl } from '@angular/forms';
import { Router } from '@angular/router';
import { Observable } from 'rxjs';
import { AppConfig } from '@geonature_config/app.config';
import { UserDataService} from '../services/user-data.service';
import { ToastrService, ToastrConfig } from 'ngx-toastr';

@Component({
  selector: 'pnx-user',
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
      password_confirmation: ['', [Validators.required, similarValidator('password')]]
    });
  }

	save() {
    console.log("save");
		if (this.form.valid) {
			this.userService
            .putPassword(this.form.value)
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
                this.router.navigate(['/user']);
              },
              error => {
                console.log(error);
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

  console() {
    console.log(this.form)
  }

}


export function similarValidator(compared: string): ValidatorFn {
  return (control: AbstractControl): { [key: string]: any } => {
    const valeur = control.value
    const group = control.parent;
    let valid = false;
    if (group) {
      const comparedValue = group.controls[compared].value;
      valid = comparedValue == valeur ? true : false;
    }

    return valid ? null : { 'similarError': { valeur } };
  };
}