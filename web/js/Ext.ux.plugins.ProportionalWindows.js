Ext.namespace('Ext.ux.plugins');

Ext.ux.plugins.ProportionalWindows = function(config) {
    Ext.apply(this, config);
};

Ext.extend(Ext.ux.plugins.ProportionalWindows, Ext.util.Observable, {
    init:function(win) {
        Ext.apply(win, {
            onRender:win.onRender.createSequence(function(ct, position) {
                var ctr = this.container;
                var ctrW = ctr.getWidth();
                var ctrH = ctr.getHeight();
                
                if (this.aspect) {
                // maintain aspect ratio
                var ratio = this.height / this.width;
                    var newWidth = Math.round(ctrW * this.percentage);
                var newHeight = Math.round(newWidth * ratio);
                } else {
                    var newWidth = Math.round(ctrW * this.percentage);
                    var newHeight = Math.round(ctrH * this.percentage);
                }
                newWidth = (newWidth > this.width)?newWidth:this.width;
                newHeight = (newHeight > this.height)?newHeight:this.height;
                this.setSize(newWidth, newHeight);
            })// End onRender
            }
        );
    } // end of function init
}); // end of extend 