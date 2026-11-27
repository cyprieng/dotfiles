import { useEffect, useMemo, useRef, useSyncExternalStore, type ReactNode } from "react";
import type {
  ExtensionDiffFile,
  ExtensionKeyEvent,
  ExtensionPaneActions,
  ExtensionPaneProps,
  ExtensionPaneTheme,
  HunkExtensionAPI,
} from "hunkdiff/extension";

interface DirRow {
  kind: "dir";
  path: string;
  label: string;
  depth: number;
}

interface FileRow {
  kind: "file";
  path: string;
  label: string;
  depth: number;
  file: ExtensionDiffFile;
  validated: boolean;
}

type Row = DirRow | FileRow;

interface DirNode {
  dirs: Map<string, DirNode>;
  files: ExtensionDiffFile[];
}

// The keyboard mode and the pane live in different React/host contexts, so they
// share state through this store: the pane publishes its rows and actions, the
// mode moves the cursor and triggers navigation.
const store = {
  focused: false,
  cursor: 0,
  collapsed: new Set<string>(),
  rows: [] as Row[],
  allPaths: [] as string[],
  // After a directory folds, the cursor lands on the row below it.
  cursorAfterDir: null as string | null,
  selectedFileId: null as string | null,
  actions: null as ExtensionPaneActions | null,
  // Validated files leave the review stream; keyed by path, with the patch they were validated at.
  validated: new Map<string, ExtensionDiffFile>(),
  version: 0,
  listeners: new Set<() => void>(),
};

function emit() {
  store.version += 1;
  for (const listener of store.listeners) listener();
}

function subscribe(listener: () => void) {
  store.listeners.add(listener);
  return () => store.listeners.delete(listener);
}

function useStoreVersion() {
  return useSyncExternalStore(subscribe, () => store.version);
}

function buildTree(files: readonly ExtensionDiffFile[]): DirNode {
  const root: DirNode = { dirs: new Map(), files: [] };
  for (const file of files) {
    const parts = file.path.split("/");
    let node = root;
    for (const part of parts.slice(0, -1)) {
      let child = node.dirs.get(part);
      if (!child) {
        child = { dirs: new Map(), files: [] };
        node.dirs.set(part, child);
      }
      node = child;
    }
    node.files.push(file);
  }
  return root;
}

const byName = (a: string, b: string) => a.toLowerCase().localeCompare(b.toLowerCase());

function flatten(node: DirNode, prefix: string, depth: number, collapsed: Set<string>, out: Row[]) {
  for (const name of [...node.dirs.keys()].sort(byName)) {
    let child = node.dirs.get(name)!;
    let label = name;
    // Chain single-child directories into one row, like "app/services/inbound_email".
    while (child.files.length === 0 && child.dirs.size === 1) {
      const [nextName, nextChild] = [...child.dirs.entries()][0];
      label = `${label}/${nextName}`;
      child = nextChild;
    }
    const path = prefix ? `${prefix}/${label}` : label;
    out.push({ kind: "dir", path, label, depth });
    if (!collapsed.has(path)) flatten(child, path, depth + 1, collapsed, out);
  }
  for (const file of [...node.files].sort((a, b) => byName(a.path, b.path))) {
    out.push({
      kind: "file",
      path: file.path,
      label: file.path.split("/").pop()!,
      depth,
      file,
      validated: store.validated.has(file.path),
    });
  }
}

const ICONS: Record<string, [string, string]> = {
  rb: ["\ue739", "#e78284"],
  erb: ["\ue739", "#e78284"],
  rake: ["\ue739", "#e78284"],
  md: ["\ue73e", "#8caaee"],
  mdx: ["\ue73e", "#8caaee"],
  yml: ["\ue615", "#ca9ee6"],
  yaml: ["\ue615", "#ca9ee6"],
  json: ["\ue60b", "#e5c890"],
  toml: ["\ue615", "#ef9f76"],
  ts: ["\ue628", "#8caaee"],
  tsx: ["\ue7ba", "#85c1dc"],
  js: ["\ue74e", "#e5c890"],
  jsx: ["\ue7ba", "#85c1dc"],
  mjs: ["\ue74e", "#e5c890"],
  vue: ["\ue6a0", "#a6d189"],
  lua: ["\ue620", "#8caaee"],
  sh: ["\ue795", "#a6d189"],
  zsh: ["\ue795", "#a6d189"],
  py: ["\ue73c", "#e5c890"],
  go: ["\ue627", "#85c1dc"],
  rs: ["\ue7a8", "#ef9f76"],
  html: ["\ue736", "#ef9f76"],
  css: ["\ue749", "#8caaee"],
  scss: ["\ue603", "#f4b8e4"],
  sql: ["\ue706", "#e5c890"],
  lock: ["\uf023", "#737994"],
  tf: ["\ue615", "#ca9ee6"],
  svg: ["\uf1c5", "#e5c890"],
  png: ["\uf1c5", "#ca9ee6"],
  jpg: ["\uf1c5", "#ca9ee6"],
  txt: ["\uf15c", "#c6d0f5"],
};

