/**
 * Search Before Write Extension
 *
 * 强制 agent 在 write/edit 前先调用 mcp search 检索
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function searchBeforeWrite(pi: ExtensionAPI): void {
  let lastSearchTime = 0;
  const SEARCH_COOLDOWN = 60_000; // 60s 内有效

  // 追踪 mcp 调用
  pi.on("tool_call", async (event) => {
    if (event.toolName === "mcp") {
      const args = event.input as { tool?: string; search?: string };
      if (args.tool?.includes("search") || args.search) {
        lastSearchTime = Date.now();
      }
    }
  });

  // 拦截 write/edit
  pi.on("tool_call", async (event) => {
    if (event.toolName !== "write" && event.toolName !== "edit") return;

    const elapsed = Date.now() - lastSearchTime;
    if (elapsed > SEARCH_COOLDOWN) {
      return {
        block: true,
        reason: `[Search-Before-Write] 请先用 mcp search 检索是否有类似实现！\n\nmcp({ search: "你要实现的功能关键词" })\n\n确认没有重复代码后再写入。`,
      };
    }
  });
}
