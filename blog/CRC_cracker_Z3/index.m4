m4_include(`commons.m4')

_HEADER_HL1(`Getting CRC polynomial and other CRC generator parameters using Z3')

<p>Sometimes CRC implementations are incompatible with each other: polynomial and other parameters can be different.
Aside of polynomial, initial state can be either 0 or -1, final value can be inverted or not, endianness of the final value can be changed or not.
Trying all these parameters by hand to match with someone's else implementation can be a real pain.
Also, you can bruteforce 32-bit polynomial, but 64-bit polynomials is too much.</p>

<p>Deducing all these parameters is surprisingly simple using Z3, just get two values for 01 byte and 02, or any other bytes.</p>

_PRE_BEGIN
m4_include(`blog/CRC_cracker_Z3/CRC_cracker.py')
_PRE_END

<p>This is for CRC-16:</p>

_PRE_BEGIN
poly=0xa001, init=0x0, XORout=0
_PRE_END

<p>Sometimes, we have no enough information, but still can get something. This is for CRC-16-CCITT</p>

_PRE_BEGIN
poly=0xb30f, init=0x0, XORout=-1
poly=0x7c07, init=0x0, XORout==0, ReflectOut=true
poly=0x8408, init=0x0, XORout==0, ReflectOut=true
_PRE_END

<p>One of these results is correct.</p>

<p>We can get something even if we have only one result for one input byte:</p>

_PRE_BEGIN
# recipe-259177-1.py, CRC-64-ISO
width=64
samples=["\x01"]
must_be=[0x01B0000000000000]
sample_len=1
_PRE_END

_PRE_BEGIN
poly=0x1fb12, init=0x0, XORout==0, ReflectOut=true
poly=0x1d24924924924924, init=0xffffffffffffffff, XORout=0
poly=0x86a9466cbb890d53, init=0x0, XORout=-1, ReflectOut=true
poly=0x580080, init=0x0, XORout==0, ReflectOut=true
poly=0xce9ce, init=0x0, XORout==0, ReflectOut=true
poly=0x53ffffffffffffff, init=0xffffffffffffffff, XORout=0
poly=0xd800000000000000, init=0x0, XORout=0
poly=0x38ad6, init=0x0, XORout==0, ReflectOut=true
poly=0x131e56e82623cae, init=0xffffffffffffffff, XORout==0, ReflectOut=true
poly=0x3fffffffffd3ffbf, init=0xffffffffffffffff, XORout==0, ReflectOut=true
poly=0x461861861861861, init=0xffffffffffffffff, XORout=0
total results 11
_PRE_END

<p>The files: _HTML_LINK_AS_IS(`https://github.com/dennis714/yurichev.com/tree/master/blog/CRC_cracker_Z3').</p>

<p>The shortcoming: longer samples slows down everything significantly.
I had luck with samples up to 4 bytes, but no larger.</p>

<p>Further reading I've found interesting/helpful:</p>

<ul>
<li>_HTML_LINK_AS_IS(`http://www.cosc.canterbury.ac.nz/greg.ewing/essays/CRC-Reverse-Engineering.html')
<li>_HTML_LINK_AS_IS(`http://reveng.sourceforge.net/crc-catalogue/1-15.htm')
<li>_HTML_LINK_AS_IS(`http://reveng.sourceforge.net/crc-catalogue/16.htm')
<li>_HTML_LINK_AS_IS(`http://reveng.sourceforge.net/crc-catalogue/17plus.htm')
</ul>

_BLOG_FOOTER()

