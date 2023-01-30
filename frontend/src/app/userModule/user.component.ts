import { Component, OnInit } from '@angular/core';
import { UntypedFormGroup } from '@angular/forms';
import { AuthService } from '@geonature/components/auth/auth.service';
import { RoleFormService } from './services/form.service';
import { UserDataService } from './services/user-data.service';

@Component({
  selector: 'pnx-user',
  templateUrl: './user.component.html',
  styleUrls: ['./user.component.scss'],
})
export class UserComponent implements OnInit {
  form: UntypedFormGroup;

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
