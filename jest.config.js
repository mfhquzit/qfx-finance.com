module.exports = {
  displayName: 'qfx-api',
  preset: 'ts-jest',
  testEnvironment: 'node',
  rootDir: 'src',
  testRegex: '.*\\.spec\\.ts$',
  transform: {
    '^.+\\.(t|j)s$': 'ts-jest',
  },
  collectCoverageFrom: [
    '**/*.(t|j)s',
  ],
  coverageDirectory: '../coverage',
  testPathIgnorePatterns: ['/node_modules/', '/dist/'],
  moduleNameMapper: {
    '^@app/(.*)$': '<rootDir>/$1',
  },
  globals: {
    'ts-jest': {
      tsconfig: {
        module: 'commonjs',
        target: 'es2022',
      },
    },
  },
};
