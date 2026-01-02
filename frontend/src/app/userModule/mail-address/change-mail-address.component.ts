import { Component, OnInit } from '@angular/core';
import { UntypedFormGroup, UntypedFormBuilder, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { UserDataService } from '../services/user-data.service';
import { CommonService } from '@geonature_common/service/common.service';
import { AuthService } from '@geonature/components/auth/auth.service';

@Component({
  selector: 'pnx-change-mail',
  templateUrl: './change-mail-address.component.html',
  styleUrls: ['./change-mail-address.component.scss'],
})
export class ChangeMailAddressComponent implements OnInit {
  form: UntypedFormGroup;
  currentEmail: string = '';

  constructor(
    private fb: UntypedFormBuilder,
    private router: Router,
    private userService: UserDataService,
    private authService: AuthService,
    private commonService: CommonService
  ) {}

  ngOnInit() {
    this.initForm();
    this.loadUserEmail();
  }

  initForm() {
    this.form = this.fb.group({
      new_mail: ['', [Validators.required, Validators.email]],
    });
  }

  loadUserEmail() {
    this.userService.getCurrentUserRole().subscribe({
      next: (user) => {
        this.currentEmail = user.email;
      },
      error: () => {
        this.commonService.regularToaster('error', "Erreur lors de la récupération de l'email");
      },
    });
  }

  save() {
    if (this.form.valid) {
      this.userService.requestEmailChange(this.form.value).subscribe({
        next: () => {
          this.commonService.translateToaster(
            'success',
            'MyAccount.Messages.ChangeMailConfirmation'
          );
          this.router.navigate(['/user']);
        },
        error: (error) => {
          this.commonService.regularToaster('error', error.error.msg);
        },
      });
    }
  }
}
