.. _tutorial:

=====================
Tutorial and Examples
=====================





Meryl processing is built around 'actions'.  An action can count the kmers in
a sequence file creating a meryl database for future use, combine multiple
databases into one, filter kmers in a single database by value or label, or
modify the labels of kmers in a single database.  Actions can be chained together
in a processing tree and evaluated in a single invocation of meryl.

Some examples of what this can accomplish:

1) Count the 22-mers in two sequence files, discard the unique kmers and
   output the rest to a database.

   .. code-block:: shell

     meryl \
     output kmers.meryl \
     greater-than 1 \
     count \
       k=22 \
       sequences.fasta.gz

2) Output kmers with a value at least 10 that exists in 2 out of 4 input
   databases.  Notice that the size of the k-mer ('k=22') does not need to be
   supplied as it is implicit in the input databases.

   .. code-block:: shell

      meryl \
      present-in:2 \
        [filter value:>=10 a.meryl] \
        [filter value:>=10 b.meryl] \
        [filter value:>=10 c.meryl] \
        [filter value:>=10 d.meryl]

3) You can also count the k-mers in the same command.  Since the 'count'
   action doesn't know what k-mer size to use, we must again supply it.

   .. code-block:: shell

      meryl \
      k=22 \
      present-in:2 \
        [filter value:>=10 count a.meryl] \
        [filter value:>=10 count b.meryl] \
        [filter value:>=10 count c.meryl] \
        [filter value:>=10 count d.meryl]

3) Output a k-mer if it exists in at least three databases with count greater
   than 100, but output the minimum count the kmer has in any input database.

   .. code-block:: shell

      meryl \
      present-in:2 value:min \        #  action-1
        [present-in:any value:min \   #  action-2
          a.meryl \
          b.meryl \
          c.meryl \
          d.meryl \
          e.meryl \
        ] \
        [present-in:3 \               # action-3
          [filter value:>100 a.meryl] \
          [filter value:>100 b.meryl] \
          [filter value:>100 c.meryl] \
          [filter value:>100 d.meryl] \
          [filter value:>100 e.meryl] \
        ]

   As the comments hint, there are three actions.

     **action-1** has two inputs, 'action-2' and 'action-3'.  It requires that
     kmers be present in exactly two inputs and sets the value to
     the minimum value in any input.

     **action-2** has five inputs, all from meryl databases.  It outputs a kmer
     if it exists in any input and sets the value to the minimum
     value in any input.

     **action-3** has five inputs, each from another action.  It outputs a kmer
     if it exists in exactly three inputs, the value assigned to the
     output kmer isn't specified and will default to [....].  Each
     of the five inputs is an action that outputs only kmers whose
     value greater than 100.


=======
Actions
=======

A single meryl action is specified as:

.. code-block:: shell

  [action 
     output=<database.meryl>
     print=<file.mers | files.##.mers | stdout>
     value:value_option
     label:label_option
     input1
     input2
     ... ]

There are four primary actions:

+-----------+----------------------------------------------------------------+
|count      | create a meryl database from FASTA or FASTQ inputs             |
+-----------+----------------------------------------------------------------+
|filter     | select kmers based on their value of label from a single input |
+-----------+----------------------------------------------------------------+
|modify     | change kmer values or labels in a single input                 |
+-----------+----------------------------------------------------------------+
|present-in | combine multiple inputs into one output                        |
+-----------+----------------------------------------------------------------+

These four actions are described in detail later.  For now, just rembmer that
an action processes multiple input databases (or sequence inputs, for 'count')
into exactly one output database.

Output Modifier
---------------

If present, the 'output' modifier will write the kmers generated by this
action to the specified meryl database.  The database will be created if it
doesn't exist, or erased if it does exist.  The kmers will also be supplied
to any actions using this action as an input.

'count' actions currently require an output database.

Print Modifier
--------------

If present, the 'print' modifier will write the kmers generated by this
action, one kmer per line, to the specified text file in the format

.. code-block:: shell

  <kmer> <tab> <value> <tab> <label>

The kmers will be in sorted order: ``A`` < ``C`` < ``T`` < ``G``.  Kmers will
be canonical, unless the input database (or 'count' action) has explicitly
specified otherwise (with count-forward or count-reverse).

