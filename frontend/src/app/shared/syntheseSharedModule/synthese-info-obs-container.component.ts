import { Component, OnDestroy } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { SyntheseInfoObsComponent } from './synthese-info-obs/synthese-info-obs.component';

@Component({
  selector: 'pnx-synthese-info-obs-modal-container',
  template: '',
})
export class SyntheseObsModalWrapperComponent implements OnDestroy {
  destroy = new Subject<any>();
  currentDialog = null;
  dialogResult: any;
  constructor(
    private modalService: NgbModal,
    private router: Router,
    route: ActivatedRoute
  ) {
    route.params.pipe(takeUntil(this.destroy)).subscribe((params) => {
      // When router navigates on this component is takes the params
      // and opens up the photo detail modal
      this.currentDialog = this.modalService.open(SyntheseInfoObsComponent, {
        size: 'lg',
        windowClass: 'large-modal',
      });
      this.currentDialog.componentInstance.idSynthese = params.id_synthese;
      this.currentDialog.componentInstance.selectedTab = params.tab;
      this.currentDialog.componentInstance.useFrom = route.snapshot.data['useFrom'] || 'synthese';
      this.currentDialog.componentInstance.header = true;

      // Go back to home page after the modal is closed
      this.dialogResult = this.currentDialog.result.then(
        (result) => {
          this.router.navigate(['/synthese'], { replaceUrl: true });
        },
        (reason) => {
          this.router.navigate(['/synthese'], { replaceUrl: true });
        }
      );
    });
  }
  ngOnDestroy(): void {
    this.destroy.next();
    this.currentDialog?.close(-1);
    this.dialogResult = null;
  }
}
