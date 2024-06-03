import { Import } from '../models/import.model';

export function formatRowCount(imprt: Import): string {
  return imprt && imprt.source_count ? `${imprt.import_count ?? 0} / ${imprt.source_count}` : '';
}
