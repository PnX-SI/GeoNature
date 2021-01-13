import { Router, ActivatedRoute } from '@angular/router';
import { Component, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material';

import { map, mergeMap } from 'rxjs/operators';
import { of, Subject, Subscription } from 'rxjs';
import { LangChangeEvent, TranslateService } from '@ngx-translate/core';

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

  loading: boolean = false;
  locale: string;
  destroy$: Subject<boolean> = new Subject<boolean>();
  idRole: number;
  role: IRolePermission;
  modules: IModule[];
  subscription: Subscription;

  constructor(
    public activatedRoute: ActivatedRoute,
    private commonService: CommonService,
    public dialog: MatDialog,
    public permissionService: PermissionService,
    private router: Router,
    private translateService: TranslateService,
    private toasterService: ToastrService,
  ) {
    this.router.routeReuseStrategy.shouldReuseRoute = () => false;
  }

  ngOnInit(): void {
    this.extractRouteParams();
    this.loadRole();
    this.getI18nLocale();
  }

  ngOnDestroy(): void {
    this.destroy$.next(true);
    this.destroy$.unsubscribe();
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
    this.loading = true;
    this.permissionService.getRoleById(this.idRole)
      .pipe(
        map( role => {
          let modulesCodes = Object.keys(role.permissions);
          this.role = role;
          return modulesCodes;
        }),
        mergeMap( modulesCodes => {
          if (modulesCodes.length > 0) {
            return this.permissionService.getModules(modulesCodes)
          } else {
            return of([]);
          }
        })
      )
      .subscribe(modules => {
        this.modules = modules;
        this.loading = false;
      });
  }

  private getI18nLocale() {
    this.locale = this.translateService.currentLang;
    this.translateService.onLangChange
      .takeUntil(this.destroy$)
      .subscribe((langChangeEvent: LangChangeEvent) => {
        this.locale = langChangeEvent.lang;
      });
  }

  trackByModuleCode(index: number, module: any): string {
    return module.code;
  }

  openEditModal(permission: IPermission = new Permission()): void {
    console.log("Open edit modal:", permission)
    const dialogRef = this.dialog.open(EditPermissionModal, {
      data: {
        "idRole": this.idRole,
        "permission": permission,
      },
      disableClose: true,
      panelClass: 'edit-permission-modal',
    });

    dialogRef.afterClosed().subscribe(msg => {
      if (msg == 'OK') {
        console.log("In after add permission modal closed:", msg)
        this.loadRole();
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
