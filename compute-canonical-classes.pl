#!/usr/bin/perl

use utf8;
use warnings;
use strict;
use v5.14.2;

use YAML qw(DumpFile LoadFile);

my $docs = LoadFile "docs.yaml";
my $classes = {};

while( my ($doc_name, $doc) = each %$docs ) {
  my ($class, $subclass) = ($doc->{class}, $doc->{subclass});
  $classes->{$class} = {} unless defined $classes->{$class};
  $classes->{$class}->{$subclass} = [] unless defined $classes->{$class}->{$subclass};
  push @{$classes->{$class}->{$subclass}}, $doc_name
}

DumpFile "classes.yaml", $classes;
