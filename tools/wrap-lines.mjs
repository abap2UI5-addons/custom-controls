// Breaks JavaScript and CSS into lines short enough for a BSP page, without
// changing what the file means.
//
// Why this exists
// ---------------
// A BSP page is stored on the SAP system as a table of 255-character lines
// (see tools/app2bsp.mjs). A source line longer than that has to be chopped
// somewhere, and neither abapGit nor the O2 page API knows where a JavaScript
// token ends - the cut lands wherever character 256 happens to be, which for a
// minified bundle is in the middle of an identifier or a string literal. The
// file that comes back out of the system is then no longer the file that went
// in.
//
// Reformatting the libraries with Prettier is not a fix: Prettier never breaks
// a string literal, and the vendored bundles contain single strings far longer
// than 255 characters (bwip-js carries the whole BWIPP program that way, in one
// ~19,000-character literal). It also rewrites every line of upstream code,
// which makes "is this really chart.js 4.4.1?" impossible to answer from the
// diff.
//
// So the libraries are vendored byte-for-byte and only *wrapped* here: newlines
// are inserted, nothing else is touched.
//
// Why the inserted newlines are safe
// ----------------------------------
// If `A B` parses, then `A<LF>B` parses the same way - automatic semicolon
// insertion fires only where the parser hits an error, and there is none. The
// exceptions are the grammar's restricted productions, which forbid a line
// terminator outright: after `return`, `throw`, `break`, `continue`, `yield`,
// before a postfix `++`/`--`, before `=>`, and inside `async function`. A break
// is therefore only taken directly after one of SAFE_AFTER - `,` `;` `{` `}`
// `(` `[` `:` - none of which is one of those sites, and all of which are
// plentiful in minified code.
//
// Two things must additionally be kept out of:
//
//   template literals   the text between the backticks is content. A newline
//                       added after the `}` that closes a `${...}` lands inside
//                       the string and shows up in the output.
//   directives          `"use strict"` only takes effect when it is written
//                       without escape sequences, so a short string is never
//                       split - only one that cannot fit on a line at all.
//
// A string that has to be split is continued with a backslash before the
// newline: "ab\<LF>cd" is exactly "abcd" per the spec, in JavaScript and in
// CSS alike. The split point never lands inside an escape sequence or between
// the halves of a surrogate pair.
//
// Regular expressions, template literals and comments are never split - a
// newline there is content, not layout. A line that is still too long after
// wrapping is reported (`overlongLines`) rather than silently shipped.
import { tokenizer, tokTypes } from "acorn";

// The width the wrapper aims for. Below the 255 the BSP page format imposes,
// so a continuation backslash and an odd multi-byte character still fit;
// app2bsp asserts the hard limit again on the generated pages.
export const DEFAULT_MAX = 240;

// Token types after which a newline can never change the parse: punctuation
// that leaves a statement unfinished, and every binary or assignment operator,
// which needs its right-hand side on either side of a line break.
const SAFE_AFTER = new Set([
  tokTypes.comma,
  tokTypes.semi,
  tokTypes.braceL,
  tokTypes.braceR,
  tokTypes.parenL,
  tokTypes.parenR,
  tokTypes.bracketL,
  tokTypes.bracketR,
  tokTypes.colon,
  tokTypes.dot,
  tokTypes.question,
  tokTypes.arrow,
  tokTypes.eq,
  tokTypes.assign,
  tokTypes.logicalOR,
  tokTypes.logicalAND,
  tokTypes.coalesce,
  tokTypes.bitwiseOR,
  tokTypes.bitwiseXOR,
  tokTypes.bitwiseAND,
  tokTypes.equality,
  tokTypes.relational,
  tokTypes.bitShift,
  tokTypes.plusMin,
  tokTypes.modulo,
  tokTypes.star,
  tokTypes.slash,
  tokTypes.starstar,
  tokTypes._in,
  tokTypes._instanceof,
]);

// A newline directly BEFORE one of these changes the parse, whatever precedes
// it: `=>` must sit on the same line as its parameter list, and a `++` pushed
// onto the next line turns from a postfix operator into a prefix one.
const NEVER_BEFORE = new Set([tokTypes.arrow, tokTypes.incDec]);

// True when the character at `pos` is escaped, i.e. preceded by an odd number
// of backslashes. Used to find the end of a literal.
function isEscaped(text, pos) {
  let count = 0;
  while (pos - count - 1 >= 0 && text[pos - count - 1] === "\\") count += 1;
  return count % 2 === 1;
}

