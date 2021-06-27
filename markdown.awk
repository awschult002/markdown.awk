# markdown implementation in awk
# references: 
# - https://gist.github.com/xdanger/116153
# - https://github.com/nuex/zodiac/blob/master/lib/markdown.awk
# - https://dataswamp.org/~solene/2019-08-26-minimal-markdown.html

BEGIN {
	si = 0;
	stack[si] = "body";
	val[si] = 0
	res[si] = ""
	i = 0;
}

function peek(num) {
	return substr($0, i, num);
}

function push(block) {
	stack[++si] = block;
	res[si] = "";
	val[si] = 0;
}

function pop(str) {
	res[si-1] = res[si-1] str
	res[si] = ""
	val[si] = 0
	si--

	if (stack[si] == "body") {
		printf(res[si]);
		res[si] = ""
	}
}

function handle_code() {
	if (peek(1) == "`") {
		i = i + 1;
		pop("<code>" res[si] "</code>")
		return;
	}
	if ($0 == "") {
		pop("`" res[si])
		return;
	}
	if (i > length($0)) {
		next;
	}

	if (i == 1 && length(res[si]) > 0)
		res[si] = res[si] " ";

	res[si] = res[si] peek(1)
	i++;
}

function handle_code_long() {
	if (peek(3) == "```") {
		i = i + 3;
		pop("<code>" res[si] "</code>")
		return;
	}
	if (i > length($0)) {
		res[si] = res[si] "\n";
		next;
	}

	res[si] = res[si] peek(1)
	i++;
}

function handle_inline_code() {
	if (peek(1) == "`") {
		i = i + 1;
		pop("<code>" res[si] "</code>")
		return;
	}
	if (i > length($0)) {
		pop("`" res[si]);
		return;
	}

	res[si] = res[si] peek(1)
	i++;
}

function handle_inline_code_long() {
	if (peek(3) == "```") {
		i = i + 3;
		pop("<code>" res[si] "</code>")
		return;
	}
	if (i > length($0)) {
		pop("```" res[si]);
		return;
	}

	res[si] = res[si] peek(1)
	i++;
}

function handle_inline_strong() {
	if (peek(2) == "**") {
		i = i + 2;
		pop("<strong>" res[si] "</strong>")
		return;
	}
	if (peek(3) == "```") {
		i = i + 3;
		push("inline_code_long");
		return;
	}
	if (peek(1) == "`") {
		i = i + 1;
		push("inline_code");
		return;
	}
    if (i > length($0)) {
		pop("**" res[si]);
		return;
	}

	res[si] = res[si] peek(1)
	i++;
}

function handle_inline() {
	if (peek(2) == "**") {
		i = i + 2;
		push("inline_strong");
		return;
	}
	if (peek(3) == "```") {
		i = i + 3;
		push("inline_code_long");
		return;
	}

	res[si] = res[si] peek(1);
	i++;
}

function handle_block() {
	if (peek(3) == "```") {
		i = i + 3;
		push("code_long");
		return;
	}
	if (peek(1) == "`") {
		i = i + 1;
		push("code");
		return;
	}
	res[si] = res[si] peek(1);
	i++;
}

function handle_paragraph() {
    if (i == 1 && ($0 == "" || peek(1) == "#")) {
		if (length(res[si]) > 0)
			pop("<p>" res[si] "</p>\n");
		else
			pop("");

		if (peek(1) == "#")
			return;

		next;
	}

	if (i == 1 && length(res[si]) > 0)
		res[si] = res[si] " ";

	handle_block();

	if (i > length($0))
		next;
}

function handle_header() {
	if (i == 1)	{
		match($0, /#+/);
	    val[si] = RLENGTH;
		i = RLENGTH + 1;
		return;
	}

	if (i>length($0)) {
		pop("<h" val[si] ">" res[si] "</h" val[si] ">\n");
		next;
	}

	handle_inline();
}

function handle_body() {
	if (peek(1) == "#") {
		push("header");
		return;
	}
	else {
		push("paragraph");
		return;
	}
}

// {
	i = 1;

	while (1) {
		if (stack[si] == "body")
			handle_body();
		else if (stack[si] == "paragraph")
			handle_paragraph();
		else if (stack[si] == "header")
			handle_header();
		else if (stack[si] == "inline_strong")
			handle_inline_strong();
		else if (stack[si] == "inline_code_long")
			handle_inline_code_long();
		else if (stack[si] == "inline_code")
			handle_inline_code();
		else if (stack[si] == "code_long")
			handle_code_long();
		else if (stack[si] == "code")
			handle_code();
	}
}


END {
	#print res[si];
	#newblock();
}
