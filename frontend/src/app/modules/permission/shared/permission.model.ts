import { IPermissionFilter } from '../permission.interface';

export class Permission {
  name: string;
  code: string;
  module: string;
  end_date: string;// TODO: use Date
  filters: IPermissionFilter[];
}
