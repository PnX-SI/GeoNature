/**
 * Taken from examples
 * Modified to fire the actionEvent event
 *      and to support singleSelect
 * Possible enhancements : display radio buttons when in singleSelect mode
 */
Ext.grid.CheckColumn = function(config){
    Ext.apply(this, config);
    if(!this.id){
        this.id = Ext.id();
    }
    this.renderer = this.renderer.createDelegate(this);
};

Ext.grid.CheckColumn.prototype ={

    singleSelect: false,

    init : function(grid){
        this.grid = grid;
        this.grid.on('render', function(){
            var view = this.grid.getView();
            view.mainBody.on('mousedown', this.onMouseDown, this);
        }, this);
    },

    onMouseDown : function(e, t){
        if(t.className && t.className.indexOf('x-grid3-cc-'+this.id) != -1){
            e.stopEvent();
            var index = this.grid.getView().findRowIndex(t);
            var record = this.grid.store.getAt(index);

            // don't uncheck if singleSelect
            // consider it as a radio button
            if (this.singleSelect && record.data[this.dataIndex]) {
                return;
            }

            if (this.singleSelect) {
                this.grid.store.each(function(r) {
                    if (r != record) {
                        r.set('selected', false);
                    }
                });
            }

            record.set(this.dataIndex, !record.data[this.dataIndex]);
             //commit changes (removes the red
             // triangle which indicates a 'dirty' field)
            record.store.commitChanges();
            this.grid.fireEvent(this.actionEvent, this.grid,
                record, record.data[this.dataIndex]);
        }
    },

    renderer : function(v, p, record){
        p.css += ' x-grid3-check-col-td';
        return '<div class="x-grid3-check-col'+(v?'-on':'')+' x-grid3-cc-'+this.id+'">&#160;</div>';
    }
};
