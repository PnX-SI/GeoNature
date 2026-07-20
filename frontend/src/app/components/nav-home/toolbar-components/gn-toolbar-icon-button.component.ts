import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatMenu, MatMenuModule } from '@angular/material/menu';

/**
 * Shared presentational toolbar icon-button.
 * Renders the common `mx-2 mat-elevation-z1` + `mat-icon-button` + tooltip
 * shell, in one of three modes depending on the inputs provided:
 * - `href` set        → rendered as an `<a>` link
 * - `menuTrigger` set  → rendered as a `<button>` opening the given `mat-menu`
 * - otherwise          → rendered as a plain `<button>` emitting `btnClick`
 */
@Component({
  selector: 'gn-toolbar-icon-button',
  standalone: true,
  imports: [CommonModule, MatButtonModule, MatIconModule, MatTooltipModule, MatMenuModule],
  templateUrl: './gn-toolbar-icon-button.component.html',
  styleUrls: ['./gn-toolbar-icon-button.component.scss'],
})
export class GnToolbarIconButtonComponent {
  @Input() icon = '';
  @Input() iconId?: string;
  @Input() tooltip = '';
  @Input() href?: string;
  @Input() target?: string;
  @Input() dataQa?: string;
  @Input() menuTrigger: MatMenu | null = null;

  @Output() btnClick = new EventEmitter<void>();

  onClick(): void {
    if (!this.menuTrigger) {
      this.btnClick.emit();
    }
  }
}
