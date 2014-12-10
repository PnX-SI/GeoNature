<?php

/**
 * Enter description here...
 *
 */
class mfQuery extends Doctrine_Query
{
  /**
   * Private property __geoColumn
   *   The name of the geographic column
   *
   * @var string
   */
  private $__geoColumn;
  
  /**
   * Private Property __format
   *   Format string for geom column transform in select statement
   *
   * @var array
   */
  private static $__format = array(
    'BINARY' => ", encode(st_asbinary(%s), 'hex') %s"
  );
  
  /**
   * Create the query & set the geo column
   *
   * @param string $column
   * @return mfQuery 
   */
  public static function create( $column='the_geom', $conn = NULL, $class = NULL)
  {
    $instance = new self();
    $instance->__geoColumn = $column;
    
    return $instance;
  }
  
  /**
   * sets the SELECT part of the query, and add geo column according to format
   *
   * @param string $string
   * @param mixed $append false or string : way to transform the geom 
   * @return mfQuery
   */
  public function select($string=NULL, $append='BINARY')
  {
    if ($append!==false){
        $string .= sprintf(self::$__format[$append], $this->__geoColumn, $this->__geoColumn);
    }
    return parent::select($string);
  }
  /**
  * fonction modifiée par Gil Deluermoz pour permettre de servir une géométrie reprojettée à la volée par mapfish
  * @param string $column
  * @param string $output_srid
  * @return mfQuery 
  public function select($string, $output_srid, $append='BINARY')
  {
    if ($append!==false){
        if($output_srid){
            $string .= sprintf(self::$__format[$append], "ST_Transform(".$this->__geoColumn.",".$output_srid.")", $this->__geoColumn);
        }
        else{
            $string .= sprintf(self::$__format[$append], $this->__geoColumn, $this->__geoColumn);
        }
    }
    return parent::select($string);
  }
  */
  
  /**
   * Add where clause with geometry constrains in bbox
   *
   * @param array $box
   * @return mfQuery
   */
  public function inBBox(array $box)
  {
    $box = array_map('floatval', $box);

    $A = $box[0].' '.$box[1];
    $B = $box[0].' '.$box[3];
    $C = $box[2].' '.$box[3];
    $D = $box[2].' '.$box[1];

    return $this->intersect("POLYGON(($A, $B, $C, $D, $A))");
  }
  
  
  public function intersect($geometry)
  {
    $srid = sfConfigSynthese::$srid_local;
    $pg_geometry = 'st_GEOMETRYFROMTEXT(?, '.$srid .')';
    $the_geom = $this->__geoColumn;

    $this
      ->addWhere("$the_geom && $pg_geometry", $geometry)
      ->andWhere("st_DISTANCE($pg_geometry, $the_geom) <= 0", $geometry);
      
    return $this;
  }
}
