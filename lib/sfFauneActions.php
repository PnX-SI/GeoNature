<?php 

class sfFauneActions extends sfActions
{
    public static $EmptyGeoJSON = '{"type":"FeatureCollection","features":[]}';
    public static $toManyFeatures = '{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"nb": 0}}]}';
    public function comptFeatures($nb=0){
        return $this->renderText('{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"nb":'.$nb.'}}]}');
    }
	/**
   * Returns ext error template, with error details if form errors passed
   * 
   * @param mixed array or sfValidatorErrorSchema $errorSchema 
   */
	public function throwError($errorSchema=null)
	{
	    use_helper('I18N');
		$errors = '';
		if (!is_null($errorSchema))
		{
			$obj = new stdClass();
			foreach ($errorSchema as $field => $msg)
			{
			  $obj->$field = ($errorSchema instanceof sfValidatorErrorSchema)?
			   __($msg->getMessage()):
			   __($msg); 
			} 
			$errors = ', errors: '.json_encode($obj);
		}
		return $this->renderText('{ success: false'.$errors.' }');
	}
	
 /**
  * Returns ext success template
  * 
  * @return sfView::NONE
  */
  public function renderSuccess()
  {
    return $this->renderText('{ success: true }');
  }
  
  public function renderJsonLoad(array $array)
  {
    return $this->renderText('{success: true ,data:'.str_replace(array("[","]"),array("",""),json_encode($array)).'}');
  }
  
  /**
   * Render & return text response, formatted in JSON or GeoJSON
   *
   * @param array $array
   * @param string $format
   * 
   * @return sfView::NONE
   */
  public function renderJSON(array $array, $format='JSON')
  {
  	$format = trim(strtoupper($format));
  	switch ($format)
  	{
  		case 'GEOJSON':
  		  return $this->renderText(json_encode($array));
  		  break;
  		default:
  			return $this->renderText(json_encode($array));
  	}
  } 
 }
