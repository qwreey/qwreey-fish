function _qs_init_abbr
	# git add, commit, push
	abbr --add _qs_abbr_gcm --position=command --function=_qs_abbrfn_gcm --set-cursor --regex '^gcm.+'
	abbr --add _qs_abbr_gacm --position=command --function=_qs_abbrfn_gacm --set-cursor --regex '^gacm.+'
	abbr --add _qs_abbr_gacpm --position=command --function=_qs_abbrfn_gacpm --set-cursor --regex '^gacpm.+'

	# git log
	abbr --add _qs_abbr_gl   --position=command --function=_qs_abbrfn_gl   --regex '^gl([soga]+)'

	# npm
	abbr --add _qs_abbr_npmi --position=command --function=_qs_abbrfn_npmi --set-cursor --regex '^npmi.*'
	abbr --add _qs_abbr_npmr --position=command --function=_qs_abbrfn_npmr --set-cursor --regex '^npmr.*'
	abbr --add _qs_abbr_npmb --position=command --function=_qs_abbrfn_npmb --set-cursor --regex '^npmb.*'
	abbr --add _qs_abbr_npmp --position=command --function=_qs_abbrfn_npmp --set-cursor --regex '^npmp.*'

	# Docker
	abbr -a _qs_abbr_dockercomposeupd -r dcud "docker compose up -d"
	abbr -a _qs_abbr_dockercomposeup  -r dcu  "docker compose up"
end
