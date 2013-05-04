#!/usr/bin/perl

use utf8;
use warnings;
use strict;
use v5.14.2;

use YAML;

use PDL;
use PDL::IO::FastRaw;

use lib './lib';

use Tools;
use ART;

my $conf = require 'conf.pl';

my $fqc = $conf->{frequency_classes_count};

my ($docs, $words, $words_ids) = load_data($conf->{processed_docs_path}, $conf->{docs_limit});
my $WF = zeros($words_count); # words frequency vector


my $S = readfraw("$conf->{data_path}/term-term-model");

my $art = new ART(%$conf);

$art->input($S);
my $out = $art->output;

say "Word clusters count: " . scalar(@$out);

say "Clusters:";
map {
  say "-> ".join(',', map {  utf8::encode($_); $_; } map { $words->{$_}->{name} } @$_ );
} grep {
  scalar @$_ > 1;
} @$out;

__DATA__

__PDLPP__

pp_def('fuzzy_and',
  Pars => 'a(n); b(n); [o]c(n);',
  Code => 'loop(n) %{
    if( $a() < $b() ) {
      $c() = $a();
    } else {
      $c() = $b();
    }
  %}'
);

pp_def('less_than',
  Pars => 'a(n); b(); [o]c();',
  Code => '
    $c() = 1;
    loop(n) %{
      if( $a() > $b() ) {
        $c() = 0;
        break;
      }
    %}'
);

pp_def('adapt',
  Pars => 'a(n); b(n); c();',
  Code => '
    loop(n) %{
      if( $a() <= $b() ) {
        $a() = $c() * $a() + (1 - $c()) * $a();
      } else {
        $a() = $c() * $b() + (1 - $c()) * $a();
      }
    %}'
);
