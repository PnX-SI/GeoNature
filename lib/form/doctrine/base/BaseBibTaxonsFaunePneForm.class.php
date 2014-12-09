<?php

/**
 * BibTaxonsFaunePne form base class.
 *
 * @method BibTaxonsFaunePne getObject() Returns the current form's model object
 *
 * @package    pa_back
 * @subpackage form
 * @author     Your name here
 * @version    SVN: $Id: sfDoctrineFormGeneratedTemplate.php 29553 2010-05-20 14:33:00Z Kris.Wallsmith $
 */
abstract class BaseBibTaxonsFaunePneForm extends BaseFormDoctrine
{
  public function setup()
  {
    $this->setWidgets(array(
      'id_taxon'     => new sfWidgetFormInputHidden(),
      'cd_nom'       => new sfWidgetFormInputText(),
      'nom_latin'    => new sfWidgetFormInputText(),
      'nom_francais' => new sfWidgetFormInputText(),
      'auteur'       => new sfWidgetFormInputText(),
      'syn_fr'       => new sfWidgetFormInputText(),
      'syn_la'       => new sfWidgetFormInputText(),
      'prot_fv'      => new sfWidgetFormInputText(),
    ));

    $this->setValidators(array(
      'id_taxon'     => new sfValidatorChoice(array('choices' => array($this->getObject()->get('id_taxon')), 'empty_value' => $this->getObject()->get('id_taxon'), 'required' => false)),
      'cd_nom'       => new sfValidatorInteger(array('required' => false)),
      'nom_latin'    => new sfValidatorString(array('max_length' => 100, 'required' => false)),
      'nom_francais' => new sfValidatorString(array('max_length' => 50, 'required' => false)),
      'auteur'       => new sfValidatorString(array('max_length' => 50, 'required' => false)),
      'syn_fr'       => new sfValidatorString(array('max_length' => 80, 'required' => false)),
      'syn_la'       => new sfValidatorString(array('max_length' => 80, 'required' => false)),
      'prot_fv'      => new sfValidatorInteger(array('required' => false)),
    ));

    $this->widgetSchema->setNameFormat('bib_taxons_faune_pne[%s]');

    $this->errorSchema = new sfValidatorErrorSchema($this->validatorSchema);

    $this->setupInheritance();

    parent::setup();
  }

  public function getModelName()
  {
    return 'BibTaxonsFaunePne';
  }

}
