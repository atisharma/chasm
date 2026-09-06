/**
 * Chasm Tools — machinery-invisible rendering for the built-in file tools.
 *
 * Replaces the built-in read, write, edit, and bash tools with versions that
 * delegate execution to the originals (via createReadTool/createWriteTool/
 * createEditTool/createBashTool) but render nothing in the default (collapsed)
 * transcript view. The player sees only narrative prose; tool activity is
 * revealed on demand with Ctrl+O (expanded), which shows the call caption and
 * the full output.
 *
 * Errors are never hidden: a failed tool renders in the transcript even when
 * collapsed, so the player is not left staring at silent breakage. Partial
 * ("running…") frames render nothing, so a turn does not flicker between tool
 * states.
 *
 * The model still receives full content, diffs, and success confirmations.
 *
 * renderShell "self" is required: it skips the built-in padded tool box, so a
 * tool whose renderers produce zero lines renders nothing at all.
 */

import type { BashToolDetails, EditToolDetails, ExtensionAPI, ReadToolDetails } from "@earendil-works/pi-coding-agent";
import { createBashTool, createEditTool, createReadTool, createWriteTool } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

/** A component that renders zero lines. With renderShell "self" the tool row disappears. */
function hidden(): Text {
    return new Text("", 0, 0);
}

/** First text content block of a tool result, split into lines. */
function textLines(result: { content: { type: string; text?: string }[] }): string[] {
    const block = result.content.find((c) => c.type === "text");
    if (!block || block.type !== "text" || !block.text) return [];
    return block.text.split("\n");
}

/** Whether a result is an error: flagged by the runtime, or textually prefixed. */
function isErrorResult(result: { content: { type: string; text?: string }[] }, context: { isError?: boolean } | undefined): boolean {
    if (context?.isError) return true;
    const first = textLines(result)[0] ?? "";
    return first.startsWith("Error");
}

