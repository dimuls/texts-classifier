#!/usr/bin/perl

use utf8;
use warnings;
use strict;
use v5.14.2;

use PDL::IO::FastRaw;

use lib './lib';

use Tools;
use ART;

my $conf = require 'conf.pl';

my $DT = mapfraw("$conf->{data_path}/document-term-model");

my $art = new ART(
    beta => 0.5,
  lambda => 0.6,
     rho => 0.2,
);

$art->input($DT);

say scalar @{$art->output};
