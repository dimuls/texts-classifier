#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use v5.14.2;

use YAML qw(LoadFile DumpFile);

my $conf = require('conf.pl');

my $docs = {};

my $cnt = 0;

open FILES, '-|', "find $conf->{docs_path} -type f";
while(<FILES>) {
  chomp;
  if( m|docs/([^/]+)/([^/]+)/([^/]+)$| ) {
    say "dublicated $_" if defined $docs->{$3};
    ++$cnt;
    $docs->{$3} = { class => $1, subclass => $2 };
  } else {
    say "something wrong with $_";
  }
}
close FILES;
say $cnt;

DumpFile('docs.yaml', $docs);
