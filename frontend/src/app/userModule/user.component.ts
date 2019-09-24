import { Component, OnInit } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { Observable } from 'rxjs';
import { AppConfig } from '@geonature_config/app.config';
import { AuthService, User } from '@geonature/components/auth/auth.service';
import { Role, RoleFormService} from './services/form.service';
import { UserDataService} from './services/user-data.service';

@Component({
  selector: 'pnx-user',
  templateUrl: './user.component.html',
  styleUrls: ['./user.component.scss']
})
export class UserComponent implements OnInit {

	form: FormGroup;

  constructor(
  	private authService: AuthService,
  	private roleFormService: RoleFormService,
  	private userService: UserDataService
  ) {}

  ngOnInit() {
    this.initForm();
  }

  initForm() {
    this.form = this.getForm(this.authService.getCurrentUser().id_role);
  }

  getForm(role: number): FormGroup {
	  return this.roleFormService.getForm(role);
	}

	save() {
		if (this.form.valid) {
			this.userService.putRole(this.form.value)
            .subscribe(res => this.form.disable());
		}
	}

  cancel() {
    this.initForm();
    this.form.disable();
  }

}