If the file name includes the string '##', the data will be written to 64
files, in parallel, using up to 64 threads, replacing '##' with a value
between '00' and '63', inclusive.

'print=stdout' is the same as 'print' but writes the output to the screen.

'printACGT' is the same as 'print', but modifies the ordering of kmers from
``A < C < T < G`` to ``A < C < G < T`` when forming canonical kmers.  While
this generates correct canonical kmers, the output kmers are not sorted.

Consider 3-mers from string ``GGAGAGCT``:

 +------------+---------+---------+---------------------------+
 |            |         |         |     canonical kmer in     |
 |            |         |         +-------------+-------------+
 | ``GGAGCT`` | forward | reverse |  ACTG order |  ACGT order |
 +------------+---------+---------+-------------+-------------+
 | ``GGA...`` | ``GGA`` | ``TCC`` |   ``TCC``   |   ``GGA``   |
 +------------+---------+---------+-------------+-------------+
 | ``.GAG..`` | ``GAG`` | ``CTC`` |   ``CTC``   |   ``CTC``   |
 +------------+---------+---------+-------------+-------------+
 | ``..AGC.`` | ``AGC`` | ``GCT`` |   ``AGC``   |   ``AGC``   |
 +------------+---------+---------+-------------+-------------+
 | ``...GCT`` | ``GCT`` | ``AGC`` |   ``AGC``   |   ``AGC``   |
 +------------+---------+---------+-------------+-------------+

When meryl builds the datase, it uses the ``A < C < T < G`` order.  These
kmers will be stored in the database in order: ``AGC``, ``CTC``, ``TCC``,
``GCT``.  But when output using **printACGT**, the kmers will be reported as
``AGC``, ``CTC``, ``GGA``, ``GCT``.  Notice that because of the change in
canonical kmer from ``TCC`` to ``GGA`` the last kmer is not in sorted order.

Outputs from any form of the 'print' action can be gzip, bzip2 or xz
compressed by adding suffix '.gz', '.bz2' or 'xz' respectively to the
filename.  stdout output cannot be compressed.

A 'print' operation with just a meryl database (e.g., `meryl print
data.meryl`) will simply dump the kmers in 'data.meryl' to the screen.  If a
filename is supplied after print, it will write output to that file.


Inputs
------

For counting actions, inputs must be FASTA or FASTQ files, either
uncompressed or gzip, bzip2, xz compressed (with suffix '.gz', '.bz2' or
'.xz').  Any number of inputs may be supplied.  All kmers generated will be
in the same output database with no tracking of where they came from.

For all other actions, inputs can be a mix of other actions or meryl
databases.  Some actions require exactly one input (for example, 'filter')
while other actions can take any number of inputs (for example, 'union').

Modifiers
---------

The 'value', 'label' and 'kmer' modifiers serve slightly different purposes
depending on the action.

For **present-in** and **modify** actions, these modifiers describe how to
combine the input values and labels into a single output value or label.

For **filter** actions, these modifiers to describe how to select input kmers
for output.


When value:#c, value:first, value:min or value:max are used, the label
operation acts ONLY on the kmers matching the value selection.  For example,
if value:min finds value=5 is the minimu, label=or would combine the labels
of all kmers with value=5.  Contrast this with value:add (which would set the
output value to the sum of the kmer values in all databases) and label:and
(which would set each bit in the output label to true if the corresponding
bit is true in all inputs).

Likewise for label:#c, label:first, label:minweight and label:maxweight.  For
example, when label:#c is used, value:add would sum the values of all labels
that are the same as constant c.


Constants begin with a '#' symbol and end with a single letter denoting the
base: #011100b (binary), #34o (octal), #28d (decimal), #28 (decimal), #1ch
(hexadecimal) are all the same constant.  Note that a constant with no base
indicated is interpreted as being decimal.

Constants are optional.

Note that 'value:first' and 'label:first' are the value/label of the kmer in
the first file it is present in, which is not necessarily the first input
file.



Value Modifier
~~~~~~~~~~~~~~

