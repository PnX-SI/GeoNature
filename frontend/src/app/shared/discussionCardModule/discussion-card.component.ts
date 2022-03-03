import { Component, OnInit, OnChanges, Input } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { AuthService, User } from '@geonature/components/auth/auth.service';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { GlobalSubService } from "@geonature/services/global-sub.service";
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { CommonService } from "@geonature_common/service/common.service";
import { pickBy, isEqual, isEmpty } from "lodash";

@Component({
  selector: 'pnx-discussion-card',
  templateUrl: 'discussion-card.component.html',
  styleUrls: ['discussion-card.component.scss']
})
  
  
export class DiscussionCardComponent implements OnInit, OnChanges {
  @Input() idSynthese: number;
  public commentForm: FormGroup;
  public open = false;
  public currentUser: User;
  public moduleId: number;
  public discussions: any;
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
      item: []
    });
  }

  handleSubmitComment() {
    const userInfos = pickBy(this?.currentUser, function(value, key) {
      return ['id_role', 'prenom_role', 'nom_role'].includes(key);
    })
    this.commentForm.get('user').setValue(userInfos);
    this.commentForm.get('content').setValue({ comment: this.commentForm.get('content').value });
    this.commentForm.get('item').setValue(this.idSynthese);
    this._syntheseDataService.createDiscussions(this.commentForm.value).subscribe(data => {
      this._commonService.regularToaster(
        "success",
        "Commentaire sauvegardé !"
      );
      this.openCloseComment();
      this.getAllDiscussions();
      
    });
  }

  openCloseComment() {
    this.open = !this.open;
    if (!this.open) this.commentForm.reset();
  }

  ngOnInit() {
    this.open = false;
    this.currentUser = this._authService.getCurrentUser();
    this.getAllDiscussions();
  }

  getAllDiscussions() {
    this._syntheseDataService.getDiscussions(this.idSynthese).subscribe(data => {
      this.discussions = data;
    });
  }

  ngOnChanges() {
    this.globalSubService.currentModuleSub.subscribe(module => {
      if (module) {
        this.commentForm.get('module').setValue(module.id_module);
      }
    });
  }
}
