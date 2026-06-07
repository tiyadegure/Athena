/**
 * glm-tui 配置模块
 * 
 * 管理 glm-tui 的所有配置选项
 */

const path = require('path');
const fs = require('fs');

// 配置文件路径
const CONFIG_FILES = [
  // 项目级配置
  path.join(process.cwd(), '.glm-tui.json'),
  path.join(process.cwd(), '.glm-tui.js'),
  
  // 用户级配置
  path.join(process.env.HOME || process.env.USERPROFILE, '.glm-tui.json'),
  path.join(process.env.HOME || process.env.USERPROFILE, '.glm-tui.js'),
];

/**
 * 默认配置
 */
const DEFAULT_CONFIG = {
  // 模型配置
  provider: 'anthropic',
  model: 'claude-sonnet-4-20250514',
  
  // GLM-5.1 配置（后续版本启用）
  glm: {
    apiKey: process.env.GLM_API_KEY || '',
    model: process.env.GLM_MODEL || 'glm-5.1',
    endpoint: process.env.GLM_ENDPOINT || 'https://api.z.ai/api/coding/paas/v4',
    thinkingMode: 'auto', // 'auto', 'on', 'off', 'interleaved'
  },
  
  // 提示词配置
  prompts: {
    system: path.join(__dirname, '..', 'prompts', 'system.md'),
    planning: path.join(__dirname, '..', 'prompts', 'planning.md'),
    correction: path.join(__dirname, '..', 'prompts', 'correction.md'),
  },
  
  // 功能开关
  features: {
    planningMode: true,
    selfCorrection: true,
    longContext: true,
    interleavedThinking: true,
  },
  
  // Pi 配置
  pi: {
    args: [],
    systemPromptAppend: '',
  },
  
  // 上下文管理
  context: {
    maxTokens: 200000, // GLM-5.1 支持 200K
    compactionThreshold: 0.8, // 80% 时触发压缩
    preserveThinking: true, // 保留 thinking 块
  },
  
  // 工具配置
  tools: {
    enabled: ['read', 'write', 'edit', 'bash', 'grep', 'find', 'ls'],
    disabled: [],
  },
};

/**
 * 加载配置文件
 */
function loadConfigFile(filePath) {
  try {
    if (!fs.existsSync(filePath)) {
      return null;
    }
    
    const ext = path.extname(filePath);
    
    if (ext === '.json') {
      const content = fs.readFileSync(filePath, 'utf-8');
      return JSON.parse(content);
    }
    
    if (ext === '.js') {
      // 清除 require 缓存以支持热重载
      delete require.cache[require.resolve(filePath)];
      return require(filePath);
    }
  } catch (err) {
    console.warn(`Warning: Could not load config file ${filePath}:`, err.message);
  }
  
  return null;
}

/**
 * 深度合并配置
 */
function mergeConfig(target, source) {
  const result = { ...target };
  
  for (const key of Object.keys(source)) {
    if (source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])) {
      result[key] = mergeConfig(target[key] || {}, source[key]);
    } else {
      result[key] = source[key];
    }
  }
  
  return result;
}

/**
 * 验证配置
 */
function validateConfig(config) {
  const errors = [];
  
  // 验证必填字段
  if (!config.provider) {
    errors.push('provider is required');
  }
  
  if (!config.model) {
    errors.push('model is required');
  }
  
  // 验证 GLM 配置
  if (config.glm) {
    if (config.glm.thinkingMode && !['auto', 'on', 'off', 'interleaved'].includes(config.glm.thinkingMode)) {
      errors.push('glm.thinkingMode must be one of: auto, on, off, interleaved');
    }
  }
  
  // 验证上下文配置
  if (config.context) {
    if (config.context.maxTokens && config.context.maxTokens < 1000) {
      errors.push('context.maxTokens must be at least 1000');
    }
    
    if (config.context.compactionThreshold && 
        (config.context.compactionThreshold < 0 || config.context.compactionThreshold > 1)) {
      errors.push('context.compactionThreshold must be between 0 and 1');
    }
  }
  
  return errors;
}

/**
 * 加载完整配置
 */
function loadConfig(overrides = {}) {
  let config = { ...DEFAULT_CONFIG };
  
  // 加载配置文件
  for (const configFile of CONFIG_FILES) {
    const fileConfig = loadConfigFile(configFile);
    if (fileConfig) {
      config = mergeConfig(config, fileConfig);
    }
  }
  
  // 应用环境变量
  if (process.env.GLM_API_KEY) {
    config.glm.apiKey = process.env.GLM_API_KEY;
  }
  
  if (process.env.GLM_MODEL) {
    config.glm.model = process.env.GLM_MODEL;
  }
  
  if (process.env.GLM_ENDPOINT) {
    config.glm.endpoint = process.env.GLM_ENDPOINT;
  }
  
  // 应用命令行参数覆盖
  config = mergeConfig(config, overrides);
  
  // 验证配置
  const errors = validateConfig(config);
  if (errors.length > 0) {
    console.warn('Configuration warnings:');
    errors.forEach(err => console.warn(`  - ${err}`));
  }
  
  return config;
}

/**
 * 获取配置值
 */
function getConfig(config, key, defaultValue) {
  const keys = key.split('.');
  let value = config;
  
  for (const k of keys) {
    if (value && typeof value === 'object' && k in value) {
      value = value[k];
    } else {
      return defaultValue;
    }
  }
  
  return value !== undefined ? value : defaultValue;
}

/**
 * 设置配置值
 */
function setConfig(config, key, value) {
  const keys = key.split('.');
  let current = config;
  
  for (let i = 0; i < keys.length - 1; i++) {
    const k = keys[i];
    if (!(k in current) || typeof current[k] !== 'object') {
      current[k] = {};
    }
    current = current[k];
  }
  
  current[keys[keys.length - 1]] = value;
  return config;
}

/**
 * 保存配置到文件
 */
function saveConfig(config, filePath) {
  try {
    const ext = path.extname(filePath);
    let content;
    
    if (ext === '.json') {
      content = JSON.stringify(config, null, 2);
    } else if (ext === '.js') {
      content = `module.exports = ${JSON.stringify(config, null, 2)};\n`;
    } else {
      throw new Error(`Unsupported config file extension: ${ext}`);
    }
    
    fs.writeFileSync(filePath, content, 'utf-8');
    return true;
  } catch (err) {
    console.error(`Error saving config to ${filePath}:`, err.message);
    return false;
  }
}

module.exports = {
  DEFAULT_CONFIG,
  loadConfig,
  getConfig,
  setConfig,
  saveConfig,
  validateConfig,
  mergeConfig,
  CONFIG_FILES,
};
