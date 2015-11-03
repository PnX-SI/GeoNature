<?php 
use_helper('Form'); 
use_helper('Javascript');
// sfContext::getInstance()->getConfiguration()->loadHelpers(array('JavascriptBase', 'Tag', 'Url'));
echo 'Redirection vers la base du r&eacute;seau de conservation Alpes-Ain en cours...';

echo form_tag('http://reseau-conservation-alpes-ain.fr/flore/login','method=post name=myForm id=myForm'); 
echo input_hidden_tag('login[login]', $identifiant);
echo input_hidden_tag('login[password]', $pass);
echo input_hidden_tag('commit', 'Connexion');

echo javascript_tag("document.getElementById('myForm').submit();");
?>