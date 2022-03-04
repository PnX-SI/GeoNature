import { Component, OnInit, Input } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { AuthService, User } from '@geonature/components/auth/auth.service';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { GlobalSubService } from '@geonature/services/global-sub.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { CommonService } from '@geonature_common/service/common.service';
import { pickBy, isEqual, isEmpty } from 'lodash';

@Component({
  selector: 'pnx-discussion-card',
  templateUrl: 'discussion-card.component.html',
  styleUrls: ['discussion-card.component.scss']
})

export class DiscussionCardComponent implements OnInit {
  @Input() idSynthese: number;
  public commentForm: FormGroup;
  public open = false;
  public currentUser: User;
  public moduleId: number;
  public discussions: any;
  public allow = false;
  constructor(
    private _authService: AuthService,
    private _formBuilder: FormBuilder,
    private globalSubService: GlobalSubService,
    private _commonService: CommonService,
    private _syntheseDataService: SyntheseDataService
  ) {
    this.commentForm = this._formBuilder
    .group({
      user: [],
      content: ['', Validators.required],
      module: [],
      item: [],
      role: []
    });
  }

  ngOnInit() {
    this.open = false;
    this.currentUser = this._authService.getCurrentUser();
    this.globalSubService.currentModuleSub.subscribe(module => {
      if (module) {
        // send module id to table
        this.moduleId = module.id_module;
        this.getDiscussions();
      }
    });
  }

  handleSubmitComment() {
    const userInfos = pickBy(this?.currentUser, (value, key) => {
      return ['id_role', 'prenom_role', 'nom_role'].includes(key);
    });
    this.commentForm.get('user').setValue(userInfos);
    this.commentForm.get('role').setValue(this.currentUser.id_role);
    this.commentForm.get('content').setValue({ comment: this.commentForm.get('content').value });
    this.commentForm.get('item').setValue(this.idSynthese);
    this.commentForm.get('module').setValue(this.moduleId);
    // create new comment
    this._syntheseDataService.createDiscussions(this.commentForm.value).subscribe(data => {
      this._commonService.regularToaster(
        'success',
        'Commentaire sauvegardé !'
      );
      // close add comment panel and refresh list
      this.openCloseComment();
      this.getDiscussions();
    });
  }

  formatDate(d) {
    return new Date(d).toLocaleDateString();
  }

  openCloseComment() {
    this.open = !this.open;
    if (!this.open) {
      this.commentForm.reset();
    }
  }

  getDiscussions() {
    const params = `idSynthese=${this.idSynthese}&idModule=${this.moduleId}&type=1&sort=desc`;
    this._syntheseDataService.getReports(params).subscribe(data => {
      this.discussions = data;
    });
  }
}
