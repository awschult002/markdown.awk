BEGIN {
	body = ""
	in_code = 0
}

function parse_header(str) {
	match($0, /#+/);
    hnum = RLENGTH;

	content = parse_line(substr(str, hnum + 1, length(str) - hnum ));
	return "<h" hnum ">" content "</h" hnum ">";
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

function parse_line(str,    result, end, i) {
	#print "block '" str "'"
	result = ""


	for (i=1; i<=length(str); i++) {
		if (substr(str, i, 2) == "**") {
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
		else if (substr(str, i, 3) == "```") {
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
				result = result substr(str, i, 1);
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

function parse_block(str) {
	if (str == "")
		return "";

	if (substr(str, 1, 1) == "#") {
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

function parse_body(str) {
    print(parse_block(str));
}

/^#/ {
	if (body != "") {
		parse_body(body);
	}
	parse_body($0);
	body = "";
    next;
}

/^$/ {
	if (body == "")
		next;

	if (startswith(body, "```") == 1) {
		body = body "\n";
		next;
	}

	parse_body(body);
	body = "";
	next;
}

/```/ {
	if (startswith(body, "```") == 1) {
		print "<pre><code>" substr(body, 4, length(body)-3) "</code></pre>";
		body = "";
		next;
	}
}

// {
	body = join_lines(body, $0, "\n")
	next;
}

END {
	if (body != "") {
		parse_body(body);
	}
}
