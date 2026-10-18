import { ComponentFixture, TestBed } from '@angular/core/testing';
import { UntypedFormControl } from '@angular/forms';
import { of } from 'rxjs';
import { DestinationsComponent } from './destinations.component';
import { ImportDataService } from '../../services/data.service';

describe('DestinationsComponent', () => {
  let component: DestinationsComponent;
  let fixture: ComponentFixture<DestinationsComponent>;
  let service: { getDestinations: jest.Mock };

  beforeEach(() => {
    service = { getDestinations: jest.fn().mockReturnValue(of([{ code: 'synthese' }])) };
    TestBed.configureTestingModule({
      declarations: [DestinationsComponent],
      providers: [{ provide: ImportDataService, useValue: service }],
    });
    // the template needs ng-select and translate, only the logic is tested here
    TestBed.overrideComponent(DestinationsComponent, { set: { template: '' } });
    fixture = TestBed.createComponent(DestinationsComponent);
    component = fixture.componentInstance;
    component.parentFormControl = new UntypedFormControl(null);
  });

  it('loads all the destinations by default', () => {
    fixture.detectChanges();
    expect(service.getDestinations).toHaveBeenCalledWith();
    expect(component.destinations).toEqual([{ code: 'synthese' }]);
  });

  it('loads the destinations allowed for an action when displayAllowed', () => {
    component.displayAllowed = true;
    component.actionCode = 'U';
    fixture.detectChanges();
    expect(service.getDestinations).toHaveBeenCalledWith('U');
  });
});
