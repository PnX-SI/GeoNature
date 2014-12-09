<?php 

/**
 * Encode & decode GeoJSON
 *
 */
class GeoJSON
{

	/**
	 * Empty GeoJSON content
	 *
	 * @var string $empty
	 */
	public static $empty = '{"type":"FeatureCollection","features":[]}';
	
	private $GeoJSON; 
	
	protected $options = array(
	  'geo_column' => 'the_geom'
	);
	
	/**
	 * Decodes GeoJSON as an array
	 *
	 * @param string $GeoJSON
	 * 
	 * @return array
	 */
	public static function decode($GeoJSON)
	{
		
	}
	
	public function __construct()
	{
		
	}
	
	/**
	 * Encode array as GeoJSON
	 *
	 * @param array $items
	 * 
	 * @return string The GeoJSON string
	 */
	public function encode(mfGeometry $geometry)
	{
		switch ($geometry->getGeometryType())
		{
			case mfGeometry::FEATURECOLLECTION:
				return $this->encodeFeatureCollection($geometry);
				break;
		  case mfGeometry::FEATURE:
		  	return $this->encodeFeature($geometry);
		  	break;
		  case mfGeometry::GEOMETRY:
		  	return $this->encodeGeometry($geometry);
		  	break;
		  default:
		  	throw new Exception('No Implementation for : '.$geometry->getGeometryType());
		}
	}
	
	public function encodeFeatureCollection(mfFeatureCollection $featureCollection)
	{
		$features = array();
		foreach ($featureCollection as $feature)
		{
			$features = $this->encodeFeature($feature);
		}
    $featureCollection = array( 
      'type' => 'FeatureCollection',
      'features' => $features
    );

    return $featureCollection;
	}

  public function encodeFeature(mfFeatureCollection $geometry)
  {
    
  }
  
  public function encodeGeometry(mfFeatureCollection $geometry)
  {
    
  }
  
  
  /**
   * extract one feature properties & geometry
   *
   * @param string $geoJson
   * @return array 
   */
  public static function extractOne($geoJson)
  {
    $data = json_decode($geoJson, true);
    
    if (is_null($data) || empty($data['features']))
      return array(false, false);
    
    $item = array_shift($data['features']);
     
    return array($item['properties'], $item['properties']);
  }
  
}