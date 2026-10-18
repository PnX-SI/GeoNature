import { toColDefs, toSorts } from './data-grid.utils';

describe('data grid utils', () => {
  const options = { externalSorting: false, sorts: [], autoHeight: false };

  describe('toColDefs', () => {
    it('maps the columns', () => {
      const [col] = toColDefs(
        [{ prop: 'name', name: 'Name', width: 120, sortable: true, pinned: 'left' }],
        options
      );
      expect(col).toMatchObject({
        colId: 'name',
        field: 'name',
        headerName: 'Name',
        width: 120,
        sortable: true,
        pinned: 'left',
      });
      expect(col.flex).toBeUndefined();
    });

    it('uses the prop as header and shares the width of columns without width', () => {
      const [col] = toColDefs([{ prop: 'name' }], options);
      expect(col.headerName).toBe('name');
      expect(col.flex).toBe(1);
      expect(col.sortable).toBe(false);
      expect(col.resizable).toBe(true);
    });

    it('sets the sort of the columns, by priority', () => {
      const cols = toColDefs([{ prop: 'a' }, { prop: 'b' }, { prop: 'c' }], {
        ...options,
        sorts: [
          { prop: 'b', dir: 'desc' },
          { prop: 'a', dir: 'asc' },
        ],
      });
      expect(cols.map((c) => c.sort)).toEqual(['asc', 'desc', null]);
      expect(cols[1].sortIndex).toBe(0);
      expect(cols[0].sortIndex).toBe(1);
    });

    it('does not reorder the rows with an external sort', () => {
      const [col] = toColDefs([{ prop: 'a' }], { ...options, externalSorting: true });
      expect(col.comparator(1, 2, null, null, false)).toBe(0);
      const [internal] = toColDefs([{ prop: 'a' }], options);
      expect(internal.comparator).toBeUndefined();
    });

    it('wraps the cells of rows of automatic height', () => {
      const [col] = toColDefs([{ prop: 'a' }], { ...options, autoHeight: true });
      expect(col.autoHeight).toBe(true);
      expect(col.wrapText).toBe(true);
    });

    it('formats the values with the row', () => {
      const [col] = toColDefs(
        [{ prop: 'a', valueFormatter: (v, row) => `${v}-${row.b}` }],
        options
      );
      expect((col.valueFormatter as any)({ value: 1, data: { b: 2 } })).toBe('1-2');
    });

    it('renders the cells with the template of the column', () => {
      const template: any = {};
      const [col] = toColDefs([{ prop: 'a', template }], options);
      expect(col.cellRenderer).toBeDefined();
      expect((col.cellRendererParams as any).template).toBe(template);
    });
  });

  describe('toSorts', () => {
    it('gives the sorted columns by priority', () => {
      expect(
        toSorts([
          { colId: 'a', sort: null },
          { colId: 'b', sort: 'desc', sortIndex: 1 },
          { colId: 'c', sort: 'asc', sortIndex: 0 },
        ])
      ).toEqual([
        { prop: 'c', dir: 'asc' },
        { prop: 'b', dir: 'desc' },
      ]);
    });

    it('is empty without sorted column', () => {
      expect(toSorts([{ colId: 'a' }])).toEqual([]);
    });
  });
});
