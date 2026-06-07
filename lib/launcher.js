/**
 * glm-tui 启动器模块
 * 
 * 负责初始化和启动 Pi harness，加载 glm-tui 配置
 */

const { spawn, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const { loadConfig, getConfig } = require('./config');

/**
 * Pi 启动器类
 */
class PiLauncher {
  constructor(options = {}) {
    this.options = options;
    this.config = loadConfig(options.configOverrides || {});
    this.process = null;
  }
  
  /**
   * 查找 Pi 可执行文件
   */
  findPiBinary() {
    // 1. 检查本地 node_modules
    const localPi = path.join(__dirname, '..', 'node_modules', '.bin', 'pi');
    if (fs.existsSync(localPi)) {
      return localPi;
    }
    
    // 2. 检查全局安装
    try {
      const globalBin = execSync('which pi', { encoding: 'utf-8' }).trim();
      if (globalBin) {
        return globalBin;
      }
    } catch (err) {
      // ignore
    }
    
    // 3. 检查 npx
    try {
      execSync('npx pi --version', { encoding: 'utf-8', stdio: 'pipe' });
      return 'npx';
    } catch (err) {
      // ignore
    }
    
    return null;
  }
  
  /**
   * 构建系统提示词
   */
  buildSystemPrompt() {
    const parts = [];
    const prompts = this.config.prompts;
    
    // 读取核心系统提示词
    if (prompts.system && fs.existsSync(prompts.system)) {
      parts.push(fs.readFileSync(prompts.system, 'utf-8'));
    }
    
    // 读取规划模式提示词
    if (getConfig(this.config, 'features.planningMode', true) && 
        prompts.planning && fs.existsSync(prompts.planning)) {
      parts.push(fs.readFileSync(prompts.planning, 'utf-8'));
    }
    
    // 读取自我纠错提示词
    if (getConfig(this.config, 'features.selfCorrection', true) && 
        prompts.correction && fs.existsSync(prompts.correction)) {
      parts.push(fs.readFileSync(prompts.correction, 'utf-8'));
    }
    
    // 添加用户自定义追加内容
    const append = getConfig(this.config, 'pi.systemPromptAppend', '');
    if (append) {
      parts.push(append);
    }
    
    return parts.join('\n\n---\n\n');
  }
  
  /**
   * 构建 Pi 参数
   */
  buildPiArgs(userArgs = []) {
    const args = [];
    
    // 模型配置
    args.push('--provider', this.config.provider);
    args.push('--model', this.config.model);
    
    // 系统提示词
    const systemPrompt = this.buildSystemPrompt();
    if (systemPrompt) {
      args.push('--system-prompt', systemPrompt);
    }
    
    // 工具配置
    if (this.config.tools) {
      if (this.config.tools.enabled && this.config.tools.enabled.length > 0) {
        args.push('--tools', this.config.tools.enabled.join(','));
      }
      if (this.config.tools.disabled && this.config.tools.disabled.length > 0) {
        args.push('--exclude-tools', this.config.tools.disabled.join(','));
      }
    }
    
    // Pi 配置
    if (this.config.pi && this.config.pi.args) {
      args.push(...this.config.pi.args);
    }
    
    // 用户参数
    args.push(...userArgs);
    
    return args;
  }
  
  /**
   * 启动 Pi
   */
  async launch(userArgs = []) {
    const piBin = this.findPiBinary();
    
    if (!piBin) {
      throw new Error(
        'Could not find pi binary. Please install @earendil-works/pi-coding-agent\n' +
        'Run: npm install -g @earendil-works/pi-coding-agent'
      );
    }
    
    const args = this.buildPiArgs(userArgs);
    
    // 准备环境变量
    const env = {
      ...process.env,
      GLM_TUI_ROOT: path.join(__dirname, '..'),
      GLM_TUI_VERSION: require('../package.json').version,
    };
    
    // GLM 配置（后续版本启用）
    if (this.config.glm) {
      if (this.config.glm.apiKey) {
        env.GLM_API_KEY = this.config.glm.apiKey;
      }
      if (this.config.glm.model) {
        env.GLM_MODEL = this.config.glm.model;
      }
      if (this.config.glm.endpoint) {
        env.GLM_ENDPOINT = this.config.glm.endpoint;
      }
    }
    
    // 启动进程
    this.process = spawn(piBin, args, {
      stdio: 'inherit',
      cwd: this.options.cwd || process.cwd(),
      env,
    });
    
    // 处理进程事件
    return new Promise((resolve, reject) => {
      this.process.on('error', (err) => {
        reject(new Error(`Failed to start pi: ${err.message}`));
      });
      
      this.process.on('exit', (code) => {
        this.process = null;
        resolve(code || 0);
      });
    });
  }
  
  /**
   * 停止 Pi
   */
  stop() {
    if (this.process) {
      this.process.kill();
      this.process = null;
    }
  }
  
  /**
   * 获取配置
   */
  getConfig() {
    return this.config;
  }
  
  /**
   * 获取配置值
   */
  getConfigValue(key, defaultValue) {
    return getConfig(this.config, key, defaultValue);
  }
}

/**
 * 快速启动函数
 */
async function launch(userArgs = [], options = {}) {
  const launcher = new PiLauncher(options);
  return launcher.launch(userArgs);
}

/**
 * 创建启动器实例
 */
function createLauncher(options = {}) {
  return new PiLauncher(options);
}

module.exports = {
  PiLauncher,
  launch,
  createLauncher,
};
