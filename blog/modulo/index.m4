m4_include(`commons.m4')

_HEADER_HL1(`13-Jun-2015: Modular arithmetic + division by multiplication + reversible LCG (PRNG) + cracking LCG with Z3.')

<p>Many practicing reverse engineerings are fully aware that division operation is sometimes replaced by multiplication.</p>

<p>Here is an example:</p>

<!--
_PRE_BEGIN
#include <stdint.h>

uint32_t divide_by_9 (uint32_t a)
{
        return a/9;
};
_PRE_END
-->
<pre style='color:#000000;background:#ffffff;'><span style='color:#004a43; '>#</span><span style='color:#004a43; '>include </span><span style='color:#800000; '>&lt;</span><span style='color:#40015a; '>stdint.h</span><span style='color:#800000; '>></span>

uint32_t divide_by_9 <span style='color:#808030; '>(</span>uint32_t a<span style='color:#808030; '>)</span>
<span style='color:#800080; '>{</span>
        <span style='color:#800000; font-weight:bold; '>return</span> a<span style='color:#808030; '>/</span><span style='color:#008c00; '>9</span><span style='color:#800080; '>;</span>
<span style='color:#800080; '>}</span><span style='color:#800080; '>;</span>
</pre>

<p>Optimizing GCC 4.8.2 does this:</p>

<!--
_PRE_BEGIN
divide_by_9:
        mov     edx, 954437177
        mov     eax, edx
        mul     DWORD PTR [esp+4]
        shr     edx
        mov     eax, edx
        ret
_PRE_END
-->
<pre style='color:#000000;background:#ffffff;'><span style='color:#e34adc; '>divide_by_9:</span>
        <span style='color:#800000; font-weight:bold; '>mov</span>     <span style='color:#000080; '>edx</span><span style='color:#808030; '>,</span> <span style='color:#008c00; '>954437177</span>
        <span style='color:#800000; font-weight:bold; '>mov</span>     <span style='color:#000080; '>eax</span><span style='color:#808030; '>,</span> <span style='color:#000080; '>edx</span>
        <span style='color:#800000; font-weight:bold; '>mul</span>     <span style='color:#800000; font-weight:bold; '>DWORD</span> <span style='color:#800000; font-weight:bold; '>PTR</span> <span style='color:#808030; '>[</span><span style='color:#000080; '>esp</span><span style='color:#808030; '>+</span><span style='color:#008c00; '>4</span><span style='color:#808030; '>]</span>
        <span style='color:#800000; font-weight:bold; '>shr</span>     <span style='color:#000080; '>edx</span>
        <span style='color:#800000; font-weight:bold; '>mov</span>     <span style='color:#000080; '>eax</span><span style='color:#808030; '>,</span> <span style='color:#000080; '>edx</span>
        <span style='color:#800000; font-weight:bold; '>ret</span>
</pre>

<p>The following code can be rewritten into C/C++:</p>

<!--
_PRE_BEGIN
#include <stdint.h>

uint32_t divide_by_9_v2 (uint32_t a)
{
        return ((uint64_t)a * (uint64_t)954437177) >> 33; // 954437177 = 0x38e38e39
};
_PRE_END
-->

<pre style='color:#000000;background:#ffffff;'><span style='color:#004a43; '>#</span><span style='color:#004a43; '>include </span><span style='color:#800000; '>&lt;</span><span style='color:#40015a; '>stdint.h</span><span style='color:#800000; '>></span>

uint32_t divide_by_9_v2 <span style='color:#808030; '>(</span>uint32_t a<span style='color:#808030; '>)</span>
<span style='color:#800080; '>{</span>
        <span style='color:#800000; font-weight:bold; '>return</span> <span style='color:#808030; '>(</span><span style='color:#808030; '>(</span>uint64_t<span style='color:#808030; '>)</span>a <span style='color:#808030; '>*</span> <span style='color:#808030; '>(</span>uint64_t<span style='color:#808030; '>)</span><span style='color:#008c00; '>954437177</span><span style='color:#808030; '>)</span> <span style='color:#808030; '>></span><span style='color:#808030; '>></span> <span style='color:#008c00; '>33</span><span style='color:#800080; '>;</span> <span style='color:#696969; '>// 954437177 = 0x38e38e39</span>
<span style='color:#800080; '>}</span><span style='color:#800080; '>;</span>
</pre>

<p>And it works: you can compile it and check it.
Let's see, how.</p>

_HL2(`Quick introduction into modular arithmetic')

<p>Modular arithmetic is an environment where all values are limited by some number (modulo).
Many textbooks has clock as example. Let's imagine old mechanical analog clock.
There hour hand points to one of number in bounds of 0..11 (zero is usually shown as 12).
What hour will be if to sum up 10 hours (no matter, AM or PM) and 4 hours?
10+4 is 14 or 2 by modulo 12.
Naively you can just sum up numbers and subtract modulo base (12) as long as it's possible.</p>

<p>Modern digital watch shows time in 24 hours format, so hour there is a variable in modulo base 24.
But minutes and seconds are in modulo 60 (let's forget about leap seconds for now).</p>

<p>Another example is US imperial system of measurement: human height is measured in feets and inches.
There are 12 inches in feet, so when you sum up some lengths, you increase feet variable each time you've got more than 12 inches.</p>

<p>Another example I would recall is password cracking utilities. Often, characters set is defined in such utilities.
And when you set all Latin characters plus numbers, you've got 26+10=36 characters in total.
If you brute-forcing a 6-characters password, you've got 6 variables, each is limited by 36.
And when you increase last variable, it happens in modular arithmetic rules: if you got 36, set last variable to 0 and increase penultimate
one. If it's also 36, do the same. If the very first variable is 36, then stop.
Modular arithmetic may be very helpful when you write multi-threading (or distributed) password cracking utility and you need to slice all passwords space by even
parts.</p>

<p>Now let's recall old mechanical counters which were widespread in pre-digital era:</p>

<center><img src="//yurichev.com/blog/modulo/counter.jpg" alt="The picture was stolen from http://www.featurepics.com/ - sorry for it!"></center>

<p>This counter has 6 wheels, so it can count from 0 to $10^{6}-1$ or 999999.
When you have 999999 and you increase the counter, it will resetting to 000000 - this situation is usually understood by engineers and computer programmers as overflow.
And if you have 000000 and you decrease it, the counter will show you 999999. This situation is often called "wrap around".
See also: _HTML_LINK_AS_IS(`http://en.wikipedia.org/wiki/Integer_overflow').</p>

_HL2(`Modular arithmetic on CPUs')

<p>The reason I talk about mechanical counter is that CPU registers acting in the very same way, because this is, perhaps, simplest possible and efficient way
to compute using integer numbers.</p>

<p>This implies that almost all operations on integer values on your CPU is happens by modulo $2^{32}$ or $2^{64}$ depending on your CPU.
For example, you can sum up 0x87654321 and 0xDEADBABA, which resulting in 0x16612FDDB. 
This value is too big for 32-bit register, so only 0x6612FDDB is stored, and leading 1 is dropped.
If you will multiply these two numbers, the actual result it 0x75C5B266EDA5BFFA, which is also too big, so only low 32-bit part is stored into destination
register: 0xEDA5BFFA. This is what happens when you multiply numbers in plain C/C++ language, but some readers may argue:
when sum is too big for register, CF (carry flag) is set, and it can be used after.
And there is x86 MUL instruction which in fact produces 64-bit result in 32-bit environment (in EDX:EAX registers pair).
That's true, but observing just 32-bit registers, this is exactly environment of modulo with base $2^{32}$.</p>

<p>Now that leads to surprising consequence: almost every result of arithmetic operation stored in general purpose register of 32-bit CPU is in fact
remainder of division operation: result is always divided by $2^{32}$ and remainder is left in register.
For example, 0x16612FDDB is too large for storage, and it's divided by $2^{32}$ (or 0x100000000).
The result of division (quotient) is 1 (which is dropped) and remainder is 0x6612FDDB (which is stored as a result).
0x75C5B266EDA5BFFA divided by $2^{32}$ (0x100000000) produces 0x75C5B266 as a result of division (quotient) and 0xEDA5BFFA as a remainder, the latter is stored.</p>

<p>And if your code is 32-bit one in 64-bit environment, CPU registers are bigger, so the whole result can be stored there, 
but high half is hidden behind the scenes -- because no 32-bit code can access it.</p>

<p>By the way, this is the reason why remainder calculation is often called "division by modulo".
C/C++ has percent sign (%) for this operation, but some other PLs like Pascal and Haskell has "mod" operator.</p>

<p>Usually, almost all sane computer programmers works with variables as they never wrapping around and value here is always in some limits which 
are defined preliminarily.
However, this implicit division operation or "wrapping around" can be exploited usefully.</p>

_HL2(`Remainder of division by modulo $2^{n}$')

<p>... can be easily computed with AND operation.
If you need a random number in range of 0..16, here you go: rand()&0xF.
That helps sometimes.</p>

<p>For example, you need a some kind of wrapping counter variable which always should be in 0..16 range. What you do?
Programmers often write this:</p>

<!--
_PRE_BEGIN
int counter=0;
...
counter++;
if (counter==16)
    counter=0;
_PRE_END
-->
<pre style='color:#000000;background:#ffffff;'><span style='color:#800000; font-weight:bold; '>int</span> counter<span style='color:#808030; '>=</span><span style='color:#008c00; '>0</span><span style='color:#800080; '>;</span>
<span style='color:#808030; '>.</span><span style='color:#808030; '>.</span><span style='color:#808030; '>.</span>
counter<span style='color:#808030; '>+</span><span style='color:#808030; '>+</span><span style='color:#800080; '>;</span>
<span style='color:#800000; font-weight:bold; '>if</span> <span style='color:#808030; '>(</span>counter<span style='color:#808030; '>=</span><span style='color:#808030; '>=</span><span style='color:#008c00; '>16</span><span style='color:#808030; '>)</span>
    counter<span style='color:#808030; '>=</span><span style='color:#008c00; '>0</span><span style='color:#800080; '>;</span>
</pre>

<p>But here is a version without conditional branching:</p>

<!--
_PRE_BEGIN
int counter=0;
...
counter++;
counter=counter&0xF;
_PRE_END
-->
<pre style='color:#000000;background:#ffffff;'><span style='color:#800000; font-weight:bold; '>int</span> counter<span style='color:#808030; '>=</span><span style='color:#008c00; '>0</span><span style='color:#800080; '>;</span>
<span style='color:#808030; '>.</span><span style='color:#808030; '>.</span><span style='color:#808030; '>.</span>
counter<span style='color:#808030; '>+</span><span style='color:#808030; '>+</span><span style='color:#800080; '>;</span>
counter<span style='color:#808030; '>=</span>counter<span style='color:#808030; '>&amp;</span><span style='color:#008000; '>0xF</span><span style='color:#800080; '>;</span>
</pre>

<p>As an example, this I found in the git source code:</p>

<!--
_PRE_BEGIN
char *sha1_to_hex(const unsigned char *sha1)
{
	static int bufno;
	static char hexbuffer[4][GIT_SHA1_HEXSZ + 1];
	static const char hex[] = "0123456789abcdef";
	char *buffer = hexbuffer[3 & ++bufno], *buf = buffer;
	int i;

	for (i = 0; i < GIT_SHA1_RAWSZ; i++) {
		unsigned int val = *sha1++;
		*buf++ = hex[val >> 4];
		*buf++ = hex[val & 0xf];
	}
	*buf = '\0';

	return buffer;
}
_PRE_END
-->
<pre style='color:#000000;background:#ffffff;'><span style='color:#800000; font-weight:bold; '>char</span> <span style='color:#808030; '>*</span>sha1_to_hex<span style='color:#808030; '>(</span><span style='color:#800000; font-weight:bold; '>const</span> <span style='color:#800000; font-weight:bold; '>unsigned</span> <span style='color:#800000; font-weight:bold; '>char</span> <span style='color:#808030; '>*</span>sha1<span style='color:#808030; '>)</span>
<span style='color:#800080; '>{</span>
	<span style='color:#800000; font-weight:bold; '>static</span> <span style='color:#800000; font-weight:bold; '>int</span> bufno<span style='color:#800080; '>;</span>
	<span style='color:#800000; font-weight:bold; '>static</span> <span style='color:#800000; font-weight:bold; '>char</span> hexbuffer<span style='color:#808030; '>[</span><span style='color:#008c00; '>4</span><span style='color:#808030; '>]</span><span style='color:#808030; '>[</span>GIT_SHA1_HEXSZ <span style='color:#808030; '>+</span> <span style='color:#008c00; '>1</span><span style='color:#808030; '>]</span><span style='color:#800080; '>;</span>
	<span style='color:#800000; font-weight:bold; '>static</span> <span style='color:#800000; font-weight:bold; '>const</span> <span style='color:#800000; font-weight:bold; '>char</span> hex<span style='color:#808030; '>[</span><span style='color:#808030; '>]</span> <span style='color:#808030; '>=</span> <span style='color:#800000; '>"</span><span style='color:#0000e6; '>0123456789abcdef</span><span style='color:#800000; '>"</span><span style='color:#800080; '>;</span>
	<span style='color:#800000; font-weight:bold; '>char</span> <span style='color:#808030; '>*</span>buffer <span style='color:#808030; '>=</span> hexbuffer<span style='color:#808030; '>[</span><span style='color:#008c00; '>3</span> <span style='color:#808030; '>&amp;</span> <span style='color:#808030; '>+</span><span style='color:#808030; '>+</span>bufno<span style='color:#808030; '>]</span><span style='color:#808030; '>,</span> <span style='color:#808030; '>*</span>buf <span style='color:#808030; '>=</span> buffer<span style='color:#800080; '>;</span>
	<span style='color:#800000; font-weight:bold; '>int</span> i<span style='color:#800080; '>;</span>

	<span style='color:#800000; font-weight:bold; '>for</span> <span style='color:#808030; '>(</span>i <span style='color:#808030; '>=</span> <span style='color:#008c00; '>0</span><span style='color:#800080; '>;</span> i <span style='color:#808030; '>&lt;</span> GIT_SHA1_RAWSZ<span style='color:#800080; '>;</span> i<span style='color:#808030; '>+</span><span style='color:#808030; '>+</span><span style='color:#808030; '>)</span> <span style='color:#800080; '>{</span>
		<span style='color:#800000; font-weight:bold; '>unsigned</span> <span style='color:#800000; font-weight:bold; '>int</span> val <span style='color:#808030; '>=</span> <span style='color:#808030; '>*</span>sha1<span style='color:#808030; '>+</span><span style='color:#808030; '>+</span><span style='color:#800080; '>;</span>
		<span style='color:#808030; '>*</span>buf<span style='color:#808030; '>+</span><span style='color:#808030; '>+</span> <span style='color:#808030; '>=</span> hex<span style='color:#808030; '>[</span>val <span style='color:#808030; '>></span><span style='color:#808030; '>></span> <span style='color:#008c00; '>4</span><span style='color:#808030; '>]</span><span style='color:#800080; '>;</span>
		<span style='color:#808030; '>*</span>buf<span style='color:#808030; '>+</span><span style='color:#808030; '>+</span> <span style='color:#808030; '>=</span> hex<span style='color:#808030; '>[</span>val <span style='color:#808030; '>&amp;</span> <span style='color:#008000; '>0xf</span><span style='color:#808030; '>]</span><span style='color:#800080; '>;</span>
	<span style='color:#800080; '>}</span>
	<span style='color:#808030; '>*</span>buf <span style='color:#808030; '>=</span> <span style='color:#0000e6; '>'\0'</span><span style='color:#800080; '>;</span>

	<span style='color:#800000; font-weight:bold; '>return</span> buffer<span style='color:#800080; '>;</span>
<span style='color:#800080; '>}</span>
</pre>

( _HTML_LINK_AS_IS(`https://github.com/git/git/blob/aa1c6fdf478c023180e5ca5f1658b00a72592dc6/hex.c') )

<p>This function returns a pointer to the string containing hexadecimal representation of SHA1 digest (like "4e1243bd22c66e76c2ba9eddc1f91394e57f9f83").
But this is plain C and you can calculate SHA1 for some block, get pointer to the string, then calculate SHA1 for another block, get pointer to the string,
and both pointers are still points to the same string buffer containing the result of the second calculation.
As a solution, it's possible to allocate/deallocate string buffer each time, but more hackish way is to have several buffers (4 are here) and fill the next each time.
The <i>bufno</i> variable here is a buffer counter in 0..3 range. Its value increments each time, and its value is also always kept in limits
by AND operation (<i>3 & ++bufno</i>).</p>

<p>The author of this piece of code (seemingly Linus Torvalds himself) went even further and forgot (?) to initialize <i>bufno</i> counter variable, which will
have random garbage at the function start.
Indeed: no matter, which buffer we are starting each time!
This can be mistake which isn't affect correctness of the code, or maybe this is left so intentionally -- I don't know.</p>

_HL2(`Getting random numbers')

<p>When you write some kind of videogame, you need random numbers, and the standard C/C++ rand() function gives you them in 0..0x7FFF range (MSVC)
or in 0..0x7FFFFFFF range (GCC).
And when you need a random number in 0..10 range, the common way to do it is:</p>

_PRE_BEGIN
X_coord_of_something_spawned_somewhere=rand() % 10;
Y_coord_of_something_spawned_somewhere=rand() % 10;
_PRE_END

<p>No matter what compiler do you use, you can think about it as 10 is subtraced from rand() result, as long as there is still a number bigger than 10.
Hence, result is remainder of division of rand() result by 10.</p>

<p>One nasty consequence is that neither 0x8000 nor 0x80000000 cannot be divided by 10 evenly, so you'll get some numbers slightly more often than others.</p>

<p>I tried to calculate in Mathematica. Here is what you get if you write <i>rand() % 3</i> and rand() produce numbers in range of 0..0x7FFF (like MSVC):</p>

_PRE_BEGIN
In[]:= Counts[Map[Mod[#, 3] &, Range[0, 16^^8000 - 1]]]
Out[]= <|0 -> 10923, 1 -> 10923, 2 -> 10922|>
_PRE_END

<p>So number 2 happens slightly seldom than others.</p>

<p>Here is a result for <i>rand() % 10</i>:</p>

_PRE_BEGIN
In[]:= Counts[Map[Mod[#, 10] &, Range[0, 16^^8000 - 1]]]
Out[]= <|0 -> 3277, 1 -> 3277, 2 -> 3277, 3 -> 3277, 4 -> 3277, 
 5 -> 3277, 6 -> 3277, 7 -> 3277, 8 -> 3276, 9 -> 3276|>
_PRE_END

<p>Numbers 8 and 9 happens slightly seldom.</p>

<p>Here is a result for <i>rand() % 100</i>:</p>

_PRE_BEGIN
In[]:= Counts[Map[Mod[#, 100] &, Range[0, 16^^8000 - 1]]]
Out[]= <|0 -> 328, 1 -> 328, 2 -> 328, 3 -> 328, 4 -> 328, 5 -> 328,
  6 -> 328, 7 -> 328, 8 -> 328, 9 -> 328, 10 -> 328, 11 -> 328, 
 12 -> 328, 13 -> 328, 14 -> 328, 15 -> 328, 16 -> 328, 17 -> 328, 
 18 -> 328, 19 -> 328, 20 -> 328, 21 -> 328, 22 -> 328, 23 -> 328, 
 24 -> 328, 25 -> 328, 26 -> 328, 27 -> 328, 28 -> 328, 29 -> 328, 
 30 -> 328, 31 -> 328, 32 -> 328, 33 -> 328, 34 -> 328, 35 -> 328, 
 36 -> 328, 37 -> 328, 38 -> 328, 39 -> 328, 40 -> 328, 41 -> 328, 
 42 -> 328, 43 -> 328, 44 -> 328, 45 -> 328, 46 -> 328, 47 -> 328, 
 48 -> 328, 49 -> 328, 50 -> 328, 51 -> 328, 52 -> 328, 53 -> 328, 
 54 -> 328, 55 -> 328, 56 -> 328, 57 -> 328, 58 -> 328, 59 -> 328, 
 60 -> 328, 61 -> 328, 62 -> 328, 63 -> 328, 64 -> 328, 65 -> 328, 
 66 -> 328, 67 -> 328, 68 -> 327, 69 -> 327, 70 -> 327, 71 -> 327, 
 72 -> 327, 73 -> 327, 74 -> 327, 75 -> 327, 76 -> 327, 77 -> 327, 
 78 -> 327, 79 -> 327, 80 -> 327, 81 -> 327, 82 -> 327, 83 -> 327, 
 84 -> 327, 85 -> 327, 86 -> 327, 87 -> 327, 88 -> 327, 89 -> 327, 
 90 -> 327, 91 -> 327, 92 -> 327, 93 -> 327, 94 -> 327, 95 -> 327, 
 96 -> 327, 97 -> 327, 98 -> 327, 99 -> 327|>
_PRE_END

<p>... now larger part of numbers happens slightly seldom, these are 68...99.</p>

<p>This is sometimes called <i>modulo bias</i>. It's perhaps acceptable for videogames, but may be critical for scientific simulations, including Monte Carlo method.</p>

<p>Constructing a PRNG with uniform distribution may be tricky, there are couple of methods: 
_HTML_LINK(`http://www.reddit.com/r/algorithms/comments/39tire/using_a_01_generator_generate_a_random_number/',`1'),
_HTML_LINK(`http://www.prismmodelchecker.org/casestudies/dice.php',`2').</p>

_HL2(`Multiplicative inverse')

_HL3(`Finding multiplicative inverse')

<p>From school-level mathematics we may recall there is an easy way to replace multiplication by division.
For example, if you need to divide some number by 3, multiply it by $\frac{1}{3}$ (or 0.33333...).
So if you've got a lot of numbers you need to divide by 3, and if multiplication on your FPU works faster than division, you can precompute $\frac{1}{3}$ and then 
multiply all numbers by this one.
$\frac{1}{3}$ is called <i>multiplicative inverse</i> or <i>reciprocal</i>.
Russian textbook also uses more terse <i>inverse number</i> or <i>inverse value</i> term.</p>

<p>But that works for real numbers only. What about integer ones?</p>

_HL3(`Finding modular multiplicative inverse')

<p>First, let's state our task: we need to divide <i>a</i> (unknown at compile time) number by 9.</p>

<p>Our environment has at least these properties:</p>

<ul>
<li> multiplication is fast;
<li> division by $2^{32}$ consumes nothing;
<li> finding remainder of division by $2^{32}$ is also consumes nothing;
<li> division by $2^{n}$ is very fast (binary shift right);
<li> division by other numbers is slow.
</ul>

<p>We can't divide by 9 using bit shifts, but we can divide by $2^{32}$ or by $2^{n}$ in general.
What if we would multiply input number to make it much bigger so to compensate difference between 9 and $2^{32}$?
Yes!</p>

<p>Our initial task is:</p>

_PRE_BEGIN
result = input / 9
_PRE_END

<p>What we can do:</p>

_PRE_BEGIN
result = input * coefficient / 2^32
_PRE_END

<p><i>coefficient</i> is the solution of this equation:</p>

_PRE_BEGIN
9x = 1+k(2^32).
_PRE_END

<p>We can solve it in Wolfram Mathematica:</p>

_PRE_BEGIN
In[]= FindInstance[9 x == 1 + k (2^32), {x, k}, Integers]
Out[]= {{x -> 954437177, k -> 2}}
_PRE_END

<p><i>x</i> (which is modular multiplicative inverse) will be coefficient, <i>k</i> will be another special value, used at the very end.</p>

<p>Let's check it in Mathematica:</p>

_PRE_BEGIN
In[]:= BaseForm[954437177*90, 16]
Out[]//BaseForm= 140000000a
_PRE_END

<p>(BaseForm is the instruction to print result in hexadecimal form).</p>

<p>It has been multiplication, but division by $2^{32}$ or $2^{n}$ is not happened yet.
So after division by $2^{32}$, 0x14 will be a result and 0xA is remainder.
0x14 is 20, which twice as large as the result we expect ($\frac{90}{9}$=10).
It's because k=2, so final result should also be divided by 2.</p>

<p>That is exactly what the code produced by GCC does:</p>

<ul>
<li> input value is multiplicated by 954437177 (x);
<li> then it is divided by $2^{32}$ using quick bit shift right;
<li> final value is divided by 2 (k).
</ul>

<p>Two last steps are coalesced into one SHR instruction, which does shifting by 33 bits.</p>

<p>Let's also check relation between modular multiplicative inverse coefficient we've got and $2^{32}$ (modulo base):</p>

_PRE_BEGIN
In[]:= 954437177 / 2^32 // N
Out[]= 0.222222
_PRE_END

<p>0.222... is twice as large than $\frac{1}{9}$.
So this number acting like a real $\frac{1}{9}$ number, but on integer <acronym title="Arithmetic logic unit">ALU</acronym>!</p>

_HL3(`A little more theory')

<p>But why _HTML_LINK(`http://en.wikipedia.org/wiki/Modular_multiplicative_inverse',`Wikipedia article about it') is somewhat harder to grasp?
And why we need additional <i>k</i> coefficient?
The reason of this is because equation we should solve to get coefficients is in fact diophantine equation, that is equation
which allows only integers as it's variables.
Hence you see "Integers" in FindInstance Mathematica command: no real numbers are allowed.
Mathematica wouldn't be able to find <i>x</i> for k=1 (additional bit shift would not need then), but was able to find it for k=2.
Diophantine equation is so important here because we work on integer ALU, after all.</p>

<p>So the coefficient used is in fact modular multiplicative inverse.
And when you see such piece of code in some software, Mathematica can find division number easily, just find modular multiplicative inverse of modular
multiplicative inverse!
It works because $x=\frac{1}{(\frac{1}{x})}$.</p>

_PRE_BEGIN
In[]:= PowerMod[954437177, -1, 2^32]
Out[]= 9
_PRE_END

<p>PowerMod command is so called because it computes $x^{-1}$ by given modulo ($2^{32}$), which is the same thing.
Other representations of this algorithm are there: _HTML_LINK_AS_IS(`http://rosettacode.org/wiki/Modular_inverse').</p>

<p>So, multiplicative inverse is denoted as $x^{-1}$ and modular multiplicative inverse as $x^{-1} \pmod b$ where b is modulo base.</p>

_HL3(`Remainder?')

<p>It can be easily observed that no bit shifting need, just multiply number by modular inverse:</p>

_PRE_BEGIN
In[]:= Mod[954437177*18, 2^32]
Out[]= 2
_PRE_END

<p>The number we've got is in fact remainder of division by $2^{32}$.
It is the same as result we are looking for, because diophantine equation we solved has 1 in "1+k...", this 1 is multiplied by result and it is left
as remainder.</p>

<p>This is somewhat useless, because this calculation is going crazy when we need to divide some number (like 19) by 9 ($\frac{19}{9}=2.111...$), which should leave remainder (19 % 9 = 1):</p>

_PRE_BEGIN
In[]:= Mod[954437177*19, 2^32]
Out[]= 954437179
_PRE_END

<p>Perhaps, this can be used to detect situations when remainder is also present?</p>

_HL3(`Always coprimes?')

<p>As it's stated in many textbooks, to find modular multiplicative inverse, modulo base ($2^{32}$) and initial value (e.g., 9) 
should be _HTML_LINK(`http://en.wikipedia.org/wiki/Coprime_integers',`coprime') to each other.
9 is coprime to $2^{32}$, so is 7, but not 10.
But if you try to compile $\frac{x}{10}$ code, GCC can do it as well:</p>

<!--
_PRE_BEGIN
push   %ebp
mov    %esp,%ebp
mov    0x8(%ebp),%eax
mov    $0xcccccccd,%edx
mul    %edx
mov    %edx,%eax
shr    $0x3,%eax
pop    %ebp
ret    
_PRE_END
-->

<pre style='color:#000000;background:#ffffff;'><span style='color:#800000; font-weight:bold; '>push</span>   <span style='color:#808030; '>%</span><span style='color:#000080; '>ebp</span>
<span style='color:#800000; font-weight:bold; '>mov</span>    <span style='color:#808030; '>%</span><span style='color:#000080; '>esp</span><span style='color:#808030; '>,</span><span style='color:#808030; '>%</span><span style='color:#000080; '>ebp</span>
<span style='color:#800000; font-weight:bold; '>mov</span>    <span style='color:#008000; '>0x8</span><span style='color:#808030; '>(</span><span style='color:#808030; '>%</span><span style='color:#000080; '>ebp</span><span style='color:#808030; '>)</span><span style='color:#808030; '>,</span><span style='color:#808030; '>%</span><span style='color:#000080; '>eax</span>
<span style='color:#800000; font-weight:bold; '>mov</span>    $<span style='color:#008000; '>0xcccccccd</span><span style='color:#808030; '>,</span><span style='color:#808030; '>%</span><span style='color:#000080; '>edx</span>
<span style='color:#800000; font-weight:bold; '>mul</span>    <span style='color:#808030; '>%</span><span style='color:#000080; '>edx</span>
<span style='color:#800000; font-weight:bold; '>mov</span>    <span style='color:#808030; '>%</span><span style='color:#000080; '>edx</span><span style='color:#808030; '>,</span><span style='color:#808030; '>%</span><span style='color:#000080; '>eax</span>
<span style='color:#800000; font-weight:bold; '>shr</span>    $<span style='color:#008000; '>0x3</span><span style='color:#808030; '>,</span><span style='color:#808030; '>%</span><span style='color:#000080; '>eax</span>
<span style='color:#800000; font-weight:bold; '>pop</span>    <span style='color:#808030; '>%</span><span style='color:#000080; '>ebp</span>
<span style='color:#800000; font-weight:bold; '>ret</span>
</pre>
<p>The reason it works is because division by 5 is actually happens here (and 5 is coprime to $2^{32}$), and then the final result is divided by 2
(so there is 3 instead of 2 in the SHR instruction).</p>

_HL2(`Reversible linear congruential generator')

<p><acronym title="Linear congruential generator">LCG</acronym> is very simple: just multiply seed by some value, add another one and here is a new random number.
Here is how it is implemented in MSVC (the source code is not original one and is reconstructed by me):</p>

<!--
_PRE_BEGIN
uint32_t state;

uint32_t rand()
{
	state=state*214013+2531011;
	return (state>>16)&0x7FFF;
};
_PRE_END
-->
<pre style='color:#000000;background:#ffffff;'>uint32_t state<span style='color:#800080; '>;</span>

uint32_t <span style='color:#603000; '>rand</span><span style='color:#808030; '>(</span><span style='color:#808030; '>)</span>
<span style='color:#800080; '>{</span>
	state<span style='color:#808030; '>=</span>state<span style='color:#808030; '>*</span><span style='color:#008c00; '>214013</span><span style='color:#808030; '>+</span><span style='color:#008c00; '>2531011</span><span style='color:#800080; '>;</span>
	<span style='color:#800000; font-weight:bold; '>return</span> <span style='color:#808030; '>(</span>state<span style='color:#808030; '>></span><span style='color:#808030; '>></span><span style='color:#008c00; '>16</span><span style='color:#808030; '>)</span><span style='color:#808030; '>&amp;</span><span style='color:#008000; '>0x7FFF</span><span style='color:#800080; '>;</span>
<span style='color:#800080; '>}</span><span style='color:#800080; '>;</span>
</pre>

<p>The last bit shift is attempt to compensate LCG weakness and we may ignore it so far.
Will it be possible to make an inverse function to rand(), which can reverse state back?
First, let's try to think, what would make this possible? Well, if state internal variable would be some kind of BigInt or BigNum container which can
store infinitely big numbers, then, although state is increasing rapidly, it would be possible to reverse the process.
But <i>state</i> isn't BigInt/BigNum, it's 32-bit variable, and summing operation is easily reversible on it (just subtract 2531011 at each step).
As we may know now, multiplication is also reversible: just multiply the state by modular multiplicative inverse of 214013!</p>

<!--
_PRE_BEGIN
#include <stdio.h>
#include <stdint.h>

uint32_t state;

void next_state()
{
	state=state*214013+2531011;
};

void prev_state()
{
	state=state-2531011; // reverse summing operation
	state=state*3115528533; // reverse multiply operation. 3115528533 is modular inverse of 214013 in 2^32.
};

int main()
{
	state=12345;
	
	printf ("state=%d\n", state);
	next_state();
	printf ("state=%d\n", state);
	next_state();
	printf ("state=%d\n", state);
	next_state();
	printf ("state=%d\n", state);

	prev_state();
	printf ("state=%d\n", state);
	prev_state();
	printf ("state=%d\n", state);
	prev_state();
	printf ("state=%d\n", state);
};
_PRE_END
-->
<pre style='color:#000000;background:#ffffff;'><span style='color:#004a43; '>#</span><span style='color:#004a43; '>include </span><span style='color:#800000; '>&lt;</span><span style='color:#40015a; '>stdio.h</span><span style='color:#800000; '>></span>
<span style='color:#004a43; '>#</span><span style='color:#004a43; '>include </span><span style='color:#800000; '>&lt;</span><span style='color:#40015a; '>stdint.h</span><span style='color:#800000; '>></span>

uint32_t state<span style='color:#800080; '>;</span>

<span style='color:#800000; font-weight:bold; '>void</span> next_state<span style='color:#808030; '>(</span><span style='color:#808030; '>)</span>
<span style='color:#800080; '>{</span>
	state<span style='color:#808030; '>=</span>state<span style='color:#808030; '>*</span><span style='color:#008c00; '>214013</span><span style='color:#808030; '>+</span><span style='color:#008c00; '>2531011</span><span style='color:#800080; '>;</span>
<span style='color:#800080; '>}</span><span style='color:#800080; '>;</span>

<span style='color:#800000; font-weight:bold; '>void</span> prev_state<span style='color:#808030; '>(</span><span style='color:#808030; '>)</span>
<span style='color:#800080; '>{</span>
	state<span style='color:#808030; '>=</span>state<span style='color:#808030; '>-</span><span style='color:#008c00; '>2531011</span><span style='color:#800080; '>;</span> <span style='color:#696969; '>// reverse summing operation</span>
	state<span style='color:#808030; '>=</span>state<span style='color:#808030; '>*</span><span style='color:#008c00; '>3115528533</span><span style='color:#800080; '>;</span> <span style='color:#696969; '>// reverse multiply operation. 3115528533 is modular inverse of 214013 in 2^32.</span>
<span style='color:#800080; '>}</span><span style='color:#800080; '>;</span>

<span style='color:#800000; font-weight:bold; '>int</span> <span style='color:#400000; '>main</span><span style='color:#808030; '>(</span><span style='color:#808030; '>)</span>
<span style='color:#800080; '>{</span>
	state<span style='color:#808030; '>=</span><span style='color:#008c00; '>12345</span><span style='color:#800080; '>;</span>
	
	<span style='color:#603000; '>printf</span> <span style='color:#808030; '>(</span><span style='color:#800000; '>"</span><span style='color:#0000e6; '>state=</span><span style='color:#007997; '>%d</span><span style='color:#0f69ff; '>\n</span><span style='color:#800000; '>"</span><span style='color:#808030; '>,</span> state<span style='color:#808030; '>)</span><span style='color:#800080; '>;</span>
	next_state<span style='color:#808030; '>(</span><span style='color:#808030; '>)</span><span style='color:#800080; '>;</span>
	<span style='color:#603000; '>printf</span> <span style='color:#808030; '>(</span><span style='color:#800000; '>"</span><span style='color:#0000e6; '>state=</span><span style='color:#007997; '>%d</span><span style='color:#0f69ff; '>\n</span><span style='color:#800000; '>"</span><span style='color:#808030; '>,</span> state<span style='color:#808030; '>)</span><span style='color:#800080; '>;</span>
	next_state<span style='color:#808030; '>(</span><span style='color:#808030; '>)</span><span style='color:#800080; '>;</span>
	<span style='color:#603000; '>printf</span> <span style='color:#808030; '>(</span><span style='color:#800000; '>"</span><span style='color:#0000e6; '>state=</span><span style='color:#007997; '>%d</span><span style='color:#0f69ff; '>\n</span><span style='color:#800000; '>"</span><span style='color:#808030; '>,</span> state<span style='color:#808030; '>)</span><span style='color:#800080; '>;</span>
	next_state<span style='color:#808030; '>(</span><span style='color:#808030; '>)</span><span style='color:#800080; '>;</span>
	<span style='color:#603000; '>printf</span> <span style='color:#808030; '>(</span><span style='color:#800000; '>"</span><span style='color:#0000e6; '>state=</span><span style='color:#007997; '>%d</span><span style='color:#0f69ff; '>\n</span><span style='color:#800000; '>"</span><span style='color:#808030; '>,</span> state<span style='color:#808030; '>)</span><span style='color:#800080; '>;</span>

	prev_state<span style='color:#808030; '>(</span><span style='color:#808030; '>)</span><span style='color:#800080; '>;</span>
	<span style='color:#603000; '>printf</span> <span style='color:#808030; '>(</span><span style='color:#800000; '>"</span><span style='color:#0000e6; '>state=</span><span style='color:#007997; '>%d</span><span style='color:#0f69ff; '>\n</span><span style='color:#800000; '>"</span><span style='color:#808030; '>,</span> state<span style='color:#808030; '>)</span><span style='color:#800080; '>;</span>
	prev_state<span style='color:#808030; '>(</span><span style='color:#808030; '>)</span><span style='color:#800080; '>;</span>
	<span style='color:#603000; '>printf</span> <span style='color:#808030; '>(</span><span style='color:#800000; '>"</span><span style='color:#0000e6; '>state=</span><span style='color:#007997; '>%d</span><span style='color:#0f69ff; '>\n</span><span style='color:#800000; '>"</span><span style='color:#808030; '>,</span> state<span style='color:#808030; '>)</span><span style='color:#800080; '>;</span>
	prev_state<span style='color:#808030; '>(</span><span style='color:#808030; '>)</span><span style='color:#800080; '>;</span>
	<span style='color:#603000; '>printf</span> <span style='color:#808030; '>(</span><span style='color:#800000; '>"</span><span style='color:#0000e6; '>state=</span><span style='color:#007997; '>%d</span><span style='color:#0f69ff; '>\n</span><span style='color:#800000; '>"</span><span style='color:#808030; '>,</span> state<span style='color:#808030; '>)</span><span style='color:#800080; '>;</span>
<span style='color:#800080; '>}</span><span style='color:#800080; '>;</span>
</pre>

<p>Wow, that works!</p>

_PRE_BEGIN
state=12345
state=-1650445800
state=1255958651
state=-456978094
state=1255958651
state=-1650445800
state=12345
_PRE_END

<p>It's very hard to find a real-world application of reversible LCG, but it was a spectacular demonstration of modular multiplicative inverse, so I added it.</p>

_HL2(`Cracking LCG with Z3 SMT solver')

<p>... the text which was here has been moved to _HTML_LINK_AS_IS(`https://yurichev.com/writings/SAT_SMT_draft-EN.pdf').</p>

_HL2(`RSA')

<p>Modular arithmetic is also used in RSA algorithm in its core.
I've written an article about it: _HTML_LINK_AS_IS(`//yurichev.com/blog/RSA/').</p>

_BLOG_FOOTER()
