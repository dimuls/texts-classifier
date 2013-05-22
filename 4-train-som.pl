#!/usr/bin/perl

use utf8;
use warnings;
use strict;
use v5.14.2;

use PDL;
use PDL::IO::FastRaw;
use PDL::IO::GD;

use lib './lib';
use SOM;

my $conf = require 'conf.pl';

my $DT = mapfraw("$conf->{data_path}/doc-term-matrix");
#my $DT = mapfraw("$conf->{data_path}/tests/9-clusters");

my $som = new SOM(
  width => 10,
  height => 10,
  iter_limit => 4,
  error_limit => 0.001,
  alpha_zero => 0.1,
  show_progress_bar => 1,
  weights_init_type => 1,
);

$som->input($DT);
write_true_png($som->output_img, "$conf->{img_path}/som-doc-clusters.png");
