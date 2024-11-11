Shelduck is a tiny tool to fetch dependencies for shell scripts.



Usage:

Use at runtime. Insert into script

	curl https://raw.githubusercontent.com/legeyda/shelduck/refs/heads/main/shelduck.sh

	shelduck https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/master/base.sh substr isprefix=starts_with falias=function_alias shelduck_*
	
	shelduck https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/master/sshauth.sh '*=shelduck_*'
	function_alias copy=shelduck_copy_resource

	with arg 
	call_with_vars 'SSH_*=PAYREGISTRY_DEPLOY_SSH_*' sshauth ssh x
	var_scope 


	wrap_function