const NAMED_ICONS: Record<string, [string, string]> = {
  Gemfile: ["\ue739", "#e78284"],
  Rakefile: ["\ue739", "#e78284"],
  Dockerfile: ["\uf308", "#8caaee"],
  Makefile: ["\ue615", "#ef9f76"],
  ".gitignore": ["\ue702", "#ef9f76"],
};

function fileIcon(name: string): [string, string] {
  if (NAMED_ICONS[name]) return NAMED_ICONS[name];
  const ext = name.includes(".") ? name.split(".").pop()!.toLowerCase() : "";
  return ICONS[ext] ?? ["\uf15b", "#c6d0f5"];
}

function statusOf(file: ExtensionDiffFile, theme: ExtensionPaneTheme): [string, string] {
  if (file.isUntracked) return ["?", theme.fileUntracked];
  switch (file.changeType) {
    case "new":
      return ["A", theme.fileNew];
    case "deleted":
      return ["D", theme.fileDeleted];
    case "rename-pure":
    case "rename-changed":
      return ["R", theme.fileRenamed];
    default:
      return ["M", theme.fileModified];
  }
}

function fit(text: string, width: number) {
  if (width <= 0) return "";
  return text.length <= width ? text : `${text.slice(0, Math.max(0, width - 1))}…`;
}

function ancestorDirs(path: string) {
  const parts = path.split("/");
  return parts.slice(0, -1).map((_, index) => parts.slice(0, index + 1).join("/"));
}

function cursorOnSelectedFile() {
  const index = store.rows.findIndex(
    (row) => row.kind === "file" && !row.validated && row.file.id === store.selectedFileId,
  );
  if (index >= 0) store.cursor = index;
}

