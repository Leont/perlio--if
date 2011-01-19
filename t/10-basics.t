# perl -T

use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use PerlIO::Layers qw/query_handle get_layers/;

my $fh;
lives_ok { open $fh, '<:if(buffered,pop)', $0; } 'Can open :if(buffered, pop)';
#diag $_ for PerlIO::get_layers($fh);
#diag Dump get_layers($fh);
ok !query_handle($fh, 'buffered'), 'Handle is no longer buffered';

ok binmode($fh, ':if(!buffered,crlf)'), 'binmode succedded';

ok query_handle($fh, 'buffered'), 'Handle is buffered again';
ok query_handle($fh, 'crlf'), 'Handle is crlf too';

done_testing;
