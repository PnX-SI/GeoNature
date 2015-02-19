<script type="text/javascript">
Ext.onReady(function() {
    Ext.QuickTips.init();
    application.init();

    setTimeout(function() {
        Ext.get('loading').remove();
        Ext.get('loading-mask').fadeOut({remove:true});
    }, 2250);

});
</script>
<div id="loading-mask" style=""></div>
<div id="loading">
    <div class="loading-indicator"><img src="images/large-loading.gif" width="32" height="32" style="margin-right:8px;" align="absmiddle"/>Chargement...</div>
</div>
<div id="north"></div>