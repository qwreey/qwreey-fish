function _qs_abbrfn_gacpm
	set -l matches (string match --regex '^gacpm([^.]+)\.?(.*)' $argv[1])
	set -l gitdir (_qs_get_gitdir)
	or return 1
	set prefix (_qs_gen_commitheader $matches[2] $matches[3])
	echo "git add $gitdir"\n"and git commit -m \"$prefix: %\""\n"and git push"
end
