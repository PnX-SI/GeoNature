import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation, ViewChild } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { ContactFormService } from '../contact-form.service';
import { AuthService } from '../../../../../core/components/auth/auth.service';

@Component({
  selector: 'pnx-occurrence',
  templateUrl: './occurrence.component.html',
  styleUrls: ['./occurrence.component.scss'],
  encapsulation: ViewEncapsulation.None
})
export class OccurrenceComponent implements OnInit {

  @Input() occurrenceForm: FormGroup;
  @ViewChild('taxon') taxon;
  constructor(public fs: ContactFormService, private _auth: AuthService) {
   }

  ngOnInit() {
    document.getElementById('taxonInput').focus();
  }



}