function ExplorerPane({ files, selectedFileId, theme, width, actions }: ExtensionPaneProps): ReactNode {
  useStoreVersion();
  const scrollRef = useRef<any>(null);
  store.actions = actions;

  const validatedCount = store.validated.size;
  const tree = useMemo(
    () => buildTree([...files.filter((file) => !store.validated.has(file.path)), ...store.validated.values()]),
    [files, validatedCount],
  );
  store.allPaths = [...files.map((file) => file.path), ...store.validated.keys()];
  const rows: Row[] = [];
  flatten(tree, "", 0, store.collapsed, rows);
  store.rows = rows;
  if (store.cursorAfterDir !== null) {
    const dir = rows.findIndex((row) => row.kind === "dir" && row.path === store.cursorAfterDir);
    if (dir >= 0) store.cursor = Math.min(dir + 1, rows.length - 1);
    store.cursorAfterDir = null;
  }
  store.cursor = Math.min(store.cursor, Math.max(0, rows.length - 1));

  // Keep the file shown in the diff visible: expand its directories and, unless
  // the user is driving the explorer, move the cursor onto it.
  useEffect(() => {
    if (store.selectedFileId === selectedFileId) return;
    store.selectedFileId = selectedFileId;
    const selected = files.find((file) => file.id === selectedFileId);
    if (!selected) return;
    let expanded = false;
    for (const dir of [...store.collapsed]) {
      if (ancestorDirs(selected.path).some((ancestor) => ancestor === dir || ancestor.startsWith(`${dir}/`))) {
        store.collapsed.delete(dir);
        expanded = true;
      }
    }
    if (!store.focused) {
      if (expanded) {
        const next: Row[] = [];
        flatten(tree, "", 0, store.collapsed, next);
        store.rows = next;
      }
      cursorOnSelectedFile();
    }
    emit();
  }, [files, selectedFileId, tree]);

  useEffect(() => {
    const box = scrollRef.current;
    const viewport = box?.viewport?.height ?? 0;
    if (!box || viewport <= 0) return;
    const top = box.scrollTop ?? 0;
    if (store.cursor < top) box.scrollTo(store.cursor);
    else if (store.cursor >= top + viewport) box.scrollTo(store.cursor - viewport + 1);
  });

  const textWidth = Math.max(8, width - 1);

  return (
    <scrollbox
      ref={scrollRef}
      width="100%"
      height="100%"
      focused={false}
      scrollY={true}
      rootOptions={{ backgroundColor: theme.panel }}
      wrapperOptions={{ backgroundColor: theme.panel }}
      viewportOptions={{ backgroundColor: theme.panel }}
      contentOptions={{ backgroundColor: theme.panel }}
      verticalScrollbarOptions={{ visible: false }}
      horizontalScrollbarOptions={{ visible: false }}
    >
      {rows.map((row, index) => {
        const isCursor = store.focused && index === store.cursor;
        const isSelected = row.kind === "file" && !row.validated && row.file.id === selectedFileId;
        const bg = isCursor ? theme.accentMuted : isSelected ? theme.panelAlt : theme.panel;
        const indent = " ".repeat(row.depth * 2);

        if (row.kind === "dir") {
          const open = !store.collapsed.has(row.path);
          const head = ` ${indent}x x `;
          return (
            <box
              key={`d:${row.path}`}
              style={{ width: "100%", height: 1, flexDirection: "row", backgroundColor: bg }}
              onMouseUp={() => {
                if (open) store.collapsed.add(row.path);
                else store.collapsed.delete(row.path);
                store.cursor = index;
                emit();
              }}
            >
              <text fg={theme.muted} bg={bg}>{` ${indent}${open ? "\u2304" : "\u203a"} `}</text>
              <text fg="#8caaee" bg={bg}>{`${open ? "\uf07c" : "\uf07b"} `}</text>
              <text fg={dirValidated(row.path) ? theme.muted : theme.text} bg={bg}>
                {fit(row.label, textWidth - head.length - 1)}
              </text>
            </box>
          );
        }

        const [icon, iconColor] = row.validated ? ["\uf00c", theme.badgeAdded] : fileIcon(row.label);
        const [status, statusColor] = row.validated ? [" ", theme.muted] : statusOf(row.file, theme);
        // A narrow pane drops the +/- counts so file names stay readable.
        const showStats = textWidth >= 34;
        const stats = showStats ? `+${row.file.stats.additions} -${row.file.stats.deletions}` : "";
        const nameWidth = textWidth - indent.length - 5 - stats.length - 3;
        return (
          <box
            key={`f:${row.path}`}
            style={{ width: "100%", height: 1, flexDirection: "row", backgroundColor: bg }}
            onMouseUp={() => {
              store.cursor = index;
              if (!row.validated) actions.selectFile(row.file.id);
              emit();
            }}
          >
            <text fg={isSelected ? theme.accent : bg} bg={bg}>{isSelected ? "▌" : " "}</text>
            <text bg={bg}>{`${indent}  `}</text>
            <text fg={iconColor} bg={bg}>{`${icon} `}</text>
            <text fg={isSelected ? theme.text : statusColor} bg={bg}>
              {fit(row.label, nameWidth).padEnd(Math.max(0, nameWidth))}
            </text>
            <box style={{ flexGrow: 1, height: 1, backgroundColor: bg }} />
            {showStats && (
              <text fg={row.validated ? theme.muted : theme.badgeAdded} bg={bg}>{`+${row.file.stats.additions}`}</text>
            )}
            {showStats && (
              <text fg={row.validated ? theme.muted : theme.badgeRemoved} bg={bg}>{` -${row.file.stats.deletions}`}</text>
            )}
            <text fg={statusColor} bg={bg}>{` ${status} `}</text>
          </box>
        );
      })}
    </scrollbox>
  );
}

let reload = () => {};

function dirValidated(dir: string) {
  const inside = store.allPaths.filter((path) => path.startsWith(`${dir}/`));
  return inside.length > 0 && inside.every((path) => store.validated.has(path));
}

// Fold the outermost directory that the validation of `paths` just completed.
function foldValidatedDirs(paths: string[]) {
  const done = store.rows.find(
    (row) => row.kind === "dir" && paths.some((path) => path.startsWith(`${row.path}/`)) && dirValidated(row.path),
  );
  if (!done) return false;
  store.collapsed.add(done.path);
  store.cursorAfterDir = done.path;
  return true;
}

function toggleValidated(paths: string[]) {
  const unvalidate = paths.every((path) => store.validated.has(path));
  for (const path of paths) {
    if (unvalidate) {
      store.validated.delete(path);
      continue;
    }
    const row = store.rows.find((candidate) => candidate.kind === "file" && candidate.path === path);
    if (row?.kind === "file") store.validated.set(path, row.file);
  }
  const folded = !unvalidate && foldValidatedDirs(paths);
  emit();
  reload();
  return folded;
}

function moveCursor(delta: number) {
  store.cursor = Math.max(0, Math.min(store.rows.length - 1, store.cursor + delta));
  emit();
}

