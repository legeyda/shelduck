
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/quote.sh


shelduck fetch ./include1.txt
x="$bobshell_result_2"

shelduck fetch ./include2.txt
x="$x$bobshell_result_2"

shelduck fetch ./include1.txt
x="$x$bobshell_result_2"

bobshell_str_quote "$x"
printf %s "$bobshell_result_1"
