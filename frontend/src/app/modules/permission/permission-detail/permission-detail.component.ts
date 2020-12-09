import { ActivatedRoute } from '@angular/router';
import { Component, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material';

import { map, mergeMap } from 'rxjs/operators';
import { Subscription } from 'rxjs';
import { TranslateService } from '@ngx-translate/core';

import { CommonService } from '@geonature_common/service/common.service';
import { IModule, IPermission, IRolePermission } from '../permission.interface'
import { DeletePermissionDialog } from './delete-permission-dialog/delete-permission-dialog.component';
import { PermissionService } from '../permission.service';
import { ToastrService } from 'ngx-toastr';
import { EditPermissionModal } from './edit-permission-modal/edit-permission-modal.component';
import { Permission } from '../shared/permission.model';

@Component({
  selector: 'gn-permission-detail',
  templateUrl: './permission-detail.component.html',
  styleUrls: ['./permission-detail.component.scss']
})
export class PermissionDetailComponent implements OnInit {

  idRole: number;
  role: IRolePermission;
  modules: IModule[];
  subscription: Subscription;

  constructor(
    public activatedRoute: ActivatedRoute,
    public dialog: MatDialog,
    public permissionService: PermissionService,
    private commonService: CommonService,
    private translateService: TranslateService,
    private toasterService: ToastrService,
  ) {}

  ngOnInit(): void {
    this.extractRouteParams();
    this.loadRole();
  }

  private extractRouteParams() {
    const urlParams = this.activatedRoute.snapshot.paramMap;
    this.idRole = urlParams.get('idRole') as unknown as number;
    if (urlParams.has('name') && urlParams.has('type')) {
      this.role = {
        'id': this.idRole,
        'userName': urlParams.get('name'),
        'type': urlParams.get('type') as 'USER' | 'GROUP',
      };
    }
  }

  private loadRole() {
    this.permissionService.getRoleById(this.idRole)
      .pipe(
        map( role => {
          let modulesCodes = Object.keys(role.permissions);
          this.role = role;
          console.log('Role:', this.role)
          return modulesCodes;
        }),
        mergeMap( modulesCodes => {
          if (modulesCodes.length > 0) {
            return this.permissionService.getModules(modulesCodes)
          } else {
            return [];
          }
        })
      )
      .subscribe(modules => {
        this.modules = modules;
        console.log('Modules:', this.modules)
      });
      console.log(`In loadRole end: role ${this.role}`)
  }

  openAddModal(permission: IPermission = new Permission()): void {
    const dialogRef = this.dialog.open(EditPermissionModal, {
      data: permission,
      disableClose: true,
      panelClass: 'edit-permission-modal',
    });

    dialogRef.afterClosed().subscribe(permission => {
      if (permission) {
        console.log("In after add permission modal closed:", permission)
      }
    });
  }

  openDeleteDialog(permission: IPermission): void {
    const dialogRef = this.dialog.open(DeletePermissionDialog, {
      maxWidth: 800,
      data: permission
    });

    dialogRef.afterClosed().subscribe(permission => {
      if (permission) {
        console.log(permission);
        this.permissionService.deletePermission(permission.gathering).subscribe(
          () => {
            this.commonService.translateToaster('info', 'Permissions.deleteOk');
            this.loadRole();
          },
          error => {
            const msg = (error.error && error.error.msg) ? error.error.msg : error.message;
            console.log(msg);
            this.translateService
              .get('Permissions.deleteKo', {errorMsg: msg})
              .subscribe((translatedTxt: string) => {
                this.toasterService.error(translatedTxt);
              });
            this.loadRole();
          }
        );
      }
    });
  }
}
