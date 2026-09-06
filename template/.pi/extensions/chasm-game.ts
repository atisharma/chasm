/**
 * Chasm Game Tools — auto-save, save tool, and sync command.
 *
 * Auto-save: commits any changed files after every agent turn. The model
 * just needs to write state files — the git commit is automatic.
 *
 * save tool: for the model to checkpoint with a descriptive message.
 * Auto-save uses a generic message; the save tool lets the model be specific.
 *
 * /save command: user-facing, forces a commit with a reminder to persist first.
 * /sync command: user-facing, forces the narrator to re-read state and persist.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

async function gitCommit(cwd: string, message: string): Promise<string> {
    try {
        await execFileAsync("git", ["-C", cwd, "add", "-A"], { timeout: 5000 });
        await execFileAsync("git", ["-C", cwd, "commit", "--quiet", "-m", message], { timeout: 5000 });
        return message;
    } catch (err: any) {
        // git writes "nothing to commit, working tree clean" to stdout (and
        // sometimes "nothing added to commit" to stderr) and exits 1. Check both
        // streams so a no-op save is treated as "no changes", not a failure.
        const output = `${err?.stdout ?? ""}${err?.stderr ?? ""}`;
        if (output.includes("nothing to commit")) {
            return "no changes";
        }
        throw err;
    }
}

export default function (pi: ExtensionAPI) {
    // Track whether the model persisted any state this turn
    let persistedThisTurn = false;
    let turnCount = 0;

    pi.on("turn_start", async () => {
        persistedThisTurn = false;
        turnCount++;
    });

    pi.on("tool_call", async (event) => {
        if (event.toolName === "write" || event.toolName === "edit") {
            persistedThisTurn = true;
            turnCount = 0;
        }
    });

    // --- Nudge if model hasn't persisted state recently ---
    pi.on("agent_end", async (_event, ctx) => {
        // Check every 7 turns whether state was persisted
        if (turnCount % 7 !== 0) return;
        if (persistedThisTurn) return;

        pi.sendUserMessage(
            "You haven't persisted any state recently. Check: has the player moved? " +
            "Did an NPC change? Did time pass? Is the current place file up to date? " +
            "If anything changed, write it to the relevant files now, then continue the story without comment.",
            { deliverAs: "followUp" },
        );
    });
    // --- Auto-save after every agent turn ---
    pi.on("agent_end", async (_event, ctx) => {
        if (!persistedThisTurn) return;
        persistedThisTurn = false;
        const cwd = process.env.PI_MEMORY_DIR || process.cwd();
        try {
            const result = await gitCommit(cwd, "[auto] turn checkpoint");
            if (result !== "no changes") {
                ctx.ui.notify("💾 saved", "info");
            }
        } catch {
            // Silent — don't disrupt the player for a git error
        }
    });

    // --- save tool (LLM calls this for a descriptive commit) ---
    pi.registerTool({
        name: "save",
        label: "save",
        description:
            "Checkpoint game state with a descriptive git commit. " +
            "Auto-save already commits after every turn, so this is optional — " +
            "use it when you want a meaningful commit message for a significant moment. " +
            "BEFORE saving, ensure all changes are persisted to disk: " +
            "update WORLD_STATE.md (player location, time, conditions), " +
            "create any new place/character/item files, " +
            "update existing entity files for changes, " +
            "create event files for significant occurrences.",
        parameters: {
            type: "object",
            properties: {
                message: {
                    type: "string",
                    description: 'Commit message, e.g. "[narrative] Player enters the abandoned lighthouse"',
                },
            },
            required: ["message"],
            additionalProperties: false,
        },
        renderShell: "self",

        async execute(_toolCallId, params, _signal) {
            const cwd = process.env.PI_MEMORY_DIR || process.cwd();
            const result = await gitCommit(cwd, params.message);
            return {
                content: [{ type: "text" as const, text: result === "no changes" ? "Nothing to save." : `Saved: ${params.message}` }],
                details: {},
            };
        },
        renderCall(args, theme, context) {
            // Hidden in the collapsed view; only the caption is shown when expanded (Ctrl+O).
            if (!context?.expanded) return new Text("", 0, 0);
            return new Text(theme.fg("toolTitle", theme.bold("save ")) + theme.fg("dim", args.message.slice(0, 60)), 0, 0);
        },
        renderResult(result, options, theme, context) {
            const text = result.content[0]?.type === "text" ? result.content[0].text : "saved";
            // Errors stay visible; successes are hidden unless expanded.
            if (context?.isError) {
                return new Text(theme.fg("error", text.split("\n")[0] ?? "save failed"), 0, 0);
            }
            if (!options.expanded) return new Text("", 0, 0);
            return new Text(theme.fg("dim", text), 0, 0);
        },
    });

    // --- /save command (user invokes) ---
    pi.registerCommand("save", {
        description: "Save game state (reminds narrator to persist changes first)",
        handler: async (_args, ctx) => {
            const cwd = process.env.PI_MEMORY_DIR || process.cwd();
            try {
                const result = await gitCommit(cwd, "[player] manual save");
                ctx.ui.notify(result === "no changes" ? "Nothing to save." : "💾 saved", "info");
            } catch {
                ctx.ui.notify("Save failed", "error");
            }
            pi.sendUserMessage(
                "The player wants to save. Persist any pending changes to state files now, " +
                "then continue the story without comment.",
                { deliverAs: "steer" },
            );
        },
    });

    // --- /sync command (user invokes to force state re-read) ---
    pi.registerCommand("sync", {
        description: "Force narrator to re-read and persist state (use when things feel stale)",
        handler: async (_args, ctx) => {
            ctx.ui.notify("Syncing state…", "info");
            pi.sendUserMessage(
                "Sync state now: re-read WORLD_STATE.md, your current place file, and your " +
                "character file. If any of these are out of date, update them. If you've made " +
                "changes this turn that aren't persisted, write them now. Then continue the story without comment.",
                { deliverAs: "steer" },
            );
        },
    });
}
