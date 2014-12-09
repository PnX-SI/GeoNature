
Ext.namespace("application.cf");

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

application.cf.createLayerWindow = function(map) {
    var overlayLayerUrl = map.getLayersByName('overlay')[0].url;
    var model = [
        // {
            // text: "Cartes d'État-Major (1/40 000)"
            // ,id:'layer_etatmajor'
            // ,leaf: true
            // ,checked: false
            // ,layerName: "Cartes État-Major (1/40 000)"
        // },
        {
            text: "Photographies aériennes"
            ,id:'layer_ortho'
            ,leaf: true
            ,checked: false
            ,layerName: "Ortho-imagerie"
        }
        // ,{
            // text: "Parcelles cadastrales"
            // ,id:'layer_cadastre'
            // ,leaf: true
            // ,checked: false
            // ,layerName: "Parcelles cadastrales"
        // }
        ,{
            text: "Communes"
            ,leaf: true
            ,checked: false
            ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'communes'})
            ,layerName: "overlay:communes"
        }
        ,{
            text: "Délégations"
            ,leaf: true
            ,checked: false
            ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'secteurs'})
            ,layerName: "overlay:secteurs"
        }
        ,{
            text: "Unités géographiques"
            ,leaf: true
            ,checked: true
            ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'unitesgeo'})
            ,layerName: "overlay:unitesgeo"
        },{
            text: "Zones à statut"
            ,leaf: false
            ,expanded: false
            ,checked: true
            ,children: [
            {
                text: 'Aire optimale d\'adhésion'
                ,leaf: true
                ,checked: false
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'aoa'})
                ,layerName: "overlay:aoa"
            },{
                text: 'Coeur de parc national'
                ,leaf: true
                ,checked: false
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'coeur'})
                ,layerName: "overlay:coeur"
            }
            // ,{
                // text: 'Réserve intégrale'
                // ,leaf: true
                // ,checked: false
                // ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'reservesint'})
                // ,layerName: "overlay:reservesint"
            // }
            ,{
                text: 'Réserves naturelles'
                ,leaf: true
                ,checked: false
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'reservesnat'})
                ,layerName: "overlay:reservesnat"
            }
            // ,{
                // text: 'Réserves de chasse'
                // ,leaf: true
                // ,checked: false
                // ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'reserveschasse'})
                // ,layerName: "overlay:reserveschasse"
            // }
            // ,{
                // text: 'Arretés de biotope'
                // ,leaf: true
                // ,checked: false
                // ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'ab'})
                // ,layerName: "overlay:ab"
            // }
            ,{
                text: 'Sites classés'
                ,leaf: true
                ,checked: false
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'sitesclasses'})
                ,layerName: "overlay:sitesclasses"
            },{
                text: 'Sites inscrits'
                ,leaf: true
                ,checked: false
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'sitesinscrits'})
                ,layerName: "overlay:sitesinscrits"
            }
            // ,{
                // text: 'Natura 2000'
                // ,leaf: true
                // ,checked: false
                // ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'n2000'})
                // ,layerName: "overlay:n2000"
            // }
            ,{
                text: 'Znieff2'
                ,leaf: true
                ,checked: false
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'znieff2'})
                ,layerName: "overlay:znieff2"
            },{
                text: 'Znieff1'
                ,leaf: true
                ,checked: false
                ,icon: mapfish.Util.getIconUrl(overlayLayerUrl, {layer: 'znieff1'})
                ,layerName: "overlay:znieff1"
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
