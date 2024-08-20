import { Component, Input, Output, EventEmitter } from '@angular/core';

@Component({
  selector: 'pnx-home-discussions-toggle',
  templateUrl: './home-discussions-toggle.component.html',
  styleUrls: ['./home-discussions-toggle.component.scss']
})
export class HomeDiscussionsToggleComponent {
  @Input() isChecked: boolean = false;
  @Output() toggle = new EventEmitter<boolean>();

  onToggle(event: any): void {
    this.toggle.emit(event.checked);
  }
}
