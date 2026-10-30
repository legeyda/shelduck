
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


shelduck import ../../src/shelduck.sh

test_01() {
	shelduck_parse_heredoc hello
	assert_result_equals false '"<<" expected'
}

test_02() {
	shelduck_parse_heredoc '   <<'
	assert_result_equals false 'newline expected'
}

test_03() {
	shelduck_parse_heredoc '   <<
'
	assert_result_equals false 'empty heredoc-constant'
}

test_04() {
	shelduck_parse_heredoc '   <<EOF
'
	assert_result_equals false 'only escaped heredocs supported'
}

test_05() {
	shelduck_parse_heredoc '   <<\EOF-blabla
'
	assert_result_equals false 'heredoc contstant invalid'
}

test_06() {
	shelduck_parse_heredoc "   <<'EOF-blabla'
"
	assert_result_equals false 'heredoc contstant invalid'
}

test_07() {
	shelduck_parse_heredoc '   <<\EOF
'
	assert_result_equals false 'heredoc end marker not found'
}

test_08() {
	shelduck_parse_heredoc '   <<\EOF
value
EOF'
	assert_result_equals true 'value
' ''
}

test_09() {
	shelduck_parse_heredoc '   <<\EOF
value
EOF
hello'
	assert_result_equals true 'value
' hello
}

test_10() {
	shelduck_parse_heredoc "<<'EOF'
value
EOF
hello"
	assert_result_equals true 'value
' hello
}
