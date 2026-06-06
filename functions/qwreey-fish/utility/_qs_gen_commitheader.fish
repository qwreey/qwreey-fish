function _qs_gen_commitheader -a prefix range
	# Expend short flag
	switch "$prefix"
		case fx fi; set prefix "fix"
		case ft fe; set prefix "feat"
		case co ch; set prefix "chore"
		case dc do; set prefix "docs"
		case ts te; set prefix "test"
		case rf re; set prefix "refactor"
		case pe pf; set prefix "perf"
		case se sc; set prefix "security"
		case st; set prefix "style"
		case dk; set prefix "docker"
	end

	# Push range flag to prefix
	test -n "$range"
	and set prefix "$prefix""($range)"

	echo -n "$prefix"
end
