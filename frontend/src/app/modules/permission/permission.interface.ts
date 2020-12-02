import { TemplateRef } from '@angular/core';

export interface IPermissionRequestDatatableColumn {
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

export interface IPermissionRequest {
  token: string;
  userName: string;
  organismName: string;
  geographicFilters?: number[];
  geographicFiltersLabels?: string[];
  taxonomicFilters?: number[];
  taxonomicFiltersLabels?: string[];
  sensitiveAccess?: boolean;
  endAccessDate?: string;// TODO: use Date
  processedState?: string;
  processedDate?: string;// TODO: use DateTime
  processedBy?: IRolePermission;
  refusalReason?: string;
  additionalData?: IAdditionalData[];
  metaCreateDate?: string;
  metaUpdateDate?: string;
}

export interface IAdditionalData {
  key: string;
  label?: string;
  value: any;
}

export interface IPermissionRequestConstraint {
  sensitive: boolean;
  geographic: number[];
  taxonomic?: number[];
}

export interface IRolePermission {
  id: number;
  name: string;
  type: 'USER'|'GROUP';
  permissionsNbr?: number;
}
