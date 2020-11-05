import { Component, OnInit } from '@angular/core';

import { AppConfig } from '@geonature_config/app.config';
import { PermissionService } from '../permission.service';

@Component({
  selector: 'pnx-permission-request-list',
  templateUrl: './request-list.component.html',
  styleUrls: ['./request-list.component.scss'],
})
export class RequestListComponent implements OnInit {

  constructor(
    public permissionService: PermissionService,
  ) {}

  ngOnInit(): void {
    //throw new Error('Method not implemented.');
  }
}
