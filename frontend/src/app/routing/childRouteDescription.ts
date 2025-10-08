import { ActivatedRouteSnapshot, Router, RouterStateSnapshot } from "@angular/router";

export function navigateToFirstAvailableChild(
  route: ActivatedRouteSnapshot,
  state: RouterStateSnapshot,
  router: Router,
  children: Array<ChildRouteDescription>
): boolean {
  if (children.length) {
    const redirectionTab = children[0];
    console.log(state.url + '/' + redirectionTab.path);
    router.navigate([state.url + '/' + redirectionTab.path]);
    return true;
  }
  return false;
}

export interface ChildRouteDescription {
  label: string;
  path: string;
  configEnabledField?: string;
  component: any;
}
