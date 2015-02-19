<?php

/**
 * print actions.
 *
 * @package    OieauConchyli
 * @subpackage print
 * @author     Your name here
 * @version    SVN: $Id: actions.class.php 9301 2008-05-27 01:08:46Z dwhittle $
 */
class printActions extends sfActions
{
  
  /**
   * Temporary file prefix / suffix
   *
   * @var string
   */
  protected $_temp_file_prefix = 'mfPrintTempFile_';
  protected $_temp_file_suffix = '.pdf';


  protected $_java_bin = '';
  
  /**
   * Delay in seconds before a temporary file is deleted
   *
   * @var integer
   */
  protected $_temp_file_purge_seconds = 300;
  
  /**
   * MF config
   */
  protected $jarPath; 
  protected $configPath;
  protected $tmpDir;
  
  /**
   * Set MF config variables
   *
   * @see sfAction#preExecute()
   */
  public function preExecute()
  {
    $this->jarPath = sfConfig::get('sf_root_dir').
      '/print/print-standalone/target/print-standalone.jar';
    $this->configPath = sfConfig::get('sf_root_dir').
      '/config/print.yml';
    $this->tmpDir = sfConfig::get('sf_cache_dir');
  }

  
 /**
  * Executes index action
  *
  * @param sfRequest $request A request object
  */
  public function executeIndex($request)
  {
    $this->forward('default', 'module');
  }
  
  private function mycmd_exec($cmd, $input, &$stdout, &$stderr)
  {

    $outfile = tempnam($this->tmpDir, "cmd"); 
    $errfile = tempnam($this->tmpDir, "cmd");
    
    $descriptorspec = array(
        0 => array("pipe", "r"),
        1 => array("file", $outfile, "w"),
        2 => array("file", $errfile, "w")
    );
    $proc = proc_open($cmd, $descriptorspec, $pipes);
   
    if (!is_resource($proc)) return 255;
    if ($input) {
        fwrite($pipes[0], $input);
    }
    fclose($pipes[0]);
    $exit = proc_close($proc);
    
    $stdout = file($outfile);
    $stderr = file($errfile);
    
    unlink($outfile);
    unlink($errfile);
    
    return $exit;
  }
  
  public function executeInfo() 
  {
    $_cmd = $this->_java_bin.'java -Djava.awt.headless=true -cp "'.$this->jarPath.
      '" org.mapfish.print.ShellMapPrinter --config="'. $this->configPath.
      '" --clientConfig --verbose=0';

    $stdout = array();
    $stderr = array();
    $return = $this->mycmd_exec($_cmd, null, $stdout, $stderr);
    if ($return == 0) {
      $object = json_decode($stdout[0], true);
      $this->_addURLs($object);
      return $this->renderText(json_encode($object));
    } else {
      $this->forward404();
    }
  }

  /**
   * All in one method: creates and returns the PDF to the client.
   */
  public function executeDoprint() 
  {
    $_cmd = array(
      $this->_java_bin.'java', 
      '-Djava.awt.headless=true -cp', 
      '"'.$this->jarPath.'"', 
      'org.mapfish.print.ShellMapPrinter',
      '--config="'. $this->configPath.'"', 
      '--verbose=0'
    );
            
    $stdout = array();
    $stderr = array();
    $return = $this->mycmd_exec(
      implode(' ', $_cmd), $this->_getParam('spec'), $stdout, $stderr
    );
    
    if ($return == 0)
    {
      $pdf = implode('', $stdout);
      $this->getResponse()->clearHttpHeaders(); 
      $this->getResponse()->setContentType('application/pdf');            
      $this->getResponse()->setHttpHeader(
        "Content-Disposition", 
        'inline; filename="flore_pda_print.pdf"'
      );        
      $this->getResponse()->setHttpHeader("Content-Length", strlen($pdf));
      return $this->renderText($pdf);
    } else {
      $this->forward404();
    }
  }
  
