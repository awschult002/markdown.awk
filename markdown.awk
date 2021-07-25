BEGIN {
	body = ""
	in_code = 0
}

function parse_header(str,    hnum, content) {
	if (substr(str, 1, 1) == "#") {
		match(str, /#+/);
    	hnum = RLENGTH;

		gsub(/^#+ */, "", str);
		content = parse_line(str);
		return "<h" hnum ">" content "</h" hnum ">";
	}
	if (match(body, /^[^\n]+\n=+$/)) {
		gsub(/\n=+$/, "", str);
		return "<h1>" parse_line(str) "</h1>"
	}
	if (match(body, /^[^\n]+\n-+$/)) {
		gsub(/\n-+$/, "", str);
		return "<h2>" parse_line(str) "</h2>"
	}
	return "";
}

function read_line(str, pos, res, i) {
	res = "";
	for (i=pos; i<=length(str); i++) {
		if (substr(str, i, 1) == "\n")
			return res;
		res = res substr(str, i, 1);
	}

	return res;
}

function find(str, s, i,    sl, j) {
	sl = length(s);
	for (j = i; j <= length(str); j++) {
		if (substr(str, j, sl) == s)
			return j;
	}

	return 0;
}

function startswith(str, s,    sl, j) {
	sl = length(s);	
	for (j = 1; j <= length(str); j++) {
		if (substr(str, j, sl) == s)
			return j;
		if (substr(str, j, 1) != " ")
			return 0;
	}
	return 0;
}

function rstrip(str) {
	gsub(/ *\n*$/, "", str);
	return str;
}

function lstrip(str) {
	gsub(/^ *\n*/, "", str);
	return str;
}

function escape_special() {
	
}

function join_lines(first, second, sep) {
	if (sep == "")
		sep = " ";

	if (second == "")
		return first;

	if (first == "")
		return second;

	return first sep second;
}

function strip_list(str) {
	gsub(/^ *\* /, "", str);
	gsub(/^ *[[:digit:]]*\. /, "", str);
	return str;
}

function parse_list(str,    buf, result, i, ind, line, lines, indent, is_bullet) {
	result = "";
	buf = "";

	split(str, lines, "\n");

	str = ""
	for (i in lines) {
		line = lines[i];

		if (match(line, / *\* /) || match(line, / *[[:digit:]]+\. /))
			str = join_lines(str, line, "\n");
		else
			str = join_lines(rstrip(str), lstrip(line), " ");
	}

	split(str, lines, "\n")

	indent = match(str, /[^ ]/);
	is_bullet = match(str, /^ *\* /)

	if (is_bullet)
		result = "<ul>\n"
	else
		result = "<ol>\n"

	for (i in lines) {
		line = lines[i];

		if (match(line, "[^ ]") > indent) {
			buf = join_lines(buf, line, "\n");
			continue
		}

		indent = match(line, "[^ ]");

		if (buf != "") {
			result = join_lines(result, parse_list(buf), "\n");
			buf = "";
		}
		if (i > 1)
			result = result "</li>\n"

		if (is_bullet && match(line, / *[[:digit:]]+\. /)) {
			is_bullet = 0;
			result = result "</ul>\n<ol>\n";
		}
		if (is_bullet == 0 && match(line, / *\* /)) {
			is_bullet = 1;
			result = result "</ol>\n<ul>\n";
		}

		result = result "<li>" parse_line(strip_list(line))
	}

	if (buf != "") {
		result = join_lines(result, parse_list(buf), "\n")
	}
	result = result "</li>";

	if (is_bullet)
		result = result "\n</ul>";
	else
		result = result "\n</ol>";

	return result;
}

function is_token(str, i, tok) {
	return substr(str, i, length(tok)) == tok;
}

function escape_char(char) {
    if (char == "<")
		return "&lt;";
    if (char == ">")
		return "&gt;";
	if (char == "&")
		return "&amp;";

	return char;
}

function parse_line(str,    result, end, i) {
	#print "block '" str "'"
	result = ""


	for (i=1; i<=length(str); i++) {
		if (is_token(str, i, "**")){
			end = find(str, "**", i+2);

			if (end != 0) {
				result = result "<strong>" parse_line(substr(str, i+2, end - i - 2)) "</strong>";	
				i = end+1;
			}
			else {
				result = result "**";
				i++;
			}
		}
		else if (is_token(str, i, "```")) {
			end = find(str, "```", i+3);
			if (end != 0) {
				result = result "<code>" substr(str, i+3, end - i - 3) "</code>";
				i = end+1;
			}
			else {
				result = result "```";
				i=i+2;
			}
		}
		else if (substr(str, i, 1) == "`") {
			end = find(str, "`", i+1);

		}
		else {
			if (substr(str, i, 1) == "\n") {
				if (length(result) > 0)
					result = result " ";
			}
			else {
				result = result escape_char(substr(str, i, 1));
			}
		}
	}

	return result;
}

function parse_blockquote(str,    i, lines, line, buf, result) {
	split(str, lines, "\n");

	str = ""
	for (i in lines) {
		line = lines[i];

		if (match(line, /^>/))
			str = join_lines(str, line, "\n");
		else
			str = join_lines(rstrip(str), lstrip(line), " ");
	}
	
	split(str, lines, "\n");

	result = "<blockquote>";
	buf = "";
	for (i in lines) {
		line = lines[i];
		gsub(/^> ?/, "", line);

		if (match(line, /^ *$/)) {
			result = join_lines(result, parse_block(buf), "\n");
			buf = "";
		}
		else {
			buf = join_lines(buf, line, "\n");	
		}
	}

	if (buf != "")
		result = join_lines(result, parse_block(buf), "\n");

	result = result "\n</blockquote>"

	return result;
}

function parse_code(str,    i, lines, result) {
	if (match(str, /^```.*```$/)) {
		gsub(/^```/, "", str);
		gsub(/\n```$/, "", str);
		return "<pre><code>" str "</code></pre>";
	}
	if (match(str, /^    /)) {
		result = "";
		split(str, lines, "\n");

		for (i in lines) {
			line = lines[i];
			gsub(/^    /, "", line);
			result = result "\n" line;
		}
		gsub(/^\n/, "", result);
		return "<pre><code>" result "</code></pre>";
	}

	return "";
}

function parse_block(str) {
	if (str == "")
		return "";

	if (match(str, /^```\n.*```$/) || match(str, /^    /)) {
		return parse_code(str);
	}
	if (substr(str, 1, 1) == "#" || match(body, /^[^\n]+\n[-=]+$/)) {
		return parse_header(str);
	}
	else if (substr(str, 1, 1) == ">") {
		return parse_blockquote(str);
	}
	else if (match(str, /^\* /) || match(str, /^[[:digit:]]\. /)) {
		return parse_list(str);
	}
	else  {
		return "<p>" parse_line(str) "</p>";
	}
}

function line_continues(body, line) {
	if (match(body, /^    /) && match(line, /^    /))
		return 1;

	if (match(body, /^```\n/) && !match(body, /\n```$/))
		return 1;

	if (match(body, /^#* /))
		return 0;

	if (match(body, /^[^\n]+\n[-=]+$/))
		return 0;

	if (line != "")
		return 1;

	return 0;
}

// {
	if (line_continues(body, $0)) {
		if (body != "")
			body = body "\n" $0;
		else
			body = $0;
		next;
	}

	if (body != "") 
		print parse_block(body);

	body = $0;

	next;
}

END {
	if (body != "")
		print parse_block(body);
}
