set -eux

shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/misc/log.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/quote.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/read.sh

bobshell_str_quote 1 str '1 2' "'" '"'
bobshell_result_read x
printf %s "$x"
