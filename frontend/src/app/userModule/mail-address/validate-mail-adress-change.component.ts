import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { UserDataService } from '../services/user-data.service';
import { CommonService } from '@geonature_common/service/common.service';
import { ToastrService } from 'ngx-toastr';

@Component({
  selector: 'pnx-validate-mail',
  templateUrl: './validate-mail-adress-change.component.html',
  styleUrls: ['./validate-mail-adress-change.component.scss'],
})
export class ValidateMailAddressChangeComponent implements OnInit {
  public loading = false;
  public hasError = false;
  public validated = false;
  public newMail: string;
  private userId: string;

  constructor(
    private _route: ActivatedRoute,
    private _router: Router,
    private _userDataService: UserDataService,
    private _commonService: CommonService,
    private _toastr: ToastrService
  ) {}

  ngOnInit(): void {
    this.newMail = this._route.snapshot.queryParamMap.get('new_mail');
    this.userId = this._route.snapshot.queryParamMap.get('user');
  }

  onConfirmValidate(): void {
    this.validateMail(this.newMail, this.userId);
  }

  validateMail(newMail: string, userId: string): void {
    this.loading = true;
    this._userDataService.validateEmailChange(newMail, userId).subscribe({
      next: () => {
        this.validated = true;
        this.loading = false;
        this._toastr.success('Email validé avec succès');
        setTimeout(() => {
          this._router.navigate(['/user']);
        }, 3000);
      },
      error: (err) => {
        this.loading = false;
        this.hasError = true;
        this._commonService.regularToaster('error', err);
        setTimeout(() => {
          this._router.navigate(['/user']);
        }, 3000);
      },
    });
  }
}
