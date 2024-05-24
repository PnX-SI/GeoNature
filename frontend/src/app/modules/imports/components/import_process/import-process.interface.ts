import { Step } from '../../models/enums.model';
import { Observable } from 'rxjs';

export interface ImportStepInterface {
  onSaveData(): void | Observable<void>;
}