  /**
   * Creates the PDF and returns to the client (in JSON) the URL to get it.
   */
  public function executeCreate(sfRequest $request)
  {
    sfLoader::loadHelpers('Url');
  
    $this->_purgeOldFiles();
    $pdf_path = $this->_newtempnam(
      $this->tmpDir, $this->_temp_file_prefix, $this->_temp_file_suffix
    );
    
    $_cmd = $this->_java_bin.'java -Djava.awt.headless=true -cp "'.$this->jarPath.
      '" org.mapfish.print.ShellMapPrinter --config="'. $this->configPath.
      '" --verbose=0 --output="'.$pdf_path.'"';
    
    $stdout = array();
    $stderr = array();
    $putdata = file_get_contents('php://input');

    $return = $this->mycmd_exec($_cmd, $putdata, $stdout, $stderr);
  
    if ($return == 0) {
      $curId = substr(
        $pdf_path, 
        strpos($pdf_path, $this->_temp_file_prefix) + strlen($this->_temp_file_prefix), 
        -strlen($this->_temp_file_suffix)
      );
      $out = array('getURL' => url_for('/flore/print/get?id='.$curId));
      return $this->renderText(json_encode($out));
    } else {
      unlink($pdf_path);
      $this->forward404();
    }
  }
  
  /**
   * To get the previously created PDF.
   */
  public function executeGet(sfRequest $request) 
  {
    $pdf_path = $this->tmpDir.DIRECTORY_SEPARATOR.$this->_temp_file_prefix.
      $request->getParameter('id').$this->_temp_file_suffix;
    if (file_exists($pdf_path) && is_readable($pdf_path)) {
      $pdf = file_get_contents($pdf_path);
      if ($pdf) {
        $this->getResponse()->clearHttpHeaders(); 
        $this->getResponse()->setContentType('application/pdf');            
        $this->getResponse()->setHttpHeader(
          "Content-Disposition", 
          'attachment; filename="flore_pda_print_'.$request->getParameter('id').'.pdf"'
        );        
        $this->getResponse()->setHttpHeader("Content-Length", strlen($pdf));
        return $this->renderText($pdf);
      }
    } else {
      return $this->renderText('File doesn\'t exists anymore');
    }
  }
  
  private function _addURLs(&$object) 
  {
    sfLoader::loadHelpers(array('Url'));
    $object['printURL'] = url_for('print/doprint', true);
    $object['createURL'] = url_for('print/create', true);
  }
  
 /**
   * Delete temporary files that are more than $this->_temp_file_purge_seconds seconds old
   */
  private function _purgeOldFiles() 
  {
    $pdfs = glob(
      $this->tmpDir.'/'.$this->_temp_file_prefix.'*'.$this->_temp_file_prefix
    );
    foreach ($pdfs as $pdf)
    {
      if (round(time() - filemtime($pdf)) > $this->_temp_file_purge_seconds)
        unlink($pdf);
    }
  }
    
  /**
   * Creates a new non-existant file with the specified post and pre fixes
   */
  private function _newtempnam($dir, $prefix, $postfix)
  {
    if ($dir[strlen($dir) - 1] == '/') {
        $trailing_slash = "";
    } else {
        $trailing_slash = "/";
    }
    /*The PHP function is_dir returns true on files that have no extension.
    The filetype function will tell you correctly what the file is */
    if (!is_dir(realpath($dir)) || filetype(realpath($dir)) != "dir") {
        // The specified dir is not actualy a dir
        return false;
    }
    if (!is_writable($dir)) {
        // The directory will not let us create a file there
        return false;
    }
   
    do {
        $seed = substr(md5(microtime().rand()), 0, 8);
        $filename = $dir . $trailing_slash . $prefix . $seed . $postfix;
    } while (file_exists($filename));
    
    $fp = fopen($filename, "w");
    fclose($fp);
    
    return $filename;
  }
  
}
