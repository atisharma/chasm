/**
 * Chasm Footer — shows world name, player location, and game state.
 *
 * Line 1: 🎲 World Name • location          model • thinking
 * Line 2: day N · time · weather · ⚔N · ↑in ↓out $cost   context%/window
 *
 * Reads WORLD.md and WORLD_STATE.md from PI_MEMORY_DIR on each render.
 * Falls back to "Chasm" / "unknown" if files are missing or uninitialised.
 */

import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import * as fs from "node:fs";
import * as nodePath from "node:path";

interface WorldState {
    worldName: string;
    location: string;
    day: string;
    timeOfDay: string;
    weather: string;
    playerCondition: string;
    inventoryCount: number;
}

// Resolve the player character file's `location:` field. The character
// pointer may be absolute, relative to the memory dir, quoted, bracketed,
// or a stale absolute path from another machine (e.g. /pi/chasm/memory/...)
// — the last resort re-roots everything after "memory/" onto memDir.
function characterLocation(memDir: string, get: (key: string) => string): string {
    const raw = get("character");
    if (!raw || raw === "null") return "";
    const cleaned = raw.replace(/^["']|["']$/g, "").replace(/\[\[|\]\]/g, "");
    const candidates = [
        cleaned,
        nodePath.join(memDir, cleaned),
        nodePath.join(memDir, cleaned.replace(/^.*?memory\//, "")),
    ];
    for (const p of candidates) {
        try {
            if (p && fs.existsSync(p)) {
                const text = fs.readFileSync(p, "utf-8");
                const match = text.match(/^location:\s*"?(.+?)"?\s*$/m);
                if (match) return match[1];
            }
        } catch {
            // Unreadable candidate — try the next one
        }
    }
    return "";
}

function readWorldState(): WorldState {
    const memDir = process.env.PI_MEMORY_DIR ?? "";
    const defaults: WorldState = {
        worldName: "Chasm",
        location: "unknown",
        day: "1",
        timeOfDay: "",
        weather: "",
        playerCondition: "",
        inventoryCount: 0,
    };

    if (!memDir) return defaults;

    try {
        const worldPath = nodePath.join(memDir, "WORLD.md");
        if (fs.existsSync(worldPath)) {
            const text = fs.readFileSync(worldPath, "utf-8");
            const firstLine = text.split("\n")[0] ?? "";
            const title = firstLine.replace(/^#+\s*/, "").trim();
            if (title && !title.includes("Your World") && !title.includes("TODO")) {
                defaults.worldName = title;
            }
        }

        const statePath = nodePath.join(memDir, "WORLD_STATE.md");
        if (fs.existsSync(statePath)) {
            const text = fs.readFileSync(statePath, "utf-8");
            const get = (key: string): string => {
                const match = text.match(new RegExp(`^-\\s+${key}:\\s*(.+)`, "m"));
                return match ? match[1].trim().replace(/`/g, "").replace(/\s+#.+$/, "") : "";
            };

            const location = get("current_place") || characterLocation(memDir, get) || get("starting_place") || get("location");
            if (location) defaults.location = location.replace(/\[\[|\]\]/g, "");

            const day = get("day");
            if (day) defaults.day = day;

            const timeOfDay = get("time_of_day");
            if (timeOfDay) defaults.timeOfDay = timeOfDay;

            // Weather condition (from ## Weather section, not player)
            const weatherSection = text.match(/## Weather\s*\n([\s\S]*?)(?=## |$)/);
            if (weatherSection) {
                const wMatch = weatherSection[1].match(/^-\s+condition:\s*(.+)/m);
                if (wMatch) defaults.weather = wMatch[1].trim().replace(/`/g, "").replace(/\s+#.+$/, "");
            }

            // Player condition (from ## Player section, not weather)
            const playerSection = text.match(/## Player\s*\n([\s\S]*?)(?=## |$)/);
            if (playerSection) {
                const pcMatch = playerSection[1].match(/^-\s+condition:\s*(.+)/m);
                if (pcMatch) defaults.playerCondition = pcMatch[1].trim().replace(/`/g, "").replace(/\s+#.+$/, "");
            }

            const invMatch = text.match(/inventory:\s*\n((?:\s+-\s+.+\n?)*)/);
            if (invMatch) {
                defaults.inventoryCount = (invMatch[1].match(/^\s+-\s+/gm) || []).length;
            }
        }
    } catch {
        // File read errors — use defaults
    }

    return defaults;
}

export default function (pi: ExtensionAPI) {
    pi.on("session_start", async (_event, ctx) => {
        ctx.ui.setToolsExpanded(false);
        // Hidden thinking blocks render as zero lines instead of one "Thinking..."
        // row per reasoning run (reasoning stays invisible like tool activity).
        // Ctrl+T still reveals it (and new runs honour the toggle).
        ctx.ui.setHiddenThinkingLabel("");
        ctx.ui.setFooter((tui, theme, footerData) => {
            const unsub = footerData.onBranchChange(() => tui.requestRender());

            return {
                dispose: unsub,
                invalidate() {},
                render(width: number): string[] {
                    const state = readWorldState();
                    const model = ctx.model?.id || "no-model";

                    // Token counts from session
                    let input = 0, output = 0, cost = 0;
                    for (const e of ctx.sessionManager.getBranch()) {
                        if (e.type === "message" && e.message.role === "assistant") {
                            const m = e.message as AssistantMessage;
                            input += m.usage.input;
                            output += m.usage.output;
                            cost += m.usage.cost.total;
                        }
                    }
                    const fmt = (n: number) =>
                        n < 1000 ? `${n}` : n < 1000000 ? `${(n / 1000).toFixed(1)}k` : `${(n / 1000000).toFixed(1)}M`;

                    // Context usage
                    const contextUsage = ctx.getContextUsage();
                    const contextWindow = contextUsage?.contextWindow ?? 0;
                    const contextPercent = contextUsage?.percent;
                    const contextFmt = contextPercent !== null && contextPercent !== undefined
                        ? `${contextPercent.toFixed(1)}%/${fmt(contextWindow)}`
                        : `?/${fmt(contextWindow)}`;

                    let contextStr: string;
                    if (contextPercent === null || contextPercent === undefined) {
                        contextStr = contextFmt;
                    } else if (contextPercent > 90) {
                        contextStr = theme.fg("error", contextFmt);
                    } else if (contextPercent > 70) {
                        contextStr = theme.fg("warning", contextFmt);
                    } else {
                        contextStr = contextFmt;
                    }

                    // Line 1: 🎲 World Name • location          model • thinking
                    const dice = "🎲";
                    const leftPlain = `${dice} ${state.worldName}` + (state.location !== "unknown" ? ` • ${state.location}` : "");
                    const leftStr = theme.fg("accent", `${dice} ${state.worldName}`)
                        + (state.location !== "unknown" ? theme.fg("dim", ` • ${state.location}`) : "");

                    let rightPlain = model;
                    if (ctx.model?.reasoning) {
                        const level = pi.getThinkingLevel();
                        rightPlain = level === "off" ? `${model} · no thinking` : `${model} · ${level}`;
                    }
                    const rightStr = theme.fg("dim", rightPlain);

                    const pad1 = Math.max(2, width - visibleWidth(leftPlain) - visibleWidth(rightPlain));
                    const line1 = truncateToWidth(leftStr + " ".repeat(pad1) + rightStr, width);

                    // Line 2: day · time · weather · ⚔N · condition   ↑↓$  context%
                    const stateParts: string[] = [];
                    stateParts.push(`day ${state.day}`);
                    if (state.timeOfDay) stateParts.push(state.timeOfDay);
                    if (state.weather) stateParts.push(state.weather);
                    if (state.inventoryCount > 0) stateParts.push(`⚔${state.inventoryCount}`);

                    if (state.playerCondition && state.playerCondition !== "normal") stateParts.push(state.playerCondition);

                    const statePlain = stateParts.join(" · ");
                    const stateStr = theme.fg("dim", statePlain);

                    // Right side: token stats + context
                    let right2Plain = "";
                    if (input || output) {
                        const tokenParts: string[] = [];
                        if (input) tokenParts.push(`↑${fmt(input)}`);
                        if (output) tokenParts.push(`↓${fmt(output)}`);
                        if (cost) tokenParts.push(`$${cost.toFixed(3)}`);
                        right2Plain = tokenParts.join(" ");
                    }
                    const right2FullPlain = (right2Plain ? right2Plain + "  " : "") + contextFmt;
                    const right2FullStr = (right2Plain ? theme.fg("dim", right2Plain) + "  " : "") + contextStr;

                    // Ellipsize left if it encroaches on right
                    const right2Width = visibleWidth(right2FullPlain);
                    const left2Budget = width - right2Width - 2; // 2 for minimum padding
                    const left2Plain = statePlain.length > left2Budget
                        ? statePlain.slice(0, Math.max(0, left2Budget - 1)) + "…"
                        : statePlain;
                    const left2Str = theme.fg("dim", left2Plain);

                    const pad2 = Math.max(2, width - visibleWidth(left2Plain) - right2Width);
                    const line2 = truncateToWidth(left2Str + " ".repeat(pad2) + right2FullStr, width);

                    return [line1, line2];
                },
            };
        });
    });
}
