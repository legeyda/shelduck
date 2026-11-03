
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/base.sh


shelduck import ../../src/parse/heredoc.sh



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
	listner() {
		x="$x"'<'"$(printf '<%s> ' "$@")"'> '
	}


	x=''
	shelduck_parse_heredoc '   <<\EOF
value
EOF' listner

	assert_result_equals true '   <<\EOF
value
EOF' ''

 	assert_equals '<<heredoc> <content> <value
> <EOF> > <<heredoc> <   <<\EOF
value
EOF> <> > ' "$x"

}




test_09() {
	listner() {
		x="$x"'<'"$(printf '<%s> ' "$@")"'> '
	}


	x=''
	shelduck_parse_heredoc '   <<\EOF
value
EOF
blabla' listner

	assert_result_equals true '   <<\EOF
value
EOF
' 'blabla'

 	assert_equals '<<heredoc> <content> <value
> <EOF
blabla> > <<heredoc> <   <<\EOF
value
EOF
> <blabla> > ' "$x"

}



test_10() {
	listner() {
		x="$x"'<'"$(printf '<%s> ' "$@")"'> '
	}


	x=''
	shelduck_parse_heredoc "<<'EOF'
value
EOF
blabla" listner

	assert_result_equals true "<<'EOF'
value
EOF
" blabla

 	assert_equals "<<heredoc> <content> <value
> <EOF
blabla> > <<heredoc> <<<'EOF'
value
EOF
> <blabla> > " "$x"
}
