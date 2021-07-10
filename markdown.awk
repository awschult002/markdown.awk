BEGIN {
	body = ""
	in_code = 0
}

function parse_header(str) {
	match($0, /#+/);
    hnum = RLENGTH;

	content = parse_block(substr(str, hnum + 1, length(str) - hnum ));
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
#function parse_list_item(str, 

function fold_lines(arr, i, result) {
	for (i in arr) {
		if (result != "")
			result = result " " arr[i];
		else
			result = arr[i];
	}
}

function parse_list(str,    buf, result, i, ind, line, lines, indent) {
	result = "<ul>\n";
	buf = "";

	print "parse: " str ">" startswith(str, "* ")
	split(str, lines, "\n");

	for (i in lines) {
		line = lines[i];
	}

	indent = 0;
	for (i in lines) {
		line = lines[i];
		print "line: " line " " startswith(line, "* ") " " indent
		ind = startswith(line, "* ");
		if (indent == 0 && ind > 0) {
			indent = ind;
		}
		else if (indent > 0 && ind > 0 && ind <= indent) {
			if (length(buf) > 0) {
				result = result "<li>" parse_list(buf) "</li>\n";
				buf = "";
			}
		}
		if (length(buf) > 0)
			buf = buf "\n";

		if (ind > 0 && ind <= indent) {
			buf = buf substr(line, ind+2, length(line) - 2);
		}
		else
			buf = buf line;
	}
	if (length(buf) > 0) {
		result = result "<li>" parse_list(buf) "</li>\n";
	}
	result = result "</ul>";
	return result;
}

function parse_block(str,    result, end, i) {
	#print "block '" str "'"
	result = ""

	if (substr(str, 1, 2) == "* ") {
		return parse_list(str);
	}

	for (i=1; i<=length(str); i++) {
		if (substr(str, i, 2) == "**") {
			end = find(str, "**", i+2);

			if (end != 0) {
				result = result "<strong>" parse_block(substr(str, i+2, end - i - 2)) "</strong>";	
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
	#print "block result '" result "'"
	return result;
}

function parse_paragraph(str) {
	if (substr(str, 1, 2 ) == "* ") {
		return parse_block(str);
	}
	else  {
		return "<p>" parse_block(str) "</p>";
	}
}

function parse_body(str) {
	if (substr(str, 1, 1) == "#") {
		print(parse_header(str));
	}
	else {
		print(parse_paragraph(str));
	}
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
	    if (body != "")
		    body = body "\n";

		print "<code>" substr(body, 4, length(body)-3) "</code>";
		body = "";
		next;
	}
}

// {
	if (body != "")
		body = body "\n" $0;
	else
		body = $0;

	next;
}

END {
	if (body != "") {
		parse_body(body);
	}
}
