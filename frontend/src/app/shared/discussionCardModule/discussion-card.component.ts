import { Component, OnInit, Input, OnChanges } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { AuthService, User } from '@geonature/components/auth/auth.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { GlobalSubService } from '@geonature/services/global-sub.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { CommonService } from '@geonature_common/service/common.service';
import { pickBy, isEmpty, uniqueId } from 'lodash';
import * as moment from 'moment';

@Component({
  selector: 'pnx-discussion-card',
  templateUrl: 'discussion-card.component.html',
  styleUrls: ['discussion-card.component.scss']
})

export class DiscussionCardComponent implements OnInit, OnChanges {
  @Input() idSynthese: number;
  @Input() additionalData: any;
  @Input() validationColor: any;
  @Input() codeModule: string;
  public commentForm: FormGroup;
  public open = false;
  public currentUser: User;
  public moduleId: number;
  public appConfig = AppConfig;
  public discussions: any;
  public allow = false;
  public sort = 'desc';
  constructor(
    private _authService: AuthService,
    private _formBuilder: FormBuilder,
    private globalSubService: GlobalSubService,
    private _commonService: CommonService,
    private _syntheseDataService: SyntheseDataService,
    private dataService: DataFormService
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
    // get current user required to save comment
    this.currentUser = this._authService.getCurrentUser();
    // init infos about current module required to save comment
    this.globalSubService.currentModuleSub.subscribe(module => {
      if (module) {
        // send module id to table
        this.moduleId = module.id_module;
        this.getDiscussions();
      }
    });
  }

  orderData(data) {
    const newarr = data.sort((a, b) => {
      const aDate = moment(a.content_date ? a.content_date : a.dateTime)
      const bDate = moment(b.content_date ? b.content_date : b.dateTime)
      return moment(aDate).diff(bDate);
    });
    if (this.sort === 'desc') {
      newarr.reverse();
    };
    return newarr;
  }

  ngOnChanges() {
    // reload list for next or previous item
    if (this.additionalData && this.additionalData.data) {
      this.additionalData = {
        ...this.additionalData,
        data: this.additionalData.data.map(d => ({ ...d, spid: uniqueId() }))
      }; 
    }
    if (this.moduleId) {
      this.getDiscussions();
    }
  }

  isValid() {
    return this.commentForm.valid &&
      this.commentForm.get('content').value.length <= this.appConfig?.SYNTHESE?.DISCUSSION_LENGTH;
  }

  /**
   * Send comment
   */
  handleSubmitComment() {
    const userInfos = pickBy(this?.currentUser, (value, key) => {
      return ['id_role', 'prenom_role', 'nom_role'].includes(key);
    });
    // set required form fields
    this.commentForm.get('user').setValue(userInfos);
    this.commentForm.get('content').setValue({ comment: this.commentForm.get('content').value });
    this.commentForm.get('item').setValue(this.idSynthese);
    this.commentForm.get('module').setValue(this.moduleId);
    // create new comment
    this._syntheseDataService.createReport(this.commentForm.value).subscribe(data => {
      this._commonService.regularToaster(
        'success',
        'Commentaire sauvegardé !'
      );
      // close add comment panel and refresh list
      this.openCloseComment();
      this.getDiscussions();
    });
  }

  /**
   * From timestamp to readable value
   */
  formatDate(d) {
    return new Date(d).toLocaleString();
  }

  /**
   * Manage comment form visibility
   */
  openCloseComment() {
    this.open = !this.open;
    if (!this.open) {
      this.commentForm.reset();
    }
  }

  setDiscussions(data) {
    let listEl = data?.results || [];
    if (!isEmpty(this.additionalData?.data) && this.additionalData.dateField) {
      listEl = this.orderData([...listEl, ...this.additionalData.data]);
    }
    this.discussions = listEl;
  }

  /**
   * get all discussion by module and type
   */
  getDiscussions() {
    const params = `idSynthese=${this.idSynthese}&idModule=${this.moduleId}&type=1&sort=${this.sort}`;
    this._syntheseDataService.getReports(params).subscribe(response => {
      this.setDiscussions(response);
    });
  }

  deleteComment(id) {
    this._syntheseDataService.deleteReport(id).subscribe(response => {
      this.getDiscussions();
    });
  }
}
