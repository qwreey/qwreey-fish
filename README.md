<-- base prompt:
아래는 fish shell 의 git abbr 입니다. 설명을 확인해보고 공식적인 문서화처럼 작성해주세요. 다만 너무 ai 처럼 주저리 주저리 설명하진 말고 간략하게 하는데 유의하세요.

코드블럭으로 문서 부분을 감싸고, 코드 블럭 안에서는 영어가 되어야하며 지금 사용자와의 관계를 고려하지 마세요. 읽게될 사람은 레포지토리 방문자임을 유의하세요
-->

### Fish Shell Git Abbreviations (`gacpm`)

To make the command easy to memorize, **`gacpm`** stands for **G**it **A**dd **C**ommit **P**ush **M**essage. This structure allows you to quickly compose and execute conventional commit commands.

**Syntax**
`g[a]c[p]m<prefix>[.<scope>]`

**Flags (Optional)**
* `a` : Prepends `git add (_qs_get_gitdir)` before committing.
* `p` : Appends `git push` after committing.

**Prefixes (Commit Types)**
You can use the full commit type or the following shortcodes:
* `ft`, `fe` : feat
* `fx`, `fi` : fix
* `co`, `ch` : chore
* `dc`, `do` : docs
* `ts`, `te` : test
* `rf`, `re` : refactor
* `pe`, `pf` : perf
* `se`, `sc` : security
* `st`       : style
* `dk`       : docker

**Scope (Optional)**
Append `.<scope_name>` to specify the scope of the commit.

**Examples**
* `gcmfix.backend` expands to: `git commit -m "fix(backend): "`
* `gcmdo.backend` expands to: `git commit -m "docs(backend): "`
* `gacpmft` expands to: `git add (_qs_get_gitdir)\nand git commit -m "feat: " && git push`
