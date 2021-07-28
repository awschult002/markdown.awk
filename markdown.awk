BEGIN {
	body = ""
	in_code = 0
}

function parse_header(str,    hnum, content) {
	if (substr(str, 1, 1) == "#") {
		gsub(/ *#* *$/, "", str);
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
	gsub(/^[[:space:]]*[-+*][[:space:]]/, "", str);
	gsub(/^[[:space:]]*[[:digit:]]*\.[[:space:]]/, "", str);
	return str;
}

function parse_list(str,    buf, result, i, ind, line, lines, indent, is_bullet) {
	result = "";
	buf = "";

	split(str, lines, "\n");

	str = ""
	for (i in lines) {
		line = lines[i];

		if (match(line, /^[[:space:]]*[-+*][[:space:]]/) || 
			match(line, /^[[:space:]]*[[:digit:]]+\.[[:space:]]/))
			str = join_lines(str, line, "\n");
		else
			str = join_lines(rstrip(str), lstrip(line), " ");
	}

	split(str, lines, "\n")

	indent = match(str, /[^ ]/);
	is_bullet = match(str, /^[[:space:]]*[-+*][[:space:]]/)

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

		if (is_bullet && match(line, /[[:space:]]*[[:digit:]]+\.[[:space:]]/)) {
			is_bullet = 0;
			result = result "</ul>\n<ol>\n";
		}
		if (is_bullet == 0 && match(line, /[[:space:]]*[-+*][[:space:]]/)) {
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

function extract_html_tag(str, i,    sstr) {
    sstr=substr(str, i, length(str) - i + 1);

    if (match(sstr, /^<\/[a-zA-Z][a-zA-Z0-9]*>/))
		return substr(str, i, RLENGTH) ;

    if (match(sstr, /^<[a-zA-Z][a-zA-Z0-9]*( *[a-zA-Z][a-zA-Z0-9]* *= *"[^"]*")* *>/))
		return substr(str, i, RLENGTH);

	return "";
}

function is_html_tag(str, i,    sstr) {
	if (extract_html_tag(str, i) == "")
		return 0;

	return 1;
}

function is_escape_sequence(str, i,    sstr) {
    sstr=substr(str, i, length(str) - i + 1);

	return match(sstr, /^\\[`\\*_{}\[\]()>#.!+-]/);
}

function extract_link(str, i,    sstr) {
    sstr=substr(str, i, length(str) - i + 1);

    if (!match(sstr, /^\[([^\[\]]*)\]\( *([^() ]*)( +"([^"]*)")? *\)/, arr))
		return "";

	return substr(str, i, RLENGTH);
}

function parse_link(str,    arr) {
    if (!match(str, /^\[([^\[\]]*)\]\( *([^() ]*)( +"([^"]*)")? *\)/, arr))
		return "";

	if (arr[4] == "") {
		return "<a href=\"" arr[2] "\">" arr[1] "</a>"
	}
	return "<a href=\"" arr[2] "\" title=\"" arr[4] "\">" arr[1] "</a>"
}

function is_link(str, i) {
	return extract_link(str, i) != "";
}

function escape_text(str) {
	gsub(/&/, "\\&amp;", str);
	gsub(/</, "\\&lt;", str);
	gsub(/>/, "\\&gt;", str);
	return str;
}

function parse_line(str,    result, end, i, c) {
	result = ""

	for (i=1; i<=length(str); i++) {
		c = substr(str, i, 1);

		if (c == "*" && is_token(str, i, "**")){
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
		else if (c == "`" && is_token(str, i, "```")) {
			end = find(str, "```", i+3);
			if (end != 0) {
				result = result "<code>" escape_text(substr(str, i+3, end - i - 3)) "</code>";
				i = end+2;
			}
			else {
				result = result "```";
				i=i+2;
			}
		}
		else if (c == "`" && substr(str, i, 1) == "`") {
			end = find(str, "`", i+1);
			if (end != 0) {
				result = result "<code>" escape_text(substr(str, i+1, end - i - 1)) "</code>";
				i = end;
			}
			else {
				result = result "`";
			}
		}
		else if (c == "<" && is_html_tag(str, i)) {
			tag = extract_html_tag(str, i);
		    result = result tag;
			i = i + length(tag) - 1;
		}
		else if (c == "\\" && is_escape_sequence(str, i)) {
			result = result escape_text(substr(str, i+1, 1));
		    i = i + 1;
		}
		else if (c == "[" && is_link(str, i)) {
			link = extract_link(str, i);
			result = result parse_link(link);
		    i = i + length(link) - 1; 
		}
		else {
			if (c == "\n") {
				if (length(result) > 0)
					result = result " ";
			}
			else {
				result = result escape_text(c);
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

		if (buf != "")
			buf = buf "\n" line;	
		else
			buf = line;
	}

	if (buf != "")
		result = join_lines(result, parse_body(buf), "\n");

	result = result "\n</blockquote>"

	return result;
}

function parse_code(str,    i, lines, result) {
	if (match(str, /^```.*```$/)) {
		gsub(/^```/, "", str);
		gsub(/\n```$/, "", str);
		return "<pre><code>" escape_text(str) "</code></pre>";
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
		return "<pre><code>" escape_text(result) "</code></pre>";
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
	else if (match(str, /^[-+*][[:space:]]/) || match(str, /^[[:digit:]]\.[[:space:]]/)) {
		return parse_list(str);
	}
	else  {
		return "<p>" parse_line(str) "</p>";
	}
}

function parse_body(str,    body, line, lines, result, i) {
	split(str, lines, "\n");
    result = "";
	body = "";

	for (i in lines) {
		line = lines[i];
		if (line_continues(body, line)) {
			if (body != "")
				body = body "\n" line;
			else
				body = line;
		}
		else if (body != "") {
			result = join_lines(result, parse_block(body), "\n");
			body = "";
		}
	}

	if (body != "")
		result = join_lines(result, parse_block(body), "\n");

	return result;
}

function line_continues(body, line) {
	if (match(body, /^    /) && (match(line, /^    /) || line == ""))
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