export default function (pi: ExtensionAPI) {
    const cwd = process.cwd();

    // --- Bash tool: nothing unless error or expanded ---
    const originalBash = createBashTool(cwd);
    pi.registerTool({
        name: "bash",
        label: "bash",
        description: originalBash.description,
        parameters: originalBash.parameters,
        renderShell: "self",

        async execute(toolCallId, params, signal, onUpdate) {
            return originalBash.execute(toolCallId, params, signal, onUpdate);
        },

        renderCall(args, theme, context) {
            if (!context?.expanded) return hidden();
            let text = theme.fg("toolTitle", theme.bold("$ "));
            const cmd = args.command.length > 80 ? `${args.command.slice(0, 77)}...` : args.command;
            text += theme.fg("muted", cmd);
            return new Text(text, 0, 0);
        },

        renderResult(result, { expanded, isPartial }, theme, context) {
            if (isPartial) return hidden();

            const lines = textLines(result);
            const output = lines.join("\n");

            // Bash reports failure by throwing; the message is
            // "…output…\n\nCommand exited with code N" (or aborted/timeout),
            // where "(no output)" is a placeholder, never real content.
            const statusMatch = output.match(/Command (exited with code (\d+)|aborted|timed out)/);
            if (context?.isError || statusMatch) {
                let status: string;
                if (statusMatch) {
                    if (statusMatch[2]) status = `exit ${statusMatch[2]}`;
                    else if (output.includes("aborted")) status = "aborted";
                    else status = "timed out";
                } else {
                    status = "failed";
                }
                const firstLine = lines.find((l: string) => l.trim() && !l.startsWith("Command ") && l !== "(no output)") ?? "";
                let text = theme.fg("error", status);
                if (firstLine) text += theme.fg("dim", ` - ${firstLine.slice(0, 120)}`);
                return new Text(text, 0, 0);
            }

            if (!expanded) return hidden();

            // Expanded view: raw output minus empties and the no-output placeholder.
            const significant = lines.filter((l: string) => l.trim());
            const cleaned = significant.filter((l: string) => l !== "(no output)");
            const body = cleaned.slice(0, 20).map((l: string) => theme.fg("dim", l));
            if (significant.length > 20) body.push(theme.fg("dim", `… ${significant.length - 20} more`));
            return new Text(body.length ? body.join("\n") : theme.fg("dim", "no output"), 0, 0);
        },
    });

    // --- Read tool ---
    const originalRead = createReadTool(cwd);
    pi.registerTool({
        name: "read",
        label: "read",
        description: originalRead.description,
        parameters: originalRead.parameters,
        renderShell: "self",

        async execute(toolCallId, params, signal, onUpdate) {
            return originalRead.execute(toolCallId, params, signal, onUpdate);
        },

        renderCall(args, theme, context) {
            if (!context?.expanded) return hidden();
            let text = theme.fg("toolTitle", theme.bold("read "));
            text += theme.fg("muted", args.path);
            if (args.offset || args.limit) {
                const parts: string[] = [];
                if (args.offset) parts.push(`offset=${args.offset}`);
                if (args.limit) parts.push(`limit=${args.limit}`);
                text += theme.fg("dim", ` (${parts.join(", ")})`);
            }
            return new Text(text, 0, 0);
        },

        renderResult(result, { expanded, isPartial }, theme, context) {
            if (isPartial) return hidden();

            const details = result.details as ReadToolDetails | undefined;
            const content = result.content[0];

            if (content?.type === "image") {
                return expanded ? new Text(theme.fg("dim", "image loaded"), 0, 0) : hidden();
            }

            if (content?.type !== "text") {
                return expanded ? new Text(theme.fg("dim", "(no text output)"), 0, 0) : hidden();
            }

            const lines = content.text.split("\n");

            // Errors are always visible, even collapsed.
            if (isErrorResult(result, context)) {
                return new Text(theme.fg("error", lines[0] ?? "read failed"), 0, 0);
            }

            if (!expanded) return hidden();

            const body: string[] = [];
            let text = theme.fg("dim", `${lines.length} lines`);
            if (details?.truncation?.truncated) {
                text += theme.fg("dim", ` of ${details.truncation.totalLines}`);
            }
            body.push(text);
            for (const line of lines.slice(0, 20)) {
                body.push(theme.fg("dim", line));
            }
            if (lines.length > 20) {
                body.push(theme.fg("dim", `… ${lines.length - 20} more`));
            }
            return new Text(body.join("\n"), 0, 0);
        },
    });

    // --- Write tool ---
    const originalWrite = createWriteTool(cwd);
    pi.registerTool({
        name: "write",
        label: "write",
        description: originalWrite.description,
        parameters: originalWrite.parameters,
        renderShell: "self",

        async execute(toolCallId, params, signal, onUpdate) {
            return originalWrite.execute(toolCallId, params, signal, onUpdate);
        },

        renderCall(args, theme, context) {
            if (!context?.expanded) return hidden();
            let text = theme.fg("toolTitle", theme.bold("write "));
            text += theme.fg("muted", args.path);
            const lineCount = args.content.split("\n").length;
            text += theme.fg("dim", ` (${lineCount} lines)`);
            return new Text(text, 0, 0);
        },

        renderResult(result, { expanded, isPartial }, theme, context) {
            if (isPartial) return hidden();

            const lines = textLines(result);
            if (isErrorResult(result, context)) {
                return new Text(theme.fg("error", lines[0] ?? "write failed"), 0, 0);
            }

            if (!expanded) return hidden();

            const body: string[] = [];
            for (const line of lines.slice(0, 20)) {
                body.push(theme.fg("dim", line));
            }
            return new Text(body.length ? body.join("\n") : "written", 0, 0);
        },
    });

    // --- Edit tool ---
    const originalEdit = createEditTool(cwd);
    pi.registerTool({
        name: "edit",
        label: "edit",
        description: originalEdit.description,
        parameters: originalEdit.parameters,
        renderShell: "self",

        async execute(toolCallId, params, signal, onUpdate) {
            return originalEdit.execute(toolCallId, params, signal, onUpdate);
        },

        renderCall(args, theme, context) {
            if (!context?.expanded) return hidden();
            let text = theme.fg("toolTitle", theme.bold("edit "));
            text += theme.fg("muted", args.path);
            return new Text(text, 0, 0);
        },

        renderResult(result, { expanded, isPartial }, theme, context) {
            if (isPartial) return hidden();

            const lines = textLines(result);
            if (isErrorResult(result, context)) {
                return new Text(theme.fg("error", lines[0] ?? "edit failed"), 0, 0);
            }

            if (!expanded) return hidden();

            const details = result.details as EditToolDetails | undefined;
            if (!details?.diff) {
                return new Text(theme.fg("dim", "applied"), 0, 0);
            }

            // Colour the diff lines.
            const diffLines = details.diff.split("\n");
            let additions = 0;
            let removals = 0;
            for (const line of diffLines) {
                if (line.startsWith("+") && !line.startsWith("+++")) additions++;
                if (line.startsWith("-") && !line.startsWith("---")) removals++;
            }

            const body: string[] = [theme.fg("dim", `+${additions}/-${removals}`)];
            for (const line of diffLines.slice(0, 30)) {
                if (line.startsWith("+") && !line.startsWith("+++")) {
                    body.push(theme.fg("success", line));
                } else if (line.startsWith("-") && !line.startsWith("---")) {
                    body.push(theme.fg("error", line));
                } else {
                    body.push(theme.fg("dim", line));
                }
            }
            if (diffLines.length > 30) {
                body.push(theme.fg("dim", `… ${diffLines.length - 30} more`));
            }
            return new Text(body.join("\n"), 0, 0);
        },
    });
}
