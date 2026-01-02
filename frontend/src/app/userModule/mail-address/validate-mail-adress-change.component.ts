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
  public loading = true;
  public hasError = false;

  constructor(
    private _route: ActivatedRoute,
    private _router: Router,
    private _userDataService: UserDataService,
    private _commonService: CommonService,
    private _toastr: ToastrService
  ) {}

  ngOnInit(): void {
    const newMail = this._route.snapshot.queryParamMap.get('new_mail');
    const userId = this._route.snapshot.queryParamMap.get('user');
    this.validateMail(newMail, userId);
  }

  validateMail(newMail: string, userId: string): void {
    this.loading = true;
    this._userDataService.validateEmailChange(newMail, userId).subscribe({
      next: () => {
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