For **present-in** and **modify** actions, the value of the kmer is set to:

  =============== ===============
  value:#c        constant c
  value:@f        the value of the kmer in the f'th input file
  =============== ===============

  =============== ===============
  value:first     that of the first input that the kmer is present in
  value:selected  that of the kmer selected by a label modifier (e.g., minweight, maxweight)
  =============== ===============

  =============== ===============
  value:min#c     the minimum of all values and constant c
  value:max#c     the maximum of all values and constant c
  =============== ===============

  =============== ===============
  value:add#c     the sum of all values and constant c
  value:sum#c     same as add
  =============== ===============

  =============== ===============
  value:sub#c     that of the first kmer (see value:first) minus all other values and constant c, thresholding to 0 if negative
  value:dif#c     same as sub
  =============== ===============

  =============== ===============
  value:mul#c     the multiplication of all values and c
  =============== ===============

  =============== ===============
  value:div#c     that of the first kmer (see value:first) divided by all other values and constant c.
                  the result of the division is truncated; value:mod can be used to get the remainder
  =============== ===============

  =============== ===============
  value:mod#c     that of the remainder of the corresponding value:div modifier
  value:rem#c     same as mod
  =============== ===============

  =============== ===============
  value:modzero#c the goofy one from merqury?
  =============== ===============

For **filter** actions, the kmer is output if the value is:

  =============== ===============
  value:=#c       is equal to c
  value:==#c      is equal to c
  =============== ===============

  =============== ===============
  value:!=#c      is not equal to c
  value:<>#c      is not equal to c
  =============== ===============

  =============== ===============
  value:<#c       is less than c
  value:>#c       is greater than c
  =============== ===============

  =============== ===============
  value:<=#c      is at most c
  value:>=#c      is at least c
  =============== ===============

Label Modifier
~~~~~~~~~~~~~~

