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

// PERMISSIONS REQUESTS
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
  type: string;
  key: string;
  value: any;
  label?: string;
  icon?: string;
  iconSet?: string;
}

// PERMISSIONS ROLE
export interface IRolePermission {
  id: number;
  userName: string;
  organismName?: string;
  type: 'USER' | 'GROUP';
  permissionsNbr?: number;
  permissions?: Record<string, IPermission[]>;// Not use in list to decrease bandwidth consumption.
}

export interface IPermission {
  name: string;
  code: string;
  module: string;
  end_date: string;// TODO: use Date
  //filters: Record<string, IPermissionFilter[]>;
  filters: IPermissionFilter[];
}

export interface IPermissionFilter {
  type: string;
  value: any;
  label?: string | string[];
}

// MODULES
export interface IModule {
  id: number;
  code: string;
  label: string;
  picto?: string;
  desc?: string;
  group?: string;
  path?: string;
  externalUrl?: string;
  target?: string;
  comment?: string;
  activatedFrontend: boolean;
  activatedBackend: boolean;
  docUrl?: URL;
  order?: number;
}
