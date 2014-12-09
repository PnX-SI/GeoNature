<?php
abstract class gjObject{

	public function addCustomMember($key, $value)
	{
		if ($key != 'type')
		{
			$this->$key=$value;
		}
	}
}

abstract class gjGeometry extends gjObject
{
	
}
?>