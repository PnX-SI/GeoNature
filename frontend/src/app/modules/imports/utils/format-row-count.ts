import { Import } from '../models/import.model';

export function formatRowCount(imprt: Import): string {
  return imprt && imprt.source_count
    ? `${imprt.statistics['nb_line_valid'] ?? 0} / ${imprt['source_count']}`
    : '';
}
