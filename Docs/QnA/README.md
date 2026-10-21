# Q&A

Questions about how **Ruby Core · Metal** works, answered from the source. Each
entry is a standalone document named after the question and cites the files and
symbols that implement the behavior, so references survive unrelated edits.

Documents are listed newest first, by the **Last updated** date recorded in each
file. When dates are equal, the most recently added question comes first.

| Question | Last updated | Covers |
| --- | --- | --- |
| [Can this demo break the internet?](can-this-demo-break-the-internet.md) | 2026-10-21 | The post-launch take, what is solid, and the path to a Ruby-scripted renderer |
| [How does the Ruby core supervise the Metal service?](how-the-ruby-core-supervises-the-service.md) | 2026-10-21 | Argument parsing, build cache, spawn, signals, and exit status |
| [How are the window and renderer built?](how-the-window-and-renderer-are-built.md) | 2026-10-21 | `AppDelegate`, `MTKView`, `Renderer`, uniforms, and the draw call |
| [How are the shaders embedded and compiled?](how-the-shaders-are-embedded-and-compiled.md) | 2026-10-21 | `shaderSource`, runtime `makeLibrary`, and struct alignment |

## Adding an entry

1. Name the file after the question, not the date
   (`how-the-ruby-core-supervises-the-service.md`), so links survive re-edits.
2. Start with the question as the `#` heading, then record both a `Recorded` and
   a `Last updated` date in the metadata block, matching the existing entries.
3. Insert the document into the table above in descending date order.
4. Cite code by file and symbol, never by line number, and run `make docs-check`
   before committing. The convention is defined in
   [`AGENTS.md`](../../AGENTS.md#documentation-and-code-references).

To confirm the date to record, use the commit that last touched the file:

```sh
git log -1 --format=%cs -- Docs/QnA/<file>.md
```

The in-file date is authoritative because it survives cloning, where file
modification times do not. The two should agree with the command above.
