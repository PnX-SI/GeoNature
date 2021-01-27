import { filter, distinctUntilChanged } from 'rxjs/operators';

import { Component, Input, OnInit, } from "@angular/core";
import { ActivatedRoute, Router, NavigationEnd, Event } from "@angular/router";

import { IBreadCrumb, IBuildBreadCrumb } from './breadcrumb.interface';

/**
 * Classe construisant un fil d'Ariane à l'aide de la configuration des routes
 * d'un module.
 *
 * Pour l'usage voir le module "permission" et les ressources ci-dessous.
 * Source : https://medium.com/@bo.vandersteene/angular-5-breadcrumb-c225fd9df5cf
 * Voir aussi : https://vsavkin.tumblr.com/post/146722301646/angular-router-empty-paths-componentless-routes
 *
 * @example
 * <gn-breadcrumbs
 *   [previousRoutes]="monService.getBreadcrumbsRoot()"
 * >
 * </gn-breadcrumbs>
 */
@Component({
  selector: "gn-breadcrumbs",
  templateUrl: "./breadcrumbs.component.html",
})
export class BreadcrumbsComponent implements OnInit {

  /**
   * Permet de fournir un tableau d'objets contenant la configuration
   * de routes. Ces routes seront affichées au début du fil d'Ariane.
   * Cela permet de compléter les routes pour un module imbriqué dans un
   * autre.
   * Le format de l'objet correspond à l'interface IBreadCrumb :
   * - label: intitulé affiché dans le fil d'Ariane.
   * - iconClass [optionnel]: class CSS d'icône (Fontawesome, Material).
   *   Ex. : 'fa fa-shield' ou 'check_circle'
   * - title [optionnel]: texte qui apparaitra dans un tooltip.
   * - url: portion d'URL situé après le # permettant d'accéder au module.
   *   Ex. : '/admin'
   */
  @Input() previousRoutes: Array<IBreadCrumb> = []; // Areas id_type
  public breadcrumbs: IBreadCrumb[];

  constructor(
    private router: Router,
    private activatedRoute: ActivatedRoute
  ) {
    this.breadcrumbs = this.buildBreadCrumb({route: this.activatedRoute.root});
  }

  ngOnInit() {
    this.breadcrumbs = this.buildBreadCrumb({
      route: this.activatedRoute.root,
      breadcrumbs: this.previousRoutes,
    });
    this.router.events.pipe(
      filter((event: Event) => event instanceof NavigationEnd),
      distinctUntilChanged(),
    ).subscribe(() => {
      this.breadcrumbs = this.buildBreadCrumb({
        route: this.activatedRoute.root,
        breadcrumbs: this.previousRoutes,
      });
    });
  }

  /**
   * Construit récursivement le fil d'Ariane vis à vis de la route active
   * courante.
   * Si "previousRoute" existe, insére les routes en question au début du
   * fil d'Ariane.
   *
   * @param route
   * @param url
   * @param breadcrumbs
   */
  private buildBreadCrumb({route, url = '', breadcrumbs = []}: IBuildBreadCrumb): IBreadCrumb[] {
    // If no routeConfig is avalailable we are on the root path
    let data = route.routeConfig && route.routeConfig.data && route.routeConfig.data.breadcrumb
        ? route.routeConfig.data.breadcrumb
        : {label: '', iconClass: '', title: ''};
    let label = data.label;
    let iconClass = data.iconClass || '';
    let title = data.title || '';
    let path = route.routeConfig && route.routeConfig.path
        ? route.routeConfig.path
        : '';

    // If the route is dynamic route such as ':id', remove it
    const lastRoutePart = path.split('/').pop();
    const isDynamicRoute = lastRoutePart.startsWith(':');
    if (isDynamicRoute) {
      const paramName = lastRoutePart.split(':')[1];
      const paramValue = route.snapshot.params[paramName];
      path = path.replace(lastRoutePart, paramValue);
      label = label.replace(`:${paramName}`, paramValue);
    }

    // In the routeConfig the complete path is not available,
    // so we rebuild it each time
    const nextUrl = path ? `${url}/${path}` : url;

    const breadcrumb: IBreadCrumb = {
        label: label,
        iconClass: iconClass,
        title: title,
        url: nextUrl,
    };

    // Only adding route with non-empty label
    const newBreadcrumbs = breadcrumb.label ? [ ...breadcrumbs, breadcrumb ] : [ ...breadcrumbs];
    if (route.firstChild) {
        // If we are not on our current path yet,
        // there will be more children to look after, to build our breadcumb
        return this.buildBreadCrumb({route: route.firstChild, url: nextUrl, breadcrumbs: newBreadcrumbs});
    }
    return newBreadcrumbs;
  }
}
