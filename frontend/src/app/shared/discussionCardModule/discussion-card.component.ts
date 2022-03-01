import { Component, OnInit, OnChanges, Input } from '@angular/core';
import { Observable } from 'rxjs';
import { AppConfig } from '@geonature_config/app.config';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { AuthService, User } from '@geonature/components/auth/auth.service';
import { ModuleService } from '@geonature/services/module.service';

@Component({
  selector: 'pnx-discussion-card',
  templateUrl: 'discussion-card.component.html',
  styleUrls: ['discussion-card.component.scss']
})

export class DiscussionCardComponent implements OnInit, OnChanges {
  @Input() idSynthese: number;
  public comment: any;
  public currentUser: User;
  public cruved: any;
  constructor(
    private _authService: AuthService,
    private _gnDataService: DataFormService,
    private _moduleService: ModuleService
  ) { }

  addComment() {
    this.comment = {
      date: new Date().toISOString(),
      user: 'Jean'
    }
  }
  ngOnInit() {
    console.log("INIT");
    this.currentUser = this._authService.getCurrentUser();
    this.cruved = this._gnDataService.getCruved(['6']);
    console.log(this.currentUser);
    console.log(this.cruved);
    let synthese_module = this._moduleService.getModule('VALIDATION');
    console.log(synthese_module);
  }

  ngOnChanges() {
    console.log("CHANGES");
  }
}
