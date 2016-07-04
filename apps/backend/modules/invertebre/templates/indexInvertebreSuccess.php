<script type="text/javascript">
Ext.onReady(function() {
    Ext.QuickTips.init();
    application.invertebre.init();
});
</script>

<div id="loading">
  <div class="wrapper">
    <div class="loader"></div>
    <h1>Chargement…</h1>
    <h3>Invertébrés</h3>
  </div>
</div>
<div id="north"></div>

<script type="text/javascript">
function getInternetExplorerVersion()
{
  var rv = -1;
  if (navigator.appName == 'Microsoft Internet Explorer')
  {
    var ua = navigator.userAgent;
    var re  = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})");
    if (re.exec(ua) != null)
      rv = parseFloat( RegExp.$1 );
  }
  else if (navigator.appName == 'Netscape')
  {
    var ua = navigator.userAgent;
    var re  = new RegExp("Trident/.*rv:([0-9]{1,}[\.0-9]{0,})");
    if (re.exec(ua) != null)
      rv = parseFloat( RegExp.$1 );
  }
  return rv;
};
var rv = getInternetExplorerVersion()
var msg = '';
if(rv != -1){
    msg= 'Le fonctionnement de l\'application n\'est pas garanti avec Internet Explorer. Utilisez plutôt Firefox ou Chrome';
    document.getElementsByTagName('h3')[0].innerHTML = msg;
}
</script>