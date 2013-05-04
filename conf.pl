use utf8;

{
  # Docs parameters
  docs_path  => './docs',
  processed_docs_path  => './pdocs',
  docs_limit => undef,

  # Computed data files path
  data_path => './data',

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
