import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation, ViewChild } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { ContactFormService } from '../contact-form.service';

@Component({
  selector: 'pnx-occurrence',
  templateUrl: './occurrence.component.html',
  styleUrls: ['./occurrence.component.scss'],
  encapsulation: ViewEncapsulation.None
})
export class OccurrenceComponent implements OnInit {

  @Input() occurrenceForm: FormGroup;
  @ViewChild('taxon') taxon;
  constructor(public fs: ContactFormService) {
   }

  ngOnInit() {
    console.log('init occurrence');
    
    console.log(this.taxon);
    console.log(this.taxon.inputElementRef);
    console.log(document.getElementById('taxonInput'));
    //document.getElementById('taxonInput').focus();
    
    
    //this.taxon.inputElementRef.focus(); 
  }



}
