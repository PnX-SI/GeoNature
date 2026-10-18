module.exports = {
  preset: 'jest-preset-angular',
  setupFilesAfterEnv: ['<rootDir>/setup-jest.ts'],
  testEnvironment: 'jsdom',
  roots: ['<rootDir>/src'],
  testMatch: ['**/*.spec.ts'],
  resolver: '<rootDir>/jest-resolver.js',
  // let the Ivy builds processed by ngcc be transformed (see jest-resolver.js)
  transformIgnorePatterns: ['node_modules/(?!.*\\.mjs$|.*/__ivy_ngcc__/)'],
  moduleNameMapper: {
    '^@geonature_common/(.*)$': '<rootDir>/src/app/GN2CommonModule/$1',
    '^@geonature_config/(.*)$': '<rootDir>/src/conf/$1',
    '^@geonature/(.*)$': '<rootDir>/src/app/$1',
    '^@librairies/(.*)$': '<rootDir>/node_modules/$1',
  },
  transform: {
    '^.+\\.(ts|js|mjs|html|svg)$': [
      'jest-preset-angular',
      {
        tsconfig: '<rootDir>/src/tsconfig.spec.json',
        stringifyContentPathRegex: '\\.(html|svg)$',
      },
    ],
  },
};
