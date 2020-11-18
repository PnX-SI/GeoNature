import { Component, Input, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';

import { AppConfig } from '@geonature_config/app.config';
import { GnPermissionRequest } from '../permission.interface';
import { PermissionService } from '../permission.service';

@Component({
  selector: 'gn-permission-request-detail',
  templateUrl: './request-detail.component.html',
  styleUrls: ['./request-detail.component.scss']
})
export class RequestDetailComponent implements OnInit {

  token: string;
  request: GnPermissionRequest;

  constructor(
    public activatedRoute: ActivatedRoute,
    public permissionService: PermissionService,
  ) {}

  ngOnInit(): void {
    this.extractRouteParams();
    this.permissionService.getRequestByToken(this.token).subscribe(data => {
      this.request = data;
    });
  }

  private extractRouteParams() {
    const urlParams = this.activatedRoute.snapshot.paramMap;
    console.log('Params:', urlParams)
    this.token = urlParams.get('requestToken');
    if (urlParams.has('user') && urlParams.has('organism')) {
      console.log('IN')
      this.request = {
        'token': this.token,
        'userName': urlParams.get('user'),
        'organismName': urlParams.get('organism'),
      };
    }
  }
}
