import { InjectionToken } from '@angular/core';
// Although the ApplicationConfig interface plays no role in dependency injection,
// it supports typing of the configuration object within the class.
export class AppConfig {
  appName: string;
  defaultLanguage: string;
  apiEndpoint: string;
  welcomeMessage: string;
  shortMessage: string;
}

// Configuration values for our app
export const CONFIG: AppConfig = {
  appName: 'Geonature 2',
  defaultLanguage: 'en', // value obligatory 'en' or 'fr'
  apiEndpoint: 'http://www',
  // tslint:disable-next-line:max-line-length
  welcomeMessage: 'Bienvenue dans la version 2 de GeoNature. Lorem ipsum dolor sit amet, eu eum postea aliquam luptatum. Est ex inermis nominati. An quo feugiat accommodare, suas integre dolorum cu nec, oratio torquatos reprimique mea ut. Eu quod partiendo usu, graeco prompta menandri ex usu. Est ut diam dolores, odio rationibus sit eu, mucius utroque at est. Has lorem delicata praesent in, nec te tincidunt moderatius, mei an duis homero sapientem. Pri ad augue soleat. Ex eum erant iudico diceret, facilisis signiferumque per ex. Ancillae convenire evertitur his an, qui te admodum percipitur, ei vix option adolescens scripserit. Duo ne illud detracto, ex meis verterem gubergren duo. An percipit praesent theophrastus eam, enim essent id vel, qui idque facer ne. Partem phaedrum disputando vel ut, posse quidam mandamus ius no. Erant consul pertinacia vel ex, posse aperiam mel an. An cum putant lobortis. Per in legere scripta qualisque, eu nam dicta cetero moderatius, duis assum ne sea. Eum sanctus senserit at, odio euismod duo at. An quando appareat atomorum sea. Ut nam graece intellegebat. Sanctus scriptorem ad per. Est ad minim mollis dolorum, nec ex ornatus vulputate. Quo ne assum virtute. Cu mea labores similique, an qui duis facete oportere. Et vide appetere salutatus sea, augue laoreet percipitur at cum, ius ei nobis libris delicatissimi.',
  shortMessage: 'Lorem ipsum dolor sit amet, eu eum postea aliquam luptatum. Est ex inermis nominati. An quo feugiat accommodare, suas integre dolorum cu nec, oratio torquatos reprimique mea ut. Eu quod partiendo usu, graeco prompta menandri ex usu. Est ut diam dolores, odio rationibus sit eu, mucius utroque at est. Has lorem delicata praesent in, nec te tincidunt moderatius, mei an duis homero sapientem.',
};

// Create a config token to avoid naming conflicts
export let APP_CONFIG = new InjectionToken<AppConfig>('app.config');