// The smallest run of characters a split may not fall inside: an escape
// sequence, in either language's spelling.
//
//   \u{1F600} é \x41   JavaScript
//   \f004 \2665             CSS - a backslash and up to six hex digits,
//                           optionally followed by one space that terminates it
//   \\ \" \n                anything else is a backslash plus one character
//
// Over-grouping is harmless here and under-grouping is not: the units are only
// ever used to choose a split point, never to interpret the text, so a rule
// that is too greedy costs a few characters of line width while a rule that is
// too narrow corrupts the literal. Hence the CSS hex branch applies to
// JavaScript too, where it can swallow the digits after a legacy octal escape.
const ESCAPE =
  /^\\(?:u\{[0-9a-fA-F]+\}|u[0-9a-fA-F]{4}|x[0-9a-fA-F]{2}|[0-9a-fA-F]{1,6}[ \t]?|[\s\S])/;

/**
 * Splits the raw source text of a string literal - quotes included - into
 * backslash-continued chunks. Works on the raw text and only between whole
 * units, so neither an escape sequence nor a surrogate pair is ever cut and
 * the value of the literal does not change.
 *
 * @param {string} raw        the literal as written in the source
 * @param {number} firstMax   room left on the line the literal starts on
 * @param {number} restMax    room on every following line
 * @returns {string}          the literal, with `\`+LF inserted
 */
function splitLiteral(raw, firstMax, restMax) {
  const out = [];
  let line = "";
  let limit = Math.max(16, firstMax);

  for (let i = 0; i < raw.length; ) {
    const escape = raw[i] === "\\" ? ESCAPE.exec(raw.slice(i, i + 12)) : null;
    // advance by escape sequence, else by code point - never by code unit
    const unit = escape ? escape[0] : String.fromCodePoint(raw.codePointAt(i));

    // -1 leaves room for the continuation backslash
    if (line.length + unit.length > limit - 1 && line.length > 0) {
      out.push(`${line}\\`);
      line = "";
      limit = Math.max(16, restMax);
    }
    line += unit;
    i += unit.length;
  }

  out.push(line);
  return out.join("\n");
}

/**
 * Wraps JavaScript so that, as far as the syntax allows, no line exceeds `max`
 * characters. The program is not otherwise modified.
 *
 * @param {string} source
 * @param {number} [max]
 * @returns {string}
 */
export function wrapJs(source, max = DEFAULT_MAX) {
  // Token boundaries come from a real tokenizer - scanning for quotes by hand
  // gets regular expressions and template literals wrong.
  const tokens = [];
  for (const token of tokenizer(source, { ecmaVersion: "latest" })) {
    tokens.push({ type: token.type, start: token.start, end: token.end });
  }

  const parts = [];
  let column = 0; // length of the output line so far
  let cursor = 0; // how much of `source` has been consumed
  let segment = ""; // text since the last break opportunity

  // Tracks whether the cursor sits in template-literal text, where an inserted
  // newline would become part of the string. `template` is inside the
  // backticks, `expr` inside a `${...}`, `brace` an ordinary block or object.
  const nesting = [];
  const inTemplateText = () => nesting[nesting.length - 1] === "template";

  // Commits the buffered segment, starting a new line first if it would not
  // fit. Breaking at the last opportunity before the limit - rather than at
  // the first one after it - is what keeps every line inside `max`.
  const commit = () => {
    if (!segment) return;
    if (column > 0 && column + segment.length > max) {
      parts.push("\n");
      column = 0;
    }
    parts.push(segment);
    const nl = segment.lastIndexOf("\n");
    column = nl === -1 ? column + segment.length : segment.length - nl - 1;
    segment = "";
  };

  for (let i = 0; i < tokens.length; i += 1) {
    const token = tokens[i];

    // whatever sits between the previous token and this one - whitespace,
    // comments - is copied through untouched
    if (token.start > cursor) segment += source.slice(cursor, token.start);

    const raw = source.slice(token.start, token.end);
    cursor = token.end;

    if (token.type === tokTypes.string && raw.length > max) {
      // Longer than a whole line: no break opportunity can help, so the
      // literal itself is continued across lines.
      //
      // It goes straight into the output rather than into `segment`, because a
      // later commit() would be free to put a newline in front of it - and the
      // token before a string is regularly one that must keep it on the same
      // line. `return "<very long>"` is the case that matters: a newline there
      // is not layout, it is an automatic semicolon and the function starts
      // returning undefined.
      commit();
      const split = splitLiteral(raw, max - column, max);
      parts.push(split);
      const nl = split.lastIndexOf("\n");
      column = nl === -1 ? column + split.length : split.length - nl - 1;
    } else {
      segment += raw;
    }

    if (token.type === tokTypes.backQuote) {
      if (inTemplateText()) nesting.pop();
      else nesting.push("template");
    } else if (token.type === tokTypes.dollarBraceL) {
      nesting.push("expr");
    } else if (token.type === tokTypes.braceL) {
      nesting.push("brace");
    } else if (token.type === tokTypes.braceR) {
      nesting.pop();
    }

    const next = tokens[i + 1];
    const breakable =
      SAFE_AFTER.has(token.type) &&
      !inTemplateText() &&
      !(next && NEVER_BEFORE.has(next.type));
    if (breakable) commit();
  }

  if (cursor < source.length) segment += source.slice(cursor);
  commit();
  return parts.join("");
}

