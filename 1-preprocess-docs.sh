#!/bin/bash
articles_path='./data/articles';
docs_path='./data/docs';
subclass_limit=99999;

doc_id=0;
echo '---' > data/docs-ids.yml;

rm $docs_path/*

#for file in `find docs -type f`
#for class_doc in `ls $articles_path`
for class_doc in economics sport
do
  for subclass_doc in `ls $articles_path/$class_doc`
  do
    for file_path in `find $articles_path/$class_doc/$subclass_doc -type f | head -n $subclass_limit`
    do
      file_name=`basename $file_path`;
      echo "$file_name: $doc_id" >> data/docs-ids.yml;
      cat $file_path | mystem -e utf8 -lfn | perl -se '
      binmode STDOUT, ":utf8";
      binmode STDIN, ":utf8";
      use YAML qw(Dump);
      my $stopwords = require("stopwords.pl");
      my $doc = {
        id => $id,
        name => $name,
        words => {},
      };
      while(<>) {
        my ($max_freq, $max_word);
        foreach( split /\|/ ) {
          my ($word, $freq) = split /\??:/;
          ($max_freq, $max_word)=($freq, $word || $max_word) unless defined $max_freq or $max_freq >= $freq
        } 
        next if defined $stopwords->{$max_word} or $max_word eq "";
        $doc->{words}->{$max_word}++;
      }
      print Dump($doc);
      ' -- -id=$doc_id -name=$file_name > $docs_path/$file_name;
      let doc_id+=1;
    done
  done
done
