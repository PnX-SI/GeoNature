import { Component, ElementRef, EventEmitter, Input, Output, ViewChild } from '@angular/core';

type ResizeTarget = 'filter' | 'map';

/**
 * Page layout shared by the modules showing search results on a map and in a list.
 * From left to right: filter (collapsible), map, list. The three columns are resizable.
 *
 * Usage:
 *   <gn-map-list-layout [(filterCollapsed)]="collapsed">
 *     <ng-container filter>...</ng-container>
 *     <ng-container map>...</ng-container>
 *     <ng-container list>...</ng-container>
 *   </gn-map-list-layout>
 */
@Component({
  selector: 'gn-map-list-layout',
  templateUrl: 'map-list-layout.component.html',
  styleUrls: ['map-list-layout.component.scss'],
})
export class MapListLayoutComponent {
  /** Whether the filter column is collapsed */
  @Input() filterCollapsed = false;
  @Output() filterCollapsedChange = new EventEmitter<boolean>();
  /** `side`: filter column on the left; `top`: filter panel above the map and the list (wide forms) */
  @Input() filterPosition: 'side' | 'top' = 'side';
  /** Display the default toggle tab on the edge of the filter column */
  @Input() showToggle = true;
  /** Initial share of the width given to the map and to the list (CSS flex-grow ratio) */
  @Input() mapRatio = 1;
  @Input() listRatio = 1;
  /** Minimal width (px) of each column while resizing */
  @Input() minWidth = 200;

  @ViewChild('container', { static: true }) container: ElementRef<HTMLElement>;
  @ViewChild('filterEl', { static: true }) filterEl: ElementRef<HTMLElement>;
  @ViewChild('mapEl', { static: true }) mapEl: ElementRef<HTMLElement>;
  @ViewChild('listEl', { static: true }) listEl: ElementRef<HTMLElement>;

  /** Widths (px) set by the user, `null` until a handle is dragged */
  filterWidth: number | null = null;
  mapWidth: number | null = null;

  private resizing: {
    target: ResizeTarget;
    startX: number;
    startFilter: number;
    startMap: number;
    startList: number;
  } | null = null;

  toggleFilter() {
    this.filterCollapsed = !this.filterCollapsed;
    this.filterCollapsedChange.emit(this.filterCollapsed);
  }

  startResize(event: PointerEvent, target: ResizeTarget) {
    if (event.button !== 0) return;
    (event.target as HTMLElement).setPointerCapture(event.pointerId);
    this.resizing = {
      target,
      startX: event.clientX,
      startFilter: this.filterEl.nativeElement.offsetWidth,
      startMap: this.mapEl.nativeElement.offsetWidth,
      startList: this.listEl.nativeElement.offsetWidth,
    };
    event.preventDefault();
  }

  onResize(event: PointerEvent) {
    const r = this.resizing;
    if (!r) return;
    const dx = event.clientX - r.startX;
    if (r.target === 'filter') {
      // the filter takes from / gives to the map, the list keeps its width
      const total = r.startFilter + r.startMap;
      this.filterWidth = this.clamp(r.startFilter + dx, total);
      this.mapWidth = total - this.filterWidth;
    } else {
      // the map takes from / gives to the list, the filter keeps its width
      const total = r.startMap + r.startList;
      this.mapWidth = this.clamp(r.startMap + dx, total);
    }
    this.notifyResize();
  }

  endResize(event: PointerEvent) {
    if (!this.resizing) return;
    (event.target as HTMLElement).releasePointerCapture?.(event.pointerId);
    this.resizing = null;
    this.notifyResize();
  }

  /** Keep both neighbours above the minimal width */
  private clamp(value: number, total: number): number {
    return Math.min(Math.max(value, this.minWidth), total - this.minWidth);
  }

  /** Let the maps (Leaflet) and the grids recompute their size */
  private notifyResize() {
    window.dispatchEvent(new Event('resize'));
  }
}
