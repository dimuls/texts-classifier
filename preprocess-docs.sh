#!/bin/bash
#for file in `find docs -type f`
subclass_limit=10
for class_doc in `ls docs`
do
  for subclass_doc in `ls docs/$class_doc`
  do
    for file in `find docs/$class_doc/$subclass_doc -type f | head -n $subclass_limit`
    do
      cat $file | mystem -e utf8 -lfn | perl -e '
      use utf8;
      my $stopwords = require("stopwords.pl");
      my %word_counts;
      while(<>) {
        utf8::decode($_);
        my ($max_freq, $max_word);
        foreach( split /\|/ ) {
          my ($word, $freq) = split /\??:/;
          ($max_freq, $max_word)=($freq, $word) unless defined $max_freq or $max_freq >= $freq
        } 
        $word_counts{$max_word}++
      }
      foreach( keys %word_counts ) {
        next if $stopwords->{$_} or $_ eq "";
        my $out = "$_:$word_counts{$_}\n" if $_ ne "";
        utf8::encode($out);
        print $out;
      }' > pdocs/`basename $file`;
    done
  done
done
