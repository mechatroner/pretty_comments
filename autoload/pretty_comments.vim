"to get visual first and last lines use:
"line("'<") (or line("v")) - beginning of selection
"and line("'>") - end of selection

let s:comment_map = {
    \   "c": ['//', ''],
    \   "cpp": ['//', ''],
    \   "go": ['//', ''],
    \   "java": ['//', ''],
    \   "javascript": ['//', ''],
    \   "typescript": ['//', ''],
    \   "php": ['//', ''],
    \   "python": ['#', ''],
    \   "ruby": ['#', ''],
    \   "sh": ['#', ''],
    \   "vim": ['"', ''],
    \   "html": ['<!--', '-->'],
    \ }


"function! s:LineIsCommented(lineno)
"    let token = s:comment_map[&filetype]
"    let cur_line = getline(a:lineno)
"    let fwpos = match(cur_line, '^[ \t]*' . token)
"    return fwpos != -1
"endfunction

function! s:CommentedColumn(lineno)
    let token = s:comment_map[&filetype][0]
    let cur_line = getline(a:lineno)
    let fwpos = match(cur_line, '^[ \t]*' . token)
    if fwpos == -1
        return [-1, -1]
    else
        let aps = match(cur_line, token)
        return [aps, aps + len(token)]
    endif
endfunction


"function! s:DoCommentLine(line, token, ccs) 
"    if a:ccs[0] == -1
"        let cmt_line = substitute(a:cur_line, '^[ \t]*', '\0' . a:token, '')
"    else
"        let fstr = ccs[0] == 0 ? '' : cur_line[:ccs[0] - 1]
"        let cmt_line = fstr . cur_line[ccs[1]:] 
"    endif
"endfunction


function! s:GetIndentAndCut(first_line, last_line)
    let ccs = s:CommentedColumn(a:first_line)
    if ccs[0] != -1
        return ['', -1]
    endif

    let min_ws = 1000
    let min_tabs = 1000
    for lnno in range(a:first_line, a:last_line)
        let cur_line = getline(lnno)
        let fwpos = match(cur_line, '[^ \t]')
        if (fwpos == -1)
            continue
        endif
        if cur_line[0] == ' '
            let min_ws = min([min_ws, fwpos])
        else
            let min_tabs= min([min_tabs, fwpos])
        endif
    endfor

    if min_ws == 1000 && min_tabs == 1000 
        let min_ws = 0
    endif
    let ws_token = ' '
    let ws_count = min_ws
    if min_tabs < min_ws
        let ws_token = '\t'
        let ws_count = min_tabs
    endif
    let indent_str = ''
    for iii in range(ws_count)
        let indent_str = indent_str . ws_token
    endfor
    return [indent_str, ws_count]
endfunction



function! pretty_comments#comment_selection()
    if !has_key(s:comment_map, &filetype)
        echom "No comment leader found for filetype"
        return
    endif

    let first_line = line("'<")
    let last_line = line("'>")
    let ccs = s:CommentedColumn(first_line)
    let tmp = s:GetIndentAndCut(first_line, last_line)
    let indent_str = tmp[0]
    let ws_count = tmp[1]

    let before_token = s:comment_map[&filetype][0]
    let after_token = s:comment_map[&filetype][1]
    for lnno in range(first_line, last_line)
        let cur_line = getline(lnno)
        let cmt_line = ''
        if ccs[0] == -1
            let cmt_line = indent_str . before_token . cur_line[ws_count :] . after_token
        else
            let fstr = ccs[0] == 0 ? '' : cur_line[:ccs[0] - 1]
            let cmt_line = fstr . cur_line[ccs[1]:-(strlen(after_token) + 1)] 
        endif
        call append(last_line + lnno - first_line, cmt_line)
    endfor
    '<,'>delete
endfunction


function! pretty_comments#comment_single_line()
    if !has_key(s:comment_map, &filetype)
        echom "No comment leader found for filetype"
        return
    endif
    let lineno = line(".")
    let cpos = col(".")
    let before_token = s:comment_map[&filetype][0]
    let after_token = s:comment_map[&filetype][1]
    let cur_line = getline(".")
    let ccs = s:CommentedColumn(lineno)
    let tmp = s:GetIndentAndCut(lineno, lineno)
    let indent_str = tmp[0]
    let ws_count = tmp[1]
    let cmt_line = ''
    if ccs[0] == -1
        let cmt_line = indent_str . before_token . cur_line[ws_count :] . after_token
    else
        let fstr = ccs[0] == 0 ? '' : cur_line[:ccs[0] - 1]
        let cmt_line = fstr . cur_line[ccs[1]:-(strlen(after_token) + 1)] 
    endif
    delete
    call append(lineno - 1, cmt_line)
    call cursor(lineno, cpos)
endfunction

