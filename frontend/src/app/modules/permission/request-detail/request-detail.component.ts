import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';

import { AppConfig } from '@geonature_config/app.config';
import { PermissionService } from '../permission.service';

@Component({
  selector: 'pnx-permission-request-detail',
  templateUrl: './request-detail.component.html',
  styleUrls: ['./request-detail.component.scss']
})
export class RequestDetailComponent implements OnInit {

  requestToken: string;

  constructor(
    public activatedRoute: ActivatedRoute,
    public permissionService: PermissionService,
  ) {}

  ngOnInit(): void {
    this.requestToken = this.activatedRoute.snapshot.params["requestToken"];
  }
}
