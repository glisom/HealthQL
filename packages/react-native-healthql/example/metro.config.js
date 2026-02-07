const { getDefaultConfig } = require('expo/metro-config');
const path = require('path');

const projectRoot = __dirname;
const workspaceRoot = path.resolve(projectRoot, '..');

const config = getDefaultConfig(projectRoot);

// Watch the local package
config.watchFolders = [workspaceRoot];

// Resolve modules from the workspace root
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, 'node_modules'),
  path.resolve(workspaceRoot, 'node_modules'),
];

// Ensure the local package is resolved from the parent directory
config.resolver.extraNodeModules = {
  'react-native-healthql': workspaceRoot,
};

module.exports = config;
