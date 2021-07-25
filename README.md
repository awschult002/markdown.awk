# A markdown-to-html in pure awk

This awk script reads markdown files and generates html from them.
Compared to other implementations of markdown in awk, it tries to do the right thing most of the time.

You can use `markdown.awk` to generate html pages from your plaintext notes, or send html emails with mutt.

**This is a work in progress**

## Usage

You can try it out by converting this readme to html:

```
awk -f markdown.awk README.md
```

## Features

Here's a list of supported markdown primitives

- Headers
- Paragraphs
- Text formatting: bold
- Code blocks
- Blockquotes
- Lists, both bulleted and numbered
- Inline html (partial)

## License

Distributed under the terms of the BSD License

