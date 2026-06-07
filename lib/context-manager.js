/**
 * glm-tui 上下文管理模块
 * 
 * 管理长上下文，支持：
 * - 200K context window（GLM-5.1）
 * - Thinking 块保留
 * - 智能压缩策略
 * - 上下文统计
 */

const fs = require('fs');
const path = require('path');

/**
 * 上下文管理器类
 */
class ContextManager {
  constructor(options = {}) {
    this.options = {
      maxTokens: options.maxTokens || 200000,
      compactionThreshold: options.compactionThreshold || 0.8,
      preserveThinking: options.preserveThinking !== false,
      ...options,
    };
    
    this.stats = {
      totalTokens: 0,
      compactionCount: 0,
      thinkingBlocksPreserved: 0,
      messagesProcessed: 0,
    };
    
    this.history = [];
  }
  
  /**
   * 估算 token 数量
   * 
   * 注意：这是一个简化的估算，实际 token 数取决于分词器
   * 对于 GLM-5.1，使用约 4 字符/token 的估算
   */
  estimateTokens(text) {
    if (!text) return 0;
    
    // 简化估算：英文约 4 字符/token，中文约 2 字符/token
    const englishChars = (text.match(/[a-zA-Z]/g) || []).length;
    const chineseChars = (text.match(/[\u4e00-\u9fff]/g) || []).length;
    const otherChars = text.length - englishChars - chineseChars;
    
    return Math.ceil(
      (englishChars / 4) + 
      (chineseChars / 2) + 
      (otherChars / 4)
    );
  }
  
  /**
   * 检查是否需要压缩
   */
  needsCompaction(messages) {
    const totalTokens = this.calculateTotalTokens(messages);
    const threshold = this.options.maxTokens * this.options.compactionThreshold;
    
    return totalTokens > threshold;
  }
  
  /**
   * 计算总 token 数
   */
  calculateTotalTokens(messages) {
    let total = 0;
    
    for (const message of messages) {
      if (message.content) {
        total += this.estimateTokens(message.content);
      }
      
      // 计算工具调用的 token
      if (message.toolCalls) {
        for (const toolCall of message.toolCalls) {
          total += this.estimateTokens(JSON.stringify(toolCall));
        }
      }
      
      // 计算工具结果的 token
      if (message.toolResults) {
        for (const toolResult of message.toolResults) {
          total += this.estimateTokens(toolResult.content);
        }
      }
    }
    
    return total;
  }
  
  /**
   * 提取 thinking 块
   */
  extractThinkingBlocks(content) {
    if (!content || !this.options.preserveThinking) {
      return { thinking: [], content };
    }
    
    const thinkingRegex = /<think>([\s\S]*?)<\/think>/g;
    const thinking = [];
    let match;
    
    while ((match = thinkingRegex.exec(content)) !== null) {
      thinking.push(match[1].trim());
    }
    
    // 移除 thinking 块，保留其他内容
    const cleanContent = content.replace(thinkingRegex, '').trim();
    
    return { thinking, content: cleanContent };
  }
  
  /**
   * 压缩消息历史
   * 
   * 策略：
   * 1. 保留最近的消息
   * 2. 保留 thinking 块
   * 3. 压缩旧消息为摘要
   */
  compactMessages(messages, targetTokens = null) {
    if (!messages || messages.length === 0) {
      return messages;
    }
    
    const target = targetTokens || (this.options.maxTokens * 0.5);
    const result = [];
    let currentTokens = 0;
    
    // 从最新消息开始，保留尽可能多的消息
    for (let i = messages.length - 1; i >= 0; i--) {
      const message = messages[i];
      const messageTokens = this.estimateTokens(message.content || '');
      
      if (currentTokens + messageTokens > target) {
        // 超出目标，停止添加
        break;
      }
      
      result.unshift(message);
      currentTokens += messageTokens;
    }
    
    // 如果压缩了消息，添加压缩摘要
    if (result.length < messages.length) {
      const compactedCount = messages.length - result.length;
      const summary = this.createCompactionSummary(messages.slice(0, compactedCount));
      
      result.unshift({
        role: 'system',
        content: `[Context Compaction] ${compactedCount} messages were compacted to preserve context window.\n\nSummary:\n${summary}`,
      });
      
      this.stats.compactionCount++;
    }
    
    return result;
  }
  
  /**
   * 创建压缩摘要
   */
  createCompactionSummary(messages) {
    const summary = [];
    
    for (const message of messages) {
      if (message.role === 'user') {
        // 提取用户消息的关键信息
        const content = message.content || '';
        const preview = content.substring(0, 100) + (content.length > 100 ? '...' : '');
        summary.push(`- User: ${preview}`);
      } else if (message.role === 'assistant') {
        // 提取助手消息的关键信息
        const content = message.content || '';
        const preview = content.substring(0, 100) + (content.length > 100 ? '...' : '');
        summary.push(`- Assistant: ${preview}`);
      } else if (message.role === 'tool') {
        // 工具调用结果
        summary.push(`- Tool: ${message.name || 'unknown'}`);
      }
    }
    
    return summary.join('\n');
  }
  
  /**
   * 处理新消息
   */
  processMessage(message) {
    this.stats.messagesProcessed++;
    
    // 提取 thinking 块
    if (message.content && this.options.preserveThinking) {
      const { thinking, content } = this.extractThinkingBlocks(message.content);
      
      if (thinking.length > 0) {
        this.stats.thinkingBlocksPreserved += thinking.length;
        
        // 将 thinking 块存储到历史
        this.history.push({
          type: 'thinking',
          blocks: thinking,
          timestamp: Date.now(),
        });
      }
      
      message.content = content;
    }
    
    // 估算 token 数量
    const tokens = this.estimateTokens(message.content || '');
    this.stats.totalTokens += tokens;
    
    return message;
  }
  
  /**
   * 获取统计信息
   */
  getStats() {
    return {
      ...this.stats,
      averageTokensPerMessage: this.stats.messagesProcessed > 0 
        ? Math.round(this.stats.totalTokens / this.stats.messagesProcessed)
        : 0,
      contextUsage: this.stats.totalTokens / this.options.maxTokens,
    };
  }
  
  /**
   * 重置统计信息
   */
  resetStats() {
    this.stats = {
      totalTokens: 0,
      compactionCount: 0,
      thinkingBlocksPreserved: 0,
      messagesProcessed: 0,
    };
  }
  
  /**
   * 获取 thinking 历史
   */
  getThinkingHistory() {
    return this.history.filter(h => h.type === 'thinking');
  }
  
  /**
   * 清除 thinking 历史
   */
  clearThinkingHistory() {
    this.history = this.history.filter(h => h.type !== 'thinking');
  }
}

/**
 * 创建上下文管理器实例
 */
function createContextManager(options = {}) {
  return new ContextManager(options);
}

/**
 * 快速检查是否需要压缩
 */
function checkCompactionNeeded(messages, maxTokens = 200000, threshold = 0.8) {
  const manager = new ContextManager({ maxTokens, compactionThreshold: threshold });
  return manager.needsCompaction(messages);
}

module.exports = {
  ContextManager,
  createContextManager,
  checkCompactionNeeded,
};
