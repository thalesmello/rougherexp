" RougherExp
"
" Version: 0.1
" Description:
"
"   Changes your search expression into rougher regexp.
"
" Maintainer: Shuhei Kubota <kubota.shuhei+vim@gmail.com>
"
" Usage:
"   1. Search for something.
"   2. Execute ':RougherExp'.
"      Then Vim restarts searching by rougher regexp.
"
"   Example:
"       /abc123def('a', 'zzz', 0, null);
"       or /neko999inu('p', 'hogehoge', 1, null);
"           |
"           V
"       /\a\+\d\+\a\+('\a',\s'\a\+',\s\d,\s\a\+);
"
"   Recovery:
"       To bring back your search expression, use search history.
"       (/<UP> or /<DOWN>)
"


"if !exists('g:RougherExp_elements')
    "let g:RougherExp_elements = ['\s', '\d', '\a', '\w']
    let g:RougherExp_elements = ['\s', '\d', '\a']
"endif

"if !exists('g:RougherExp_rougherReduction')
    " reduce \a and \d to \w

    "let g:RougherExp_rougherReduction = 1
    let g:RougherExp_rougherReduction = 0
"endif

"xnoremap * :call <SID>RougherExp_execute()<CR>gv"*y/\V<C-R>=<SID>StarRange__substituteSpecialChars(@*)<CR><CR>:call <SID>StarRange__restoreReg()<CR>:echo<CR>

command! RougherExp call g:RougherExpSearch()


" command! -register Hogehoge call g:Hogehoge('@<register>@')
" func! g:Hogehoge(value)
"     echo a:value
" endfunc

function! g:RougherExpSearch()
    let rexp = g:RougherExp(@/)

    " remember the expression in / history
    execute 'normal /' . rexp
    " and start searching immediately
    let @/ = rexp
    " ... and move the cursor immediately to the next match
    call search(rexp)
endfunction


" rawstring
" a:000[0] : reservedexp
function! g:RougherExp(rawstring, ...)
    if a:0 >= 1
        let reservedexp = a:000[0]
    else
        let reservedexp = '\_$'
    endif

    "echom 'rawstring = ' . a:rawstring
    let converted_parts = map(split(a:rawstring, reservedexp, 1), 's:RougherExp__inner(v:val)')
    "echom 'converted_parts = ' . string(converted_parts)
    let reserved_parts = s:RougherExp__matchstrlist(a:rawstring, reservedexp)
    "echom 'reserved_parts = ' . string(reserved_parts)

    " merge, stringify
    let rougherexp = ''
    let rougherlen = 0
    for p in converted_parts
        if len(reserved_parts)
            let pos = reserved_parts[0][0] " pos of the first element
            while pos <= rougherlen
                let rougherexp .= reserved_parts[0][1] " str of the first element
                let rougherlen += len(reserved_parts[0][1])

                call remove(reserved_parts, 0)

                let pos = 9999
                if len(reserved_parts)
                    let pos = reserved_parts[0][0] " pos of the first element
                endif
            endwhile
        endif
        
        let rougherexp .= p
        let rougherlen += len(p)
    endfor

    return rougherexp
endfunction


function! s:RougherExp__inner(rawstring)
    let rougherexp = ''

    let sla = 0

    " iterate rawstring
    let cnt = len(a:rawstring)
    for i in range(cnt)
        let r = a:rawstring[i]
        "echom 'a:rawstring['.i.'] = ' . r

        let matched = 0
        if !sla
            for e in g:RougherExp_elements
                if r =~ e
                    let rougherexp .= e
                    "echom ' ... matched with ' . e
                    let matched = 1
                    break
                endif
            endfor
        endif
        if !matched
            "echom r
            let rougherexp .= r
            let sla = !sla && (r == '\')
        endif
    endfor

    " reduce it rougherly
    let rougherexp = substitute(rougherexp, '\v(\\[adw])\1+', '\1\\+', 'g')
    if g:RougherExp_rougherReduction
        " realy rougher!
        let rougherexp = substitute(rougherexp, '\v\\[ad](\\\+)?\\w(\\\+)?', '\\w\\+', 'g')
        let rougherexp = substitute(rougherexp, '\v\\w(\\\+)?\\[ad](\\\+)?', '\\w\\+', 'g')
    endif

    return rougherexp
endfunction


function! g:RougherExp__test__matchedstrlist(expr, pat)
    return s:RougherExp__matchstrlist(a:expr, a:pat)
endfunction
function! s:RougherExp__matchstrlist(expr, pat)
    let matches = []

    if a:pat == '\_$'
        return matches
    endif

    let pos = match(a:expr, a:pat)
    while pos != -1
        let matchedstr = matchstr(a:expr, a:pat, pos)
        let matches = add(matches, [pos, matchedstr])
        let pos = match(a:expr, a:pat, pos + len(matchedstr))
    endwhile

    return matches
endfunction
