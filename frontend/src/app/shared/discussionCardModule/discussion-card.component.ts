import { Component, OnInit, Input, OnChanges } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { AuthService, User } from '@geonature/components/auth/auth.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { UntypedFormGroup, UntypedFormBuilder, Validators } from '@angular/forms';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { CommonService } from '@geonature_common/service/common.service';
import { isEmpty, uniqueId } from 'lodash';
import * as moment from 'moment';

@Component({
  selector: 'pnx-discussion-card',
  templateUrl: 'discussion-card.component.html',
  styleUrls: ['discussion-card.component.scss'],
})
export class DiscussionCardComponent implements OnInit, OnChanges {
  @Input() idSynthese: number;
  @Input() additionalData: any;
  @Input() validationColor: any;
  public commentForm: UntypedFormGroup;
  public open = false;
  public currentUser: User;
  public appConfig = AppConfig;
  public discussions: any;
  public allow = false;
  public sort = 'desc';
  constructor(
    private _authService: AuthService,
    private _formBuilder: UntypedFormBuilder,
    private _commonService: CommonService,
    private _syntheseDataService: SyntheseDataService
  ) {
    this.commentForm = this._formBuilder.group({
      content: ['', Validators.required],
      item: [this.idSynthese],
      type: ['discussion'],
      idReport: [],
      deleted: [false],
    });
  }

  ngOnInit() {
    this.open = false;
    // get current user required to save comment
    this.currentUser = this._authService.getCurrentUser();
    this.getDiscussions();
  }

  orderData(data) {
    const newarr = data.sort((a, b) => {
      const aDate = moment(a.creation_date ? a.creation_date : a.dateTime);
      const bDate = moment(b.creation_date ? b.creation_date : b.dateTime);
      return moment(aDate).diff(bDate);
    });
    if (this.sort === 'desc') {
      newarr.reverse();
    }
    return newarr;
  }

  ngOnChanges() {
    // reload list for next or previous item
    if (this.additionalData && this.additionalData.data) {
      this.additionalData = {
        ...this.additionalData,
        // insert spid to diff additionalData from reports data
        data: this.additionalData.data.map((d) => ({ ...d, spid: uniqueId() })),
      };
    }
    if (isEmpty(this.discussions)) {
      this.getDiscussions();
    }
  }

  isValid() {
    return (
      this.commentForm.valid &&
      this.commentForm.get('content').value.length <=
        this.appConfig?.SYNTHESE?.DISCUSSION_MAX_LENGTH
    );
  }

  /**
   * Send comment
   */
  handleSubmitComment() {
    // create new comment
    this.commentForm.get('item').setValue(this.idSynthese);
    this.commentForm.get('type').setValue('discussion');
    this._syntheseDataService.createReport(this.commentForm.value).subscribe((data) => {
      this._commonService.regularToaster('success', 'Commentaire sauvegardé !');
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
    let listEl = data.length ? data : [];
    if (!isEmpty(this.additionalData?.data) && this.additionalData.dateField) {
      listEl = this.orderData([...listEl, ...this.additionalData.data]);
    }
    this.discussions = listEl;
  }

  /**
   * get all discussion by module and type
   */
  getDiscussions() {
    const params = `idSynthese=${this.idSynthese}&type=discussion&sort=${this.sort}`;
    this._syntheseDataService.getReports(params).subscribe((response) => {
      this.setDiscussions(response);
    });
  }

  deleteComment(idReport) {
    this._syntheseDataService.deleteReport(idReport).subscribe(() => {
      this.getDiscussions();
    });
  }

  isDeleted(c) {
    return c?.deleted;
  }
}
