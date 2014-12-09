<?php
require_once dirname(__FILE__) . '/gjInterface.php';

class gjGeometryCollection extends gjGeometry
{
    public $type = "GeometryCollection";
	public $geometries = array();
	
	public function addGeometry(gjGeometry $gjGeometry)
	{
		$this->geometries[] = $gjGeometry;
	}
}
?>