<?php

require_once dirname(__FILE__).'/../lib/symfony/1.4.6/lib/autoload/sfCoreAutoload.class.php';
sfCoreAutoload::register();

class ProjectConfiguration extends sfProjectConfiguration
{
  public function setup()
  {
    $this->enablePlugins('sfDoctrinePlugin');
    $this->enablePlugins('sfMapFishPlugin');
    $this->getEventDispatcher()->connect(
  	  'request.method_not_found',
  	  array('sfRequestExtension', 'listenToMethodNotFound')
  	);
  }
}
class sfRequestExtension
{
	
  static public function listenToMethodNotFound(sfEvent $event)
  {
  	/**
  	 * Method getParams
  	 *   clean up params list and return as array
  	 *   if true, passed, prefox : is added dor doctrine link
  	 */
  	if ($event['method']=='getParams')
  	{
	  	$tmp = (array) $event->getSubject()->getParameterHolder();
	  	$params = array_shift($tmp);
	  	
	    unset($params['action'], $params['module']);

	    if (isset($event['arguments'][0]) && $event['arguments'][0]===true)
	    {
	    	foreach($params as $key => $value)
	    	{
	    		$params[':'.$key] = $value;
	    		unset($params[$key]);
	    	}
	    }

	    $event->setProcessed(true);
	    $event->setReturnValue($params);
  	}
  	
  	/**
  	 * Method getRawBody
  	 *   retrieve raw post data
  	 */
  	if ($event['method']=='getRawBody')
  	{
  		$event->setProcessed(true);
      $event->setReturnValue(file_get_contents('php://input'));
  	}
  }
}
