import { Router, ActivatedRoute } from '@angular/router';
import { Component, OnInit } from '@angular/core';
import { MatDialog, MatSlideToggleChange } from '@angular/material';

import { map, mergeMap } from 'rxjs/operators';
import { of, Subject, Subscription } from 'rxjs';
import { LangChangeEvent, TranslateService } from '@ngx-translate/core';

import { CommonService } from '@geonature_common/service/common.service';
import { IModule, IObject, IPermission, IRolePermission } from '../permission.interface'
import { DeletePermissionDialog } from './delete-permission-dialog/delete-permission-dialog.component';
import { PermissionService } from '../permission.service';
import { ToastrService } from 'ngx-toastr';
import { EditPermissionModal } from './edit-permission-modal/edit-permission-modal.component';
import { Permission } from '../shared/permission.model';
import { HttpParams } from '@angular/common/http';
import { NumberValueAccessor } from '@angular/forms/src/directives';

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
  objects: Record<string, IObject> = {};
  permissionsByCode: Record<string, Record<string, IPermission[]>> = {};
  permissionsNbrByCode: Record<string, {total: number, inherited: number, owned: number}> = {};
  showInheritance: boolean = true;
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
    this.loadPermissionsObjects();
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

  private loadPermissionsObjects() {
    this.permissionService.getObjects().subscribe(objects => {
      this.objects = {};
      objects.forEach((obj) => {
        this.objects[obj.code] = obj;
      });
      console.log("Objects:", this.objects)
    })
  }

  private loadRole() {
    this.loading = true;
    let params = new HttpParams().set('with-inheritance', (this.showInheritance ? '1' : '0'));
    console.log(`With inheritance: ${this.showInheritance.toString()}`, params)
    this.permissionService.getRoleById(this.idRole, params)
      .pipe(
        map( role => {
          this.role = role;

          // Extract modules codes and dispatch permissions by module code
          let modulesCodes = [];
          for (let prop in role.permissions) {
            let permissions = role.permissions[prop];
            permissions.forEach((item) => {
              if (! modulesCodes.includes(item.module)) {
                modulesCodes.push(item.module);
                this.permissionsByCode[item.module] = {};
                this.permissionsByCode[item.module][item.object] = [item];
                // Set numbers of permissions
                this.permissionsNbrByCode[item.module] = {
                  total: 1,
                  inherited: (item.isInherited ? 1 : 0),
                  owned: (item.isInherited ? 0 : 1),
                };
              } else {
                if (this.permissionsByCode[item.module][item.object]) {
                  this.permissionsByCode[item.module][item.object].push(item);
                } else {
                  this.permissionsByCode[item.module][item.object] = [item];
                }
                // Update numbers of permissions
                this.permissionsNbrByCode[item.module]['total']++;
                if (item.isInherited) {
                  this.permissionsNbrByCode[item.module]['inherited']++;
                } else {
                  this.permissionsNbrByCode[item.module]['owned']++;
                }
              }
            })
          }
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

  onShowInheritanceChange(ob: MatSlideToggleChange) {
    console.log(`Show inheritance checked change : ${ob.checked}`);
    if (ob.checked != this.showInheritance) {
      this.showInheritance = ob.checked
      this.loadRole();
    }
  }

  openEditModal(permission: IPermission = new Permission()): void {
    console.log("Open edit modal:", permission)
    console.log("this.role:", this.role);
    const dialogRef = this.dialog.open(EditPermissionModal, {
      data: {
        "role": this.role,
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
