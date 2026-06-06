function _qs_abbrfn_npmr
	set -l matches (string match --regex '^npmr(.*)')
	echo (echo "npm run $matches[2] " | string trim)" %"
end
