m4_include(`commons.m4')

_HEADER(`PE_patcher')
_HL1(`PE_patcher')

<p><i>PE_patcher</i> is a simple tool for patching PE executables</p>

<p>Usage:</p>

_PRE_BEGIN
PE_patcher.exe filename.exe address bytes
_PRE_END

<p>For example:</p>

_PRE_BEGIN
PE_patcher.exe filename.exe 0x401000 33C0C3
_PRE_END

<p>It can also be used in pair with my other utility: 
_HTML_LINK(`PE_search_str_refs.html',`PE_search_str_refs').</p>

<p>Download: _HTML_LINK(`utils/PE_patcher.exe',`win32 executable'), 
_HTML_LINK(`utils/PE_patcher64.exe',`win64 executable')</p>
<p>_HTML_LINK(`https://github.com/DennisYurichev/bolt/blob/master/PE_patcher.c',`Source code'). 
_HTML_LINK(`https://github.com/DennisYurichev/bolt',`Bolt library') in which this utility is incorporated</p>

_FOOTER()
