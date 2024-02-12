import { Component, OnInit } from '@angular/core';
import { UntypedFormGroup } from '@angular/forms';
import { AuthService } from '@geonature/components/auth/auth.service';
import { RoleFormService } from './services/form.service';
import { UserDataService } from './services/user-data.service';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-user',
  templateUrl: './user.component.html',
  styleUrls: ['./user.component.scss'],
})
export class UserComponent implements OnInit {
  form: UntypedFormGroup;
  additionalFieldsForm: Array<any>;

  constructor(
    private authService: AuthService,
    private roleFormService: RoleFormService,
    private userService: UserDataService,
    private config: ConfigService
  ) {}

  ngOnInit() {
    this.additionalFieldsForm = [...this.config.ACCOUNT_MANAGEMENT.ACCOUNT_FORM].map(
      (form_element) => {
        //on desactive les elements customs
        form_element['disable'] = true;
        return form_element;
      }
    );
    this.initForm();
  }

  initForm() {
    this.form = this.getForm(this.authService.getCurrentUser().id_role);
  }

  getForm(role: number): UntypedFormGroup {
    return this.roleFormService.getForm(role);
  }

  save() {
    if (this.form.valid) {
      this.userService.putRole(this.form.value).subscribe((res) => this.form.disable());
    }
  }

  cancel() {
    this.initForm();
    this.form.disable();
  }
}