For **present-in** and **modify** actions, the label of the kmer is set to:

  =============== ===============
  label:#c        constant c
  =============== ===============

  =============== ===============
  label:first     that of the first input that the kmer is present in
  label:selected  that of the kmdf selected by a value modifier (e.g., min, max)
  =============== ===============

  =============== ===============
  label:and#c     the bitwise AND of all labels and constant c
  label:or#c      the bitwise OR  of all labels and constant c
  label:xor#c     the bitwise XOR of all labels and constant c
  =============== ===============

  =============== ===============
  label:sub#c     that of the first input after subtracting (turning off) bits set in any other label or constant c
  =============== ===============

  =============== ===============
  label:inv       that of the bitwise invert (equivalent to label:xor#ffffffh)
  =============== ===============

  =================  ===============
  label:minweight#c  to the label (or constant) with the least bits set
  label:maxweight#c  to the label (or constant) with the most bits set
  =================  ===============

  =============== ===============
  label:shl#c     shift  label bits left  by c
  label:shr#c     shift  label bits right by c
  label:rol#c     rotate label bits left  by c
  label:ror#c     rotate label bits right by c
  =============== ===============

For **filter** actions, the kmer is output if the label is:

  =============== ===============
  label:=#c       is equal to c
  label:==#c      is equal to c
  =============== ===============

  =============== ===============
  label:!=#c      is not equal to c
  =============== ===============

  =============== ===============
  label:and#c     has at least one bit set that is also set in c
  label:or#c      nonsense
  label:xor#c     complicated
  =============== ===============

  =============== ===============
  label:weight=#c true if the number of bits set in >, =, < c
  =============== ===============

Kmer Modifier
~~~~~~~~~~~~~

This modifier is invalid for **present-in** and **modify** actions.

For **filter** actions, the kmer is output if:

  =============== ===============
  kmer:AT==X      output a kmer if the AT content is X
  kmer:AT!=X
  kmer:AT>X
  kmer:AT>=X
  kmer:AT<X
  kmer:AT<=X
  =============== ===============

  =============== ===============
  kmer:GC==X      output the kmer if the GC content is X
  kmer:GC!=X
  kmer:GC>X
  kmer:GC>=X
  kmer:GC<X
  kmer:GC<=X
  =============== ===============

  =============== ===============
  kmer:A==X       output if kmer has exactly, more than, less than X A's
  kmer:C==X
  kmer:G==X
  kmer:T==X
  =============== ===============

  =============== ===============
  kmer:[ACGTn]    output if kmer matches / does not match some pattern
  =============== ===============




Advanced Label Filtering
~~~~~~~~~~~~~~~~~~~~~~~~

To generalize the label tests, it is sufficient (is it?) to test if the label
is (is not) equal to C, or if the label is (is not) contained in or is (is
not) contained by the constant C.

A label is contained in a constant if the only bits set in the label are also
set in the constant.  Label `00` is contained in all constants, and
constant `11` contains all labels.

+------+----------+----------+------------------------------------+------------------------------------------+----------------------------------------+
| case | expression          | interpretation                     | interpretation                           | interpretation                         |
+======+=====================+====================================+==========================================+========================================+
|      | l == c   |          | L is     equal to C                |                                          |                                        |
|    0 +----------+----------+------------------------------------+------------------------------------------+----------------------------------------+
|      | l != c   |          | L is not equal to C                |                                          |                                        |
+------+----------+----------+------------------------------------+------------------------------------------+----------------------------------------+
|      |          |          |                                    |                                          |                                        |
+------+----------+----------+------------------------------------+------------------------------------------+----------------------------------------+
|    1 | l&c == l | l|c == c | L is       contained in C          | no bit     set in L that is not set in C | all  of the bits set in L are set in C |
+------+----------+----------+------------------------------------+------------------------------------------+----------------------------------------+
|    2 | l&c != l | l|c != c | L is   not contained in C          | a  bit     set in L that is not set in C |                                        |
+------+----------+----------+------------------------------------+------------------------------------------+----------------------------------------+
|    3 | l&c == c | l|c == l | L          contains     C          | no bit not set in L that is     set in C | all  of the bits set in C are set in L |
+------+----------+----------+------------------------------------+------------------------------------------+----------------------------------------+
|    4 | l&c != c | l|c != c | L does not contain      C          | a  bit not set in L that is     set in C |                                        |
+------+----------+----------+------------------------------------+------------------------------------------+----------------------------------------+
|      |          |          |                                    |                                          |                                        |
+------+----------+----------+------------------------------------+------------------------------------------+----------------------------------------+
|    5 | l&c == 0 |          | L and C have no set bits in common |                                          |                                        |
+------+----------+----------+------------------------------------+------------------------------------------+----------------------------------------+
|    6 | l&c != 0 |          | L and C have    set bits in common |                                          |                                        |
+------+----------+----------+------------------------------------+------------------------------------------+----------------------------------------+
|      |          |          |                                    |                                          |                                        |
+------+----------+----------+------------------------------------+------------------------------------------+----------------------------------------+

A general label filter can be specified by picking one of four functions for
each bit, then testing if: all functions are true, some function is true, or
no functions are true.  (this cannot capture the weight tests)

The four functions to modify a label before it is tested are:

.. code-block::

    '0' - zero(bit) =  0    - set testable bit to 0
    '1' - one (bit) =  1    - set testable bit to 1
    '+' - pass(bit) =  bit  - set testable bit to the true     label bit
    '-' - flip(bit) = !bit  - set testable bit to the inverted label bit

Once a label is modified by the functions, we can test if:

.. code-block::

    'all-1' -- all  bits are 1, no bits are 0 -- this roughly corresponds to an AND  operation
    'any-1' -- some bit  is  1                -- this roughly corresponds to an OR   operation
    'any-0' -- some bit  is  0                -- this roughly corresponds to an NAND operation
    'all-0' -- all  bits are 0, no bits are 1 -- this roughly corresponds to an NOR  operation

Examples:

.. code-block::

    label:-++--:all - true if the label is 01100

    label:00:all    - always false
    label:11:all    - always true
    label:--:all    - label must be 00
    label:++:all    - label must be 11

    label:00:any    - always false
    label:11:any    - always true
    label:--:any    - label cannot be 11
    label:++:any    - label cannot be 00

    label:00:none   - always true
    label:11:none   - always false
    label:--:none   - label must be 11
    label:++:none   - label must be 00

    label:0++:any   - label cannot be 000 or 100.

The tests in the table at the start of this section can be implemented as follows.

Case 0
++++++

For testing equality, convert the constant c into a string of +'s (for 1 bits)
and -'s (for 0 bits) then check that all bits are set.

For testing non-equality, invert the conversion (1 -> - and 0 -> +) then
check that any bit is set.  Proof: if the label is the same as the constant,
1 bits in the label will be inverted (to 0) and 0 bits in the label will be
output true (so also 0) resulting in a modified label of all 0's.  If a 1 bit
in the label corresponds to a 0 bit in the constant, it will be passed true
(a 1 in the modified label), similarly, a if a 0 bit in the label corresponds
to a 1 bit in the constant it will be passed inverted (a 1 in the modified
label), either of which will make the modified label not equal to zero.

Case 1
++++++

Both of these test that every bit set in L is also set in C, but C can have
extra bits set.

Convert the constant c into a string of 0's (for 1 bits) and +'s (for 0
bits), then check that no bit is set.

Where C is a 1, we don't care what L is; 'l&c == l' is true for both l=0 and
l=1.  By forcing these bits to 0 in the modified string, they will never
result in the check failing.

Where C is a 0, howeveer, L must be 0.  Hence, passing the L bit true will
result in a 1 bit output when L=1, which will cause the check to properly
fail.  When L=0, a 0 is outpout, and the check passes.

Case 2
++++++

The same as case 1, but change the check from "no bit is set" to "any bit is set".

Cases 3 and 4
+++++++++++++

Both are similar to cases 1 and 2.  Constant c is converted to +'s for 1's
and 1's for 0's, then the result is tested to check that all bits are set.
Thus, wherever c is set, l must also be set, and wherever c is not set, we
don't care what l is.

Case 4 is a bit tricky, since we need to check that some bit is zero -- and
there is no defined operation for that (other than "not all bits are set").

Cases 5 and 6
+++++++++++++

Case 5 is checking that L and C have no bits set in common, and case 6 is
checking that they do.

For case 5, C is converted to +'s for 1's and 0's for 0's, then check that no
bit is set.  For case 6, check that some bit is set.


===============
Action Ordering
===============

Meryl actions are greedy.  As the command line is processed left to right,
any inputs (either from databases or another action) will be assigned to the
last encountered action.  Square brackets ('[' and ']') can be used to assign
inputs to specific actions, by isolating actions and inputs.

Though not strictly required, square brackets can be used to disambiguate
actions and inputs.  Each nesting level can have at most one action and any
number of inputs.  The nesting level increases when either a new action or a
left bracket ('[') is encountered, but decreases only when a right bracket
(']') is encountered.

Some examples will clarify.  With no brackets, the command

.. code-block:: shell

  meryl
    union
      intersect
        a.meryl
        b.meryl
      intersect
        c.meryl
        d.meryl

expands to

.. code-block:: shell

  meryl
    [              #  Start new nesting level 0
    union          #  Level 0 action
      [            #  Level 0 input, start new nesting level 1
      intersect    #  Level 1 action
        a.meryl    #  Level 1 input
        a.meryl    #  Level 1 input
        [          #  Level 1 input, start new nesting level 2
        intersect  #  Level 2 action
          b.meryl  #  Level 2 input
          c.meryl  #  Level 2 input
        ]          #  Level 2 terminator
      ]            #  Level 1 terminator
    ]              #  Level 0 terminator

Note the 'union' action has only one input; the first 'intersect' action has
three inputs, and the last 'intersect' has two inputs.

As written, the intent is clear but square brackets must be used to communicate this
to meryl.

.. code-block:: shell

  meryl
    union
      [
      intersect
         a.meryl
         b.meryl
      ]
      [
      intersect
        c.meryl
        d.meryl
      ]

This can be written on one line as:

.. code-block:: shell

  meryl union [intersect a.meryl b.meryl] [intersect c.meryl d.meryl]

in particular, the square brackets will recognized even if they are not
separated from the action or input with white-space.

=============
Modify Action
=============

The 'modify' action changes the value or label.  This action operates on
exactly one input; if more than one input is supplied, the action is rejected
and meryl will return an error before any processing is performed.

Descriptions are largely the same as for present-in above, except there is no
other value, so operations occur between the current (single) value and the
constant.

=============
Filter Action
=============

The filter action accepts input from one source, and passes or discards kmers
according to the 'value' and 'label' rules supplied.

If more than one input is supplied, the action is rejected and meryl will
return an error.

Tests can be combined in a single filter action using a sum-of-products
format.  In a sum-of-products expression, AND takes precedence over OR.  In a
programming language, we'd write expressions such as
:math:`((\mathbf{A}\ and\ \mathbf{B})\ or\ (\mathbf{C}\ and\ \mathbf{D}))`.
In meryl, the :math:`\mathbf{A}`, :math:`\mathbf{B}`, et cetera, symbols are repaced with a **value**
or **label** modifier, and the parentheses are omitted.

A simple expression, output rare or common kmers:
 
.. code-block:: shell

 filter
    value:<#5 or value:>#1000

To output kmers with value between 3 and 9, or between 13 and 20, we'd write:

.. code-block:: shell

  filter
    value:>#3 and value:<#9 or value:>#13 and value:<#20

The contrasting style, **not supported in meryl**, is called a
product-of-sums expression.  In this, OR takes precedence over AND.  In a
programming language, we'd write expressions such as
:math:`((\mathbf{A})\ and\ (\mathbf{B}\ or\ \mathbf{C})\ and\ (\mathbf{D}))`.
Since this form is a bit awkward to use, and since `De Morgan's
laws <https://en.wikipedia.org/wiki/De_Morgan%27s_laws>`_ allow conversion
between the two, this form is, again, **not supported in meryl**.

============
Count Action
============

Described elsewhere??

=================
Present-In Action
=================

The 'present-in' action will emit a kmer based on the number of input files
it is present in, its "input-count" value.  If the kmer is not present in the
specified number of input files, it is discarded.  'present-in' takes a
comma-delimited list of integer ranges.

Assuming 9 input files, some examples are:

.. code-block::

  present-in:4,5,6  - output if present in 4 or 5 or 6 input files
  present-in:4-6,8  - output if present in 4 or 5 or 6 or 8 input files

Because meryl gets its kmers from the inputs, as opposed to iterating over
all possible kmers, every kmer that meryl processes will exist in at least
one input; therefore, 'present-in:0' is never true; further 'present-in:0-6'
and 'present-in:1-6' are exactly the same.

One additional flag is useful:

.. code-block::

  'first' - the kmer is present in the first input file

The 'first' flag is necessary to perform set difference operations:

.. code-block::

  present-in:1:first     - output if kmer exists only in the first input
                           (the kmer exists in one input AND
                            the kmer exists in the first input)

  present-in:first:2-9   - output if kmer exists in the first file and
                           some other file
                           (and, we'll see later, subtract the counts
                            in the other files from the count in the
                            first file)

Several synonyms exist:

.. code-block::

  present-in:n       - the number of input files (9 in the example above)
  present-in:all     - the number of input files
  present-in:any     - equivalent to 'present-in:1-all'
  present-in:only    - equivalent to 'in:1:first'

Aliases
~~~~~~~

Aliases exist to support common operations.  An alias sets the 'present-in',
'value' and 'label' options and so these are not allowed to be used with
aliases.

.. code-block::


========
EXAMPLES
========

Generate Counts
---------------


Generate Counts in Parallel
---------------------------


Extract Counts
--------------


Merqury
-------


Assign Labels to Sources
------------------------

Assign labels to kmers in an assembly based on the source database they are
present in.  Each kmer will have a label:

.. code-block:: none

   00b  if the kmer appears only in the assembly
   01b  if the kmer appears in db1
   10b  if the kmer appears in db2
   11b  if the kmer appears in both db1 and db1

.. code-block:: shell

  meryl \
    output final.meryl \
    modify label:and#011b \
    filter label:and#100b \
    union \
      [modify label:#100b asm.meryl] \
      [modify label:#001b db1.meryl] \
      [modify label:#010b db2.meryl]

Note that the 'modify label:and#011b' and 'filter label:and#100b' actions are
completely different, even though they look very similar.  The 'modify'
action will change a label L to 'L AND 011' (that is, retain only the rightmost
two bits in the label), while the 'filter' action will pass only kmers that
have a non-zero value for 'L AND 100' (that is, that have the third bit set in
the label).

An alternate method could intersect the two databases with the assembly kmers
first, then assign label.  This method does not, however, report kmers that
exist only in the assembly.  Note that the 'union' action will bitwise 'OR' the
labels together by default.

.. code-block:: shell

  meryl \
    output final.meryl \
    union \
      [modify label:#01b intersect asm.meryl db1.meryl] \
      [modify label:#10b intersect asm.meryl db2.meryl]

