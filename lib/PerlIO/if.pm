package PerlIO::if;
use 5.008;
use strict;
use warnings;

use XSLoader;

our $VERSION;
XSLoader::load(__PACKAGE__, $VERSION);

1;

#ABSTRACT: Push layers conditionally
