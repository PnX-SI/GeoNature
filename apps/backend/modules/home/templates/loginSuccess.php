<?php use_helper('Url') ?>
  <div id="titre">
   <?php echo sfGeonatureConfig::$appname_main; ?>
  </div> 
<form action="<?php echo url_for('@login') ?>" method="post" id="loginForm">
  <div id="container">
      <?php echo $form?>
      <input type="submit" id="submit" value="Connexion" />
  </div>
  <div id="reflect"></div>
</form>
