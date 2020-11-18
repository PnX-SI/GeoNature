import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';

import { AppConfig } from '@geonature_config/app.config';
import { PermissionService } from '../permission.service';
import { GnRolePermission } from '../permission.interface'

@Component({
  selector: 'gn-permission-detail',
  templateUrl: './permission-detail.component.html',
  styleUrls: ['./permission-detail.component.scss']
})
export class PermissionDetailComponent implements OnInit {

  idRole: number;
  role: GnRolePermission;

  constructor(
    public activatedRoute: ActivatedRoute,
    public permissionService: PermissionService,
  ) {}

  ngOnInit(): void {
    this.extractRouteParams();
    this.permissionService.getRoleById(this.idRole).subscribe(data => {
      this.role = data;
    });
  }

  private extractRouteParams() {
    const urlParams = this.activatedRoute.snapshot.paramMap;
    console.log('Params:', urlParams)
    this.idRole = urlParams.get('idRole') as unknown as number;
    if (urlParams.has('name') && urlParams.has('type')) {
      console.log('IN')
      this.role = {
        'id': this.idRole,
        'name': urlParams.get('name'),
        'type': urlParams.get('type') as 'USER' | 'GROUP',
      };
    }
  }
}
