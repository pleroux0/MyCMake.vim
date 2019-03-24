" autoload/MyCMake.vim


function! s:DeleteFile(file)
    " Delete a file

    if !filereadable(a:file)
        echo "Skipping deletetion of file that doesn't exist: " . a:file
        return v:true
    endif

    if !filewritable(a:file)
        echo "Can't delete file without write permissions: " . a:file
        return v:false
    endif

    call delete(a:file)

    return v:true
endfunction


function! s:ToString(string_or_list)
    " Convert a string or list into a string
    if type(a:string_or_list) == type([])
        return join(a:string_or_list, ' ')
    elseif type(a:string_or_list) == type('string')
        return a:string_or_list
    else
        echoerr 'a:string_or_list is neither a string or a list'
    endif
endfunction


function! s:Execute(command)
    " Execute command
    if exists('t:cmake_silent_execute')
      if t:cmake_silent_execute:
        exec ':silent !' . s:ToString(a:command)
      else
        exec ':!' . s:ToString(a:command)
      endif
    else
        exec ':!' . s:ToString(a:command)
    endif

    if v:shell_error
        echo 'Command exited with non-zero exit code'
        return v:false
    endif

    return v:true
endfunction


function! MyCMake#ClearVars()
    " Clear CMake variables

    " CMake settings
    unlet! t:cmake_build_dir
    unlet! t:cmake_source_dir
    unlet! t:cmake_silent_execute

    " CMake arguments
    unlet! t:cmake_toolchain
    unlet! t:cmake_cxx_compiler
    unlet! t:cmake_c_compiler
    unlet! t:cmake_cxx_flags
    unlet! t:cmake_c_flags
    unlet! t:cmake_generator
    unlet! t:cmake_build_type
    unlet! t:cmake_install_prefix
    unlet! t:cmake_export_compile_commands
    unlet! t:cmake_user_arguments
endfunction


function! MyCMake#GetArguments()
    " Get the CMake arguments from set variables
    let l:arguments = []

    if exists('t:cmake_toolchain')
        let l:file = fnameescape(t:cmake_toolchain)
        let arguments += ['-DCMAKE_TOOLCHAIN_FILE=' . l:file]
        unlet l:file
    endif

    if exists('t:cmake_cxx_compiler')
        let arguments += ['-DCMAKE_CXX_COMPILER=' . t:cmake_cxx_compiler]
    endif

    if exists('t:cmake_c_compiler')
        let arguments += ['-DCMAKE_C_COMPILER=' . t:cmake_c_compiler]
    endif

    if exists('t:cmake_cxx_flags')
        let l:flags = s:ToString(t:cmake_cxx_flags)
        let arguments += ["-DCMAKE_CXX_FLAGS=\'" . l:flags . "\'"]
        unlet l:flags
    endif

    if exists('t:cmake_c_flags')
        let l:flags = s:ToString(t:cmake_c_flags)
        let arguments += ["-DCMAKE_C_FLAGS=\'" . l:flags . "\'"]
        unlet l:flags
    endif

    if exists('t:cmake_generator')
        let arguments += ['-G' , "\'" . t:cmake_generator . "\'"]
    endif

    if exists('t:cmake_build_type')
        let arguments += ['-DCMAKE_BUILD_TYPE=' . t:cmake_build_type]
    endif

    if exists('t:cmake_install_prefix')
        let arguments += ['-DCMAKE_INSTALL_PREFIX=' . fnameescape(t:cmake_install_prefix)]
    endif

    if exists('t:cmake_export_compile_commands')
        if t:cmake_export_compile_commands
          let arguments += ['-DCMAKE_EXPORT_COMPILE_COMMANDS=ON']
        endif
    endif

    if exists('t:cmake_user_arguments')
        if type(t:cmake_user_arguments) == type([])
          let arguments += t:cmake_user_arguments
        else
          let arguments += [t:cmake_user_arguments]
        endif
    endif

    return arguments
endfunction


function! MyCMake#IsCMakeProject()
    if !exists('t:cmake_source_dir')
        return v:false
    endif

    if !exists('t:cmake_build_dir')
        return v:false
    endif

    return filereadable(t:cmake_source_dir . '/CMakeLists.txt')
endfunction


function! MyCMake#Configure()
    " Must be CMake project
    if !MyCMake#IsCMakeProject()
        echo 'Non-cmake project cannot be configured'
        return v:false
    endif

    " Create build dir if it does not exist
    call mkdir(t:cmake_build_dir, 'p')

    " Execute CMake
    let l:cmd = ['cmake']
    let l:cmd += ['-S', fnameescape(t:cmake_source_dir)]
    let l:cmd += ['-B', fnameescape(t:cmake_build_dir)]
    let l:cmd += MyCMake#GetArguments()

    return s:Execute(l:cmd)
endfunction


function! MyCMake#Build()
    return s:Execute('cmake --build ' . fnameescape(t:cmake_build_dir))
endfunction


function! MyCMake#SetMake()
    let &makeprg = 'cmake --build ' . fnameescape(t:project_build_dir) . ' --'
endfunction


function! MyCMake#Clean()
    " Must be CMake project
    if !MyCMake#IsCMakeProject()
        echo 'Non-cmake project cannot be cleaned'
        return v:false
    endif

    let l:out = v:true

    if !s:DeleteFile(t:cmake_build_dir . '/CMakeCache.txt')
        l:out = v:false
    endif

    if !s:DeleteFile(t:cmake_build_dir . '/CTestTestFile.txt')
        l:out = v:false
    endif

    return l:out
endfunction