function handleKey(key: ExtensionKeyEvent): "handled" | "pass" | "exit" {
  const row = store.rows[store.cursor];
  switch (key.name) {
    case "up":
      moveCursor(-1);
      return "handled";
    case "down":
      moveCursor(1);
      return "handled";
    case "pageup":
      moveCursor(-10);
      return "handled";
    case "pagedown":
      moveCursor(10);
      return "handled";
    case "home":
      moveCursor(-store.rows.length);
      return "handled";
    case "end":
      moveCursor(store.rows.length);
      return "handled";
    case "right":
      if (row?.kind === "dir" && store.collapsed.has(row.path)) {
        store.collapsed.delete(row.path);
        emit();
      } else if (row?.kind === "dir") {
        moveCursor(1);
      }
      return "handled";
    case "left": {
      if (row?.kind === "dir" && !store.collapsed.has(row.path)) {
        store.collapsed.add(row.path);
        emit();
        return "handled";
      }
      const parent = store.rows.findLastIndex(
        (candidate, index) => index < store.cursor && candidate.kind === "dir" && candidate.depth < (row?.depth ?? 0),
      );
      if (parent >= 0) {
        store.cursor = parent;
        emit();
      }
      return "handled";
    }
    case "return":
    case "enter":
      if (row?.kind === "dir") {
        if (store.collapsed.has(row.path)) store.collapsed.delete(row.path);
        else store.collapsed.add(row.path);
        emit();
        return "handled";
      }
      if (row?.kind === "file" && !row.validated) {
        store.actions?.selectFile(row.file.id);
        return "exit";
      }
      return "handled";
    case "space": {
      if (row?.kind === "file") {
        if (!toggleValidated([row.path])) moveCursor(1);
      } else if (row?.kind === "dir") {
        const wasValidated = dirValidated(row.path);
        toggleValidated(store.allPaths.filter((path) => path.startsWith(`${row.path}/`)));
        if (wasValidated) {
          store.collapsed.delete(row.path);
          emit();
        }
      }
      return "handled";
    }
    case "tab":
      return "exit";
    default:
      return "pass";
  }
}

export default function (hunk: HunkExtensionAPI) {
  reload = () => hunk.events.emit("explorer:reload", {});
  hunk.events.on("explorer:reload", async (_payload, ctx) => {
    await ctx.review.requestReload();
  });

  // Validated files leave the stream until their diff changes again.
  hunk.transformChangeset((changeset) => {
    const present = new Set(changeset.files.map((file) => file.path));
    for (const path of [...store.validated.keys()]) {
      if (!present.has(path)) store.validated.delete(path);
    }
    const files = changeset.files.filter((file) => {
      const validated = store.validated.get(file.path);
      if (!validated) return true;
      if (validated.patch !== file.patch) {
        store.validated.delete(file.path);
        return true;
      }
      store.validated.set(file.path, file);
      return false;
    });
    emit();
    return { ...changeset, files };
  });

  // The review stream (and `,`/`.`) follows the explorer's order instead of Git's.
  hunk.transformChangeset((changeset) => {
    const ordered: Row[] = [];
    flatten(buildTree(changeset.files), "", 0, new Set(), ordered);
    const rank = new Map(
      ordered.flatMap((row) => (row.kind === "file" ? [row.file.id] : [])).map((id, index) => [id, index]),
    );
    return {
      ...changeset,
      files: [...changeset.files].sort((a, b) => (rank.get(a.id) ?? 0) - (rank.get(b.id) ?? 0)),
    };
  });

  hunk.registerPane({
    id: "files",
    title: "Explorer",
    placement: "left",
    replaces: "hunk:files",
    width: { preferred: 40, min: 20, max: 70, fraction: 0.2 },
    component: ExplorerPane,
  });

  hunk.registerKeyboardMode({
    id: "focus",
    title: "Explorer",
    onEnter() {
      store.focused = true;
      cursorOnSelectedFile();
      emit();
    },
    onExit() {
      store.focused = false;
      emit();
    },
    onKey: handleKey,
  });

  hunk.registerCommand({ id: "validate", title: "Validate the current file", key: "V" }, (ctx) => {
    const file = ctx.selection.file;
    if (!file) return;
    store.validated.set(file.path, file);
    foldValidatedDirs([file.path]);
    emit();
    reload();
  });

  hunk.registerCommand({ id: "focus", title: "Focus the explorer" }, (ctx) => {
    if (ctx.keyboardModes.isActive("focus")) ctx.keyboardModes.exitMode();
    else ctx.keyboardModes.enterMode("focus");
  });
}
