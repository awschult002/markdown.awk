#!/bin/bash

set -e

check() {
	input="$(mktemp)"
	expected_output="$(mktemp)"
	output="$(mktemp)"

	current="input"
	while IFS='$\n' read -r line; do
		if [[ "$line" == "---" ]]; then
			current="output"
		elif [[ "$current" == "input" ]]; then
			echo "$line" >> "$input"
		else
			echo "$line" >> "$expected_output"
		fi
    done

	awk -f markdown.awk "$input" >> "$output"

	result="success"

	if ! cmp -s "$output" "$expected_output"; then
		echo "FAIL"
		echo "--- input"
		cat "$input"
		echo "--- expected"
		cat "$expected_output"
		echo "--- got"
		cat "$output"
		echo "---"
		result="fail"
	else
		echo "SUCCESS"
	fi

	rm "$input"
	rm "$expected_output"
	rm "$output"

	if [[ "$result" == "fail" ]]; then
		exit 1
	fi
}

check <<-EOF
This is a simple sentence.
---
<p>This is a simple sentence.</p>
EOF


check <<-EOF
This is a
simple sentence.
---
<p>This is a simple sentence.</p>
EOF

check <<-EOF
First paragraph.

Second paragraph.
---
<p>First paragraph.</p>
<p>Second paragraph.</p>
EOF

check <<-EOF
# Header
body
---
<h1> Header</h1>
<p>body</p>
EOF

check <<-EOF
# Header1
## Header2
### Header3
---
<h1> Header1</h1>
<h2> Header2</h2>
<h3> Header3</h3>
EOF

check <<-EOF
underlined header 1
===================

underlined header 2
-------------------
---
<h1>underlined header 1</h1>
<h2>underlined header 2</h2>
EOF

check <<-EOF
**bold**
---
<p><strong>bold</strong></p>
EOF

check <<-EOF
**bold
multiline**
---
<p><strong>bold multiline</strong></p>
EOF

check <<-EOF
**bold
---
<p>**bold</p>
EOF

check <<-"EOF"
```
first line of code

second line of code
```
---
<pre><code>
first line of code

second line of code</code></pre>
EOF

check <<-"EOF"
```
first line of code

second line of code
---
<p>``` first line of code  second line of code</p>
EOF

check <<-"EOF"
    code
    indented by
    spaces
---
<pre><code>code
indented by
spaces</code></pre>
EOF

check <<-"EOF"
asdf

* foo
* bar
---
<p>asdf</p>
<ul>
<li>foo</li>
<li>bar</li>
</ul>
EOF

check <<-"EOF"
asdf

* bullet 1
* bullet
  2
---
<p>asdf</p>
<ul>
<li>bullet 1</li>
<li>bullet 2</li>
</ul>
EOF

check <<-"EOF"
asdf

1. number 1
2. number
  2
---
<p>asdf</p>
<ol>
<li>number 1</li>
<li>number 2</li>
</ol>
EOF

check <<-"EOF"
* **basic formatting**
* ```in list```
---
<ul>
<li><strong>basic formatting</strong></li>
<li><code>in list</code></li>
</ul>
EOF

check <<-"EOF"
* first
level 1
    * second
  level 1
  * second level 2
    * third level
* first level
  2
---
<ul>
<li>first level 1
<ul>
<li>second level 1</li>
<li>second level 2
<ul>
<li>third level</li>
</ul></li>
</ul></li>
<li>first level 2</li>
</ul>
EOF

check <<-"EOF"
* bullet1
1. number1
* bullet2
2. number2
---
<ul>
<li>bullet1</li>
</ul>
<ol>
<li>number1</li>
</ol>
<ul>
<li>bullet2</li>
</ul>
<ol>
<li>number2</li>
</ol>
EOF

check <<-"EOF"
> foo
> bar
---
<blockquote>
<p>foo bar</p>
</blockquote>
EOF

check <<-"EOF"
> foo
> 
> > bar
> > baz
---
<blockquote>
<p>foo</p>
<blockquote>
<p>bar baz</p>
</blockquote>
</blockquote>
EOF

echo 
echo "All tests passed"
