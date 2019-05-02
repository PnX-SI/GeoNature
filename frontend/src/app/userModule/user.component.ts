import { Component, OnInit } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { Observable } from 'rxjs';
import { AppConfig } from '@geonature_config/app.config';
import { AuthService, User } from '@geonature/components/auth/auth.service';
import { Role, RoleFormService} from './services/form.service';

@Component({
  selector: 'pnx-user',
  templateUrl: './user.component.html',
  /*styleUrls: ['./user.component.scss'],*/
  providers: []
})
export class UserComponent implements OnInit {

	role: Role = null;
	form: FormGroup;

  constructor(
  	private authService: AuthService,
  	private roleFormService: RoleFormService
  ) {}

  ngOnInit() {
  	this.form = this.getForm(this.authService.getCurrentUser().id_role);
  	console.log(this.form);
  }

  getForm(role: number): FormGroup {
	  return this.roleFormService.getForm(role);
	}

	save() {
		if (this.form.valid) {
			console.log(this.form.value);
		}
	}

}
