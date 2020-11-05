import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';

import { AppConfig } from '@geonature_config/app.config';
import { PermissionService } from '../permission.service';
import { IRole } from '../permission.interface'

@Component({
  selector: 'pnx-permission-detail',
  templateUrl: './permission-detail.component.html',
  styleUrls: ['./permission-detail.component.scss']
})
export class PermissionDetailComponent implements OnInit {

  idRole: number;
  role: IRole;

  constructor(
    public activatedRoute: ActivatedRoute,
    public permissionService: PermissionService,
  ) {}

  ngOnInit(): void {
    this.idRole = this.activatedRoute.snapshot.params["idRole"];
    this.permissionService.getRoleById(this.idRole).subscribe(data => {
      this.role = data;
    });
  }
}
