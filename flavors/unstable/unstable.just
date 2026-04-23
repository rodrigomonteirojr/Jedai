set quiet
set no-exit-message
set unstable

# TODO: Modularize

file-regex := '^EDIT .'
hist       := '.jedai_history~'
editor     := 'vis'

history-tail(n)     := f"grep -e '{{file-regex}}' '{{hist}}' | awk '!seen[$2]++' | tail -n {{n}}"
history-grab(n)     := f"$({{history-tail(n)}} | head -n 1 | cut -d' ' -f2-)"
history-add(f)      := f'echo "EDIT {{f}}" >> ' + f"'{{hist}}'"
history-numbered(n) := f"{{history-tail(n)}} | tee '{{hist}}' | cut -d' ' -f2- | tac | nl"

err(msg) := f'{{RED + BOLD}}error{{NORMAL}}: {{msg}}'


[group('setup')]
[doc("check tool sanity")]
vet: (check-program 'fzf') (check-program 'rg')
	echo "status: OK"


[group('setup')]
[private]
check-program p:
	which '{{p}}' || { \
		printf '{{err(f'Program "{{p}}" not found')}}\n'; \
		exit 1; \
	}
	


[group('files')]
choose pattern="":
	FILE="$(fzf --walker-skip=.git,vendor,public --query='{{pattern}}')"; \
		[ -z "$FILE" ] && { printf '{{err('No file specified!')}}\n'; exit 1; }; \
		{{history-add('$FILE')}}; \
		{{editor}} $FILE

alias o:=choose


[group('files')]
edit file:
	{{history-add(file)}}
	{{editor}} {{file}}

alias e:=edit


[group('files')]
[arg('n', pattern='\d+')]
resume n='1':
	touch '{{hist}}'
	( FILE={{history-grab(n)}}; \
		[ -z "$FILE" ] && { \
			printf '{{err('History is empty!')}}\n'; \
			exit 1; \
		}; \
		{{history-add('$FILE')}}; \
		{{editor}} $FILE; \
	)

alias r:=resume


[group('history')]
[arg('n', pattern='\d+')]
history n='10':
	touch '{{hist}}'
	{{history-numbered(n)}}

alias h:=history


[group('history')]
history-rm n='1':
	touch '{{hist}}'
	[ "$(wc -l '{{hist}}' | cut -d' ' -f1)" -ge '{{n}}' ] || ( \
		printf '{{err('Number out of range!')}}\n'; \
		exit 1; \
	)
	FILE={{history-grab(n)}}; awk "\$2!=\"$FILE\"" '{{hist}}' | tee '{{hist}}'

[group('history')]
[confirm]
history-clear:
	echo '' > '{{hist}}'

alias hr:=history-rm
alias hc:=history-clear


[group('docs')]
help cmd:
	'{{cmd}}' --help 2>&1 | less


[group('search')]
definition sym window='10':
	rg -g!vendor -g'*.go' --heading -A '{{window}}' \
		-- 'func\s?(\(.+\))?\s?{{sym}}'

alias def:=definition


[group('search')]
containing pat:
	rg -l --heading -g!vendor -g!'*.pgerd' -- '{{pat}}' | xargs

alias c:=containing


[group('search')]
search pat n='10':
	rg -A '{{n}}' --heading -g!vendor -g!'*.pgerd' -- '{{pat}}'

alias s:=search


[group('test')]
check:
	go vet