// Separators a CSS line may be broken after: they end a declaration, a list
// item or a block, so a newline there is whitespace.
const CSS_BREAK = new Set([";", ",", "{", "}"]);

/**
 * Wraps CSS so that no line exceeds `max` characters.
 *
 * Strings and `url(...)` values are consumed whole, because a data URI carrying
 * an inlined font contains both `;` and `,` and breaking on those would corrupt
 * it. A quoted value too long for one line is continued with a backslash, which
 * CSS defines exactly like JavaScript does.
 *
 * @param {string} source
 * @param {number} [max]
 * @returns {string}
 */
export function wrapCss(source, max = DEFAULT_MAX) {
  const parts = [];
  let column = 0;
  let segment = "";

  // Same rule as in wrapJs: commit the buffered segment, breaking the line
  // before it rather than after it has already overshot.
  const commit = (force) => {
    if (!segment && !force) return;
    if (column > 0 && (force || column + segment.length > max)) {
      parts.push("\n");
      column = 0;
    }
    parts.push(segment);
    const nl = segment.lastIndexOf("\n");
    column = nl === -1 ? column + segment.length : segment.length - nl - 1;
    segment = "";
  };

  for (let i = 0; i < source.length; ) {
    const char = source[i];

    if (char === "\n") {
      commit();
      parts.push("\n");
      column = 0;
      i += 1;
      continue;
    }

    if (char === '"' || char === "'") {
      let end = i + 1;
      while (end < source.length && (source[end] !== char || isEscaped(source, end))) end += 1;
      const raw = source.slice(i, Math.min(end + 1, source.length));
      if (raw.length > max) {
        // a data URI, typically - continue it across lines
        commit();
        segment += splitLiteral(raw, max - column, max);
      } else {
        segment += raw;
      }
      i = end + 1;
      continue;
    }

    // url( ... ) unquoted: a data URI contains both `;` and `,`, so the run
    // has to stay atomic. The quoted form is handled by the branch above.
    if (/^url\(/i.test(source.slice(i, i + 4)) && !/["']/.test(source[i + 4] ?? "")) {
      const end = source.indexOf(")", i);
      const stop = end === -1 ? source.length : end + 1;
      segment += source.slice(i, stop);
      i = stop;
      continue;
    }

    segment += char;
    i += 1;
    if (CSS_BREAK.has(char)) commit();
  }

  commit();
  return parts.join("");
}

/**
 * Wraps plain text at word boundaries. Used for the bundled licence texts,
 * where a paragraph is sometimes written as one very long line and a BSP page
 * would chop it. Existing line breaks are kept; a word longer than `max` is
 * left alone rather than cut.
 *
 * @param {string} source
 * @param {number} [max]
 * @returns {string}
 */
export function wrapText(source, max = DEFAULT_MAX) {
  const out = [];

  for (const line of source.split("\n")) {
    if (line.length <= max) {
      out.push(line);
      continue;
    }
    const indent = /^\s*/.exec(line)[0];
    let current = "";
    for (const word of line.trimStart().split(/(?<=\s)/)) {
      if (current && (indent + current + word).trimEnd().length > max) {
        out.push((indent + current).trimEnd());
        current = "";
      }
      current += word;
    }
    if (current) out.push((indent + current).trimEnd());
  }

  return out.join("\n");
}

/**
 * Reports every line longer than `max`, as `<1-based line>:<length>`. The
 * caller decides whether that is a warning or a failure.
 *
 * @param {string} text
 * @param {number} [max]
 * @returns {string[]}
 */
export function overlongLines(text, max = DEFAULT_MAX) {
  return text
    .split("\n")
    .map((line, index) => (line.length > max ? `${index + 1}:${line.length}` : null))
    .filter(Boolean);
}
