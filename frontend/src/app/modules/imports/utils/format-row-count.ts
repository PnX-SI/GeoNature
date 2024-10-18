import { Import } from '../models/import.model';

export function formatRowCount(imprt: Import): string {
  return imprt && imprt.source_count
    ? `${imprt.statistics['import_count'] ?? 0} / ${imprt.statistics['source_count']}`
    : '';
}
