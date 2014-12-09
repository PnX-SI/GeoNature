<?php
require_once dirname(__FILE__) . '/gjInterface.php';

class gjBox extends gjGeometry
{
	public $type = "Box";
	public $coordinates = array();
	
	public function setMaxXMaxY($x, $y)
	{
		$this->coordinates[1] = array($x, $y);
	}
	
    public function setMinXMinY($x, $y)
	{
		$this->coordinates[0] = array($x, $y);
	}
}
?>