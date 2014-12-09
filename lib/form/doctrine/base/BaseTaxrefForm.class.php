<?php

/**
 * Taxref form base class.
 *
 * @method Taxref getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseTaxrefForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'cd_nom'       => new sfWidgetFormInputHidden(),
      'id_statut'    => new sfWidgetFormInputText(),
      'id_habitat'   => new sfWidgetFormInputText(),
      'id_rang'      => new sfWidgetFormInputText(),
      'regne'        => new sfWidgetFormInputText(),
      'phylum'       => new sfWidgetFormInputText(),
      'classe'       => new sfWidgetFormInputText(),
      'ordre'        => new sfWidgetFormInputText(),
      'famille'      => new sfWidgetFormInputText(),
      'cd_taxsup'    => new sfWidgetFormInputText(),
      'cd_ref'       => new sfWidgetFormInputText(),
      'lb_nom'       => new sfWidgetFormInputText(),
      'lb_auteur'    => new sfWidgetFormInputText(),
      'nom_complet'  => new sfWidgetFormInputText(),
      'nom_vern'     => new sfWidgetFormInputText(),
      'nom_vern_eng' => new sfWidgetFormInputText(),
    ));

    $this->setValidators(array(
      'cd_nom'       => new sfValidatorChoice(array('choices' => array($this->getObject()->get('cd_nom')), 'empty_value' => $this->getObject()->get('cd_nom'), 'required' => false)),
      'id_statut'    => new sfValidatorString(array('max_length' => 1, 'required' => false)),
      'id_habitat'   => new sfValidatorInteger(array('required' => false)),
      'id_rang'      => new sfValidatorString(array('max_length' => 4, 'required' => false)),
      'regne'        => new sfValidatorString(array('max_length' => 20, 'required' => false)),
      'phylum'       => new sfValidatorString(array('max_length' => 50, 'required' => false)),
      'classe'       => new sfValidatorString(array('max_length' => 50, 'required' => false)),
      'ordre'        => new sfValidatorString(array('max_length' => 50, 'required' => false)),
      'famille'      => new sfValidatorString(array('max_length' => 50, 'required' => false)),
      'cd_taxsup'    => new sfValidatorInteger(array('required' => false)),
      'cd_ref'       => new sfValidatorInteger(array('required' => false)),
      'lb_nom'       => new sfValidatorString(array('max_length' => 100, 'required' => false)),
      'lb_auteur'    => new sfValidatorString(array('max_length' => 150, 'required' => false)),
      'nom_complet'  => new sfValidatorString(array('max_length' => 255, 'required' => false)),
      'nom_vern'     => new sfValidatorString(array('max_length' => 255, 'required' => false)),
      'nom_vern_eng' => new sfValidatorString(array('max_length' => 100, 'required' => false)),
    ));

    $this->widgetSchema->setNameFormat('taxref[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'Taxref';
  }

}
