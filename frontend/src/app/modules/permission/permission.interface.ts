import { TemplateRef } from '@angular/core';

export interface GnRolePermission {
  id: number;
  name: string;
  type: 'USER'|'GROUP';
  permissionsNbr?: number;
}

export interface PermissionRequestDatatableColumn {
  prop: string;
  name: string;
  flexGrow: number;
  sortable?: boolean;
  resizeable?: boolean;
  tooltip?: string;
  searchable?: boolean;
  headerClass?: string;
  cellTemplate?: TemplateRef<any>;
  headerTemplate?: TemplateRef<any>;
}

export interface GnPermissionRequest {
  token: string;
  userName: string;
  organismName: string;
  endAccessDate?: string;// TODO: use DateTime
  permissions?: GnPermissionRequestConstraint;
  state?: string;
}

export interface GnPermissionRequestConstraint {
  sensitive: boolean;
  geographic: number[];
  taxonomic?: number[];
}
