import { Component, Input, Output, EventEmitter } from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';

@Component({
  standalone: true,
  selector: 'pnx-home-discussions-toggle',
  templateUrl: './home-discussions-toggle.component.html',
  styleUrls: ['./home-discussions-toggle.component.scss'],
  imports: [GN2CommonModule],
})
export class HomeDiscussionsToggleComponent {
  @Input() isChecked: boolean = false;
  @Output() toggle = new EventEmitter<boolean>();

  onToggle(event: any): void {
    this.toggle.emit(event.checked);
  }
}
