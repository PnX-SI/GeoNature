import { ActivatedRoute } from '@angular/router';

export interface IBreadCrumb {
  label: string;
  iconClass?: string;
  title?: string;
  url: string;
}

export interface IBuildBreadCrumb {
  route: ActivatedRoute;
  url?: string;
  breadcrumbs?: Array<IBreadCrumb>;
}
