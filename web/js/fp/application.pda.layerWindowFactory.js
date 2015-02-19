
Ext.namespace("application");

/**
 * function createLayerWindow
 * Factory to create the layer tree window
 *
 * Parameters:
 * {OpenLayers.Map}
 *
 * Returns:
 * {Ext.Window}
 */

application.createLayerWindow = function(map) {
    var overlayLayerUrl = map.getLayersByName('overlay')[0].url;
    var model = [
        {
            text: "Cartes d'État-Major (1/40 000)"
            ,id:'layer_etatmajor'
            ,leaf: true
            ,checked: false
            ,layerName: "Cartes État-Major (1/40 000)"
        }
        ,{
            text: "Photographies aériennes"
            ,id:'layer_ortho'
            ,leaf: true
            ,checked: false
            ,layerName: "Ortho-imagerie"
        }
        ,{
            text: "Parcelles cadastrales"
            ,id:'layer_cadastre'
            ,leaf: true
            ,checked: false
            ,layerName: "Parcelles cadastrales"
        },
        {
            text: "Communes"
            ,leaf: true
            ,checked: false
            ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'communescbna'})
            ,layerName: "overlay:communescbna"
        },
        {
            text: "Secteurs"
            ,leaf: true
            ,checked: false
            ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'secteurs'})
            ,layerName: "overlay:secteurs"
        },
        {
            text: "Zones de prospection relues"
            ,leaf: true
            ,checked: true
            //,cls: 'x-hide-checkbox' // this hides the checkbox
            ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'zp_relue'})
            ,layerName: "overlay:zp_relue"
        },
        {
            text: "Zones de prospection non relues"
            ,leaf: true
            ,checked: true
            //,cls: 'x-hide-checkbox' // this hides the checkbox
            ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'zp_pasrelue'})
            ,layerName: "overlay:zp_pasrelue"
        },
        {
            text: "Zones à statut"
            ,leaf: false
            ,expanded: false
            ,checked: true
            ,children: [{
                text: 'Znieff2'
                ,leaf: true
                ,checked: false
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'zones2'})
                ,layerName: "overlay:zones2"
            },{
                text: 'Znieff1'
                ,leaf: true
                ,checked: false
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'zones3'})
                ,layerName: "overlay:zones3"
            },{
                text: 'Coeur du Parc'
                ,leaf: true
                ,checked: false
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'zones4'})
                ,layerName: "overlay:zones4"
            },{
                text: 'Natura 2000'
                ,leaf: true
                ,checked: false
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'zones5'})
                ,layerName: "overlay:zones5"
            },{
                text: 'Réserves de chasse'
                ,leaf: true
                ,checked: false
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'zones6'})
                ,layerName: "overlay:zones6"
            },{
                text: 'Sites classés'
                ,leaf: true
                ,checked: false
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'zones8'})
                ,layerName: "overlay:zones8"
            },{
                text: 'Sites inscrits'
                ,leaf: true
                ,checked: false
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'zones9'})
                ,layerName: "overlay:zones9"
            },,{
                text: 'Programme d\'aménagement forestier'
                ,leaf: true
                ,checked: false
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'zones10'})
                ,layerName: "overlay:zones10"
            },{
                text: 'Réserves naturelles'
                ,leaf: true
                ,checked: false
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'zones11'})
                ,layerName: "overlay:zones11"
            },{
                text: 'Arretés de biotope'
                ,leaf: true
                ,checked: false
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'zones12'})
                ,layerName: "overlay:zones12"
            }]
        },
        {
            text: "Aires de présence"
            ,leaf: false
            ,checked: true
            ,layerName: "overlay:ap"
            ,expanded: false
            ,children: [{
                text: 'validées'
                ,leaf: true
                ,checked: true
                ,cls: 'x-hide-checkbox' // this hides the checkbox
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'ap_poly', rule: 'topologies_valides'})
                ,layerName: "overlay:ap"
            },{
                text: 'non validées'
                ,leaf: true
                ,checked: true
                ,cls: 'x-hide-checkbox' // this hides the checkbox
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'ap_poly', rule: 'topologies_non_valides'})
                ,layerName: "overlay:ap"
            },{
                text: 'validées'
                ,leaf: true
                ,checked: true
                ,cls: 'x-hide-checkbox' // this hides the checkbox
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'ap_line', rule: 'topologies_valides'})
                ,layerName: "overlay:ap"
            },{
                text: 'non validées'
                ,leaf: true
                ,checked: true
                ,cls: 'x-hide-checkbox' // this hides the checkbox
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'ap_line', rule: 'topologies_non_valides'})
                ,layerName: "overlay:ap"
            },{
                text: 'validées'
                ,leaf: true
                ,checked: true
                ,cls: 'x-hide-checkbox' // this hides the checkbox
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'ap_point', rule: 'topologies_valides'})
                ,layerName: "overlay:ap"
            },{
                text: 'non validées'
                ,leaf: true
                ,checked: true
                ,cls: 'x-hide-checkbox' // this hides the checkbox
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'ap_point', rule: 'topologies_non_valides'})
                ,layerName: "overlay:ap"
            }]
        }
    ];

    var tree = new mapfish.widgets.LayerTree({
        id:'layer-tree-tip'
        ,map: map
        ,model: model
        ,height: 260
    });


    return new Ext.Tip({
        width:230,
        title: 'Couches',
        items: tree,
        shadow: false,
        closable:true,
        listeners:{
            beforehide:function(){
                if(Ext.getCmp('zp-layertreetip')){
                    Ext.getCmp('zp-layertreetip').toggle(false);
                }
                if(Ext.getCmp('search-layertreetip')){
                    Ext.getCmp('search-layertreetip').toggle(false);
                }
            }
        }
    });
};
