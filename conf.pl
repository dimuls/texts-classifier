use utf8;

{
  lib_path => './lib',
  
  # Paths
      data_path => './data',
  articles_path => './data/articles',
      docs_path => './data/docs',
       img_path => './data/img',

  # Terms paramaters
  term_docs_count_upper_limit => 20,
  term_docs_count_lower_limit => 2,


  # Compund key generations paramaters
  frequency_classes_count => 4,
  frequency_classes_parts => {
    1 => 0.05, 2 => 0.10, 3 => 0.35, 4 => 0.50
  },
  
  # Fuzzy ART parameters
    beta => 0.6, # Fuzzy ART dynamics parameter
     rho => 0.7, # vigilance parameter
  lambda => 0.6, # learning rate parameter
}
