<?php
require_once dirname(__FILE__) . '/gjInterface.php';

class gjFeature extends gjObject
{
	public $type = "Feature";
    public $id;
	public $properties;
    public $geometry;
	
    public function __construct($id) {
        $this->properties = new stdClass();
        $this->id = $id;
    }
    
	public function setGeometry(gjGeometry $gjGeometry)
	{
        $this->geometry=$gjGeometry;
	}
	
	public function getGeometry()
	{
		return $this->geometry;
	}
	
	public function setProperty($key,$value)
	{
		$this->properties->$key=$value;
	}
	
	public function getProperty($key)
	{
		return $this->properties->$key;
	}
	
	public function getProperties()
	{
		return $this->properties;
	}
	
    public function setProperties(stdClass $stdClass)
	{
		 $this->properties=$stdClass;
	}

}
?>