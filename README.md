filters
================

A "snake_case" filter system to `R`.

## Installation

``` r
if (!requireNamespace("remotes")) {
  install.packages("remotes")
}
remotes::install_github(
  repo = "openpharma/filters",
  upgrade = "never"
)
```

## Features

``` r
library(filters)
library(magrittr)
library(random.cdisc.data)
library(rtables)
library(tern)
set.seed(1)
adsl <- radsl()
adae <- radae(adsl)
vads <- list(adsl = adsl, adae = adae)
```

### Built-In Filters

`{filters}` comes with a built-in filter library. You can list them using `list_all_filters()`.

``` r
list_all_filters()
```

    # A tibble: 272 x 4
       id     title                      target condition                      
       <chr>  <chr>                      <chr>  <chr>                          
     1 COV    Confirmed/Suspected COVID… ADAE   ACOVFL == 'Y'                  
     2 COVAS  AEs Associated with COVID… ADAE   ACOVASFL == 'Y'                
     3 CTC35  Grade 3-5 Adverse Events   ADAE   ATOXGR %in% c('3', '4', '5')   
     4 DSC    Adverse Events Leading to… ADAE   AEACN == 'DRUG WITHDRAWN'      
     5 DSM    Adverse Events Leading to… ADAE   AEACN %in% c('DOSE INCREASED',…
     6 FATAL  Fatal Adverse Events       ADAE   AESDTH == 'Y'                  
     7 NCOV   Excluding Confirmed/Suspe… ADAE   ACOVFL != 'Y'                  
     8 NCOVAS AEs not Associated with C… ADAE   ACOVASFL != 'Y'                
     9 NFATAL Non-fatal Adverse Events   ADAE   AESDTH == 'N'                  
    10 NREL   Adverse Events not Relate… ADAE   AREL == 'N'                    
    # … with 262 more rows

### Adding New Filters

To add a new filter use `add_filter()`. The last argument, `condition`,
defines the condition to use to filter the datasets later on. It will be
passed to `subset()` when calling `apply_filter()`.

``` r
add_filter(
  id = "CTC34",
  title = "Grade 3-4 Adverse Events",
  target = "ADAE",
  condition = AETOXGR %in% c("4", "5")
)
```

Alternatively, you can use `load_filters()` to load filter definitions
from a yaml file. The file should be structured like this:

``` yaml
CTC4:
  title: Grade 4 Adverse Events
  target: ADAE
  condition: ATOXGR == "4"
TP53WT:
  title: TP53 Wild Type
  target: ADSL
  condition: TP53 == "WILD TYPE"
```

``` r
file_path <- system.file("filters_eg.yaml", package = "filters")
load_filters(file_path)
```

You can confirm that filters haven been successfully added by using
`get_filter()`.

``` r
get_filter("CTC34")
```

    $title
    [1] "Grade 3-4 Adverse Events"
    
    $target
    [1] "ADAE"
    
    $condition
    AETOXGR %in% c("4", "5")

If you ask for a non-existing filter `get_filter()` will throw an error.

``` r
get_filter("GIDIS")
```

    Error: Filter 'GIDIS' does not exist.

To overwrite an existing filter you will have to set `overwrite = TRUE`.
Otherwise an error is thrown.

``` r
add_filter(
  id = "FATAL",
  title = "Fatal Adverse Events",
  target = "ADAE",
  condition = ATOXGR == "5"
)
```

    Error: Filter 'FATAL' already exists. Set `overwrite = TRUE` to force overwriting the existing filter definition.

``` r
add_filter(
  id = "FATAL",
  title = "Fatal Adverse Events",
  target = "ADAE",
  condition = ATOXGR == "5",
  overwrite = TRUE
)
```

### Applying Filters to Datasets

You can use `apply_filter()` to filter a single dataset or a `list` of
multiple
    datasets.

``` r
adsl_se <- apply_filter(adsl, "SE")
```

    Filter 'SE' matched target ADSL.

    400/400 records matched the filter condition `SAFFL == 'Y'`.

``` r
adae_ctc34_ser <- apply_filter(adae, "CTC34_SER")
```

    Filters 'CTC34', 'SER' matched target ADAE.

    216/1967 records matched the filter condition `AETOXGR %in% c('4', '5') & AESER == 'Y'`.

``` r
filtered_datasets <- apply_filter(vads, "CTC34_SER_SE")
```

    Filter 'SE' matched target ADSL.

    400/400 records matched the filter condition `SAFFL == 'Y'`.

    Filters 'CTC34', 'SER' matched target ADAE.

    216/1967 records matched the filter condition `AETOXGR %in% c('4', '5') & AESER == 'Y'`.

As you can see `apply_filter()` gives you feedback on which IDs matched
the dataset. This matching is done by the name of the input dataset. It
does not matter whether the dataset name is in upper or lower case or a
mix of both.

``` r
ADSL <- adsl
adsl_it <- apply_filter(ADSL, "IT")
```

    Filter 'IT' matched target ADSL.

    400/400 records matched the filter condition `ITTFL == 'Y'`.

In case your dataset is not named in a standard way you can manually
tell `apply_filter()` which dataset it is by setting the `target`
argument.

``` r
sl <- adsl
sl_it1 <- apply_filter(sl, "IT")
```

    No filter matched target SL.

``` r
sl_it2 <- apply_filter(sl, "IT", target = "ADSL")
```

    Filter 'IT' matched target ADSL.

    400/400 records matched the filter condition `ITTFL == 'Y'`.

### Using {filters} for Generating Outputs

`{filters}` package works well with `{rtables}` and `{tern}` packages. See the
following example of creating a table by a function:

``` r
t_ae <- function(datasets) {
  anl <- merge(
    x = datasets$adsl,
    y = datasets$adae,
    by = c("STUDYID", "USUBJID"),
    all = FALSE, # inner join
    suffixes = c("", "_ADAE")
  )
  
  split_fun <- drop_split_levels

  lyt <- basic_table(show_colcounts = TRUE) %>%
  split_cols_by(var = "ARM") %>%
  add_overall_col(label = "All Patients") %>%
  analyze_num_patients(
    vars = "USUBJID",
    .stats = c("unique", "nonunique"),
    .labels = c(
      unique = "Total number of patients with at least one adverse event",
      nonunique = "Overall total number of events"
    )
  ) %>%
  split_rows_by(
    "AEBODSYS",
    child_labels = "visible",
    nested = FALSE,
    split_fun = split_fun,
    label_pos = "topleft",
    split_label = obj_label(adae$AEBODSYS)
  ) %>%
  summarize_num_patients(
    var = "USUBJID",
    .stats = c("unique", "nonunique"),
    .labels = c(
      unique = "Total number of patients with at least one adverse event",
      nonunique = "Total number of events"
    )
  ) %>%
  count_occurrences(
    vars = "AEDECOD",
    .indent_mods = -1L
  ) %>%
  append_varlabels(adae, "AEDECOD", indent = 1L)

  result <- build_table(
    lyt,
    df = datasets$adae,
    alt_counts_df = datasets$adsl
  )
  return(result)
}
```

You can easily create multiple outputs with this function by applying
the filters to the input datasets *before* passing them to
`t_ae()`.

``` r
vads %>% apply_filter("SE") %>% t_ae()
```

    Filter 'SE' matched target ADSL.

    400/400 records matched the filter condition `SAFFL == 'Y'`.

``` 
Body System or Organ Class                                    A: Drug X    B: Placebo    C: Combination   All Patients
  Dictionary-Derived Term                                      (N=133)       (N=141)        (N=126)         (N=400)   
——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
Total number of patients with at least one adverse event     111 (83.5%)   132 (93.6%)    119 (94.4%)     362 (90.5%) 
Overall total number of events                                   636           755            655             2046    
cl A.1                                                                                                                
  Total number of patients with at least one adverse event   63 (47.4%)    79 (56.0%)      71 (56.3%)     213 (53.2%) 
  Total number of events                                         123           144            133             400     
  dcd A.1.1.1.1                                              47 (35.3%)    63 (44.7%)      50 (39.7%)     160 (40.0%) 
  dcd A.1.1.1.2                                              42 (31.6%)    47 (33.3%)      44 (34.9%)     133 (33.2%) 
cl B.1                                                                                                                
  Total number of patients with at least one adverse event   47 (35.3%)    49 (34.8%)      59 (46.8%)     155 (38.8%) 
  Total number of events                                         73            63              75             211     
  dcd B.1.1.1.1                                              47 (35.3%)    49 (34.8%)      59 (46.8%)     155 (38.8%) 
cl B.2                                                                                                                
  Total number of patients with at least one adverse event   73 (54.9%)    88 (62.4%)      73 (57.9%)     234 (58.5%) 
  Total number of events                                         132           156            137             425     
  dcd B.2.1.2.1                                              44 (33.1%)    56 (39.7%)      50 (39.7%)     150 (37.5%) 
  dcd B.2.2.3.1                                              48 (36.1%)    59 (41.8%)      44 (34.9%)     151 (37.8%) 
cl C.1                                                                                                                
  Total number of patients with at least one adverse event   50 (37.6%)    53 (37.6%)      42 (33.3%)     145 (36.2%) 
  Total number of events                                         62            75              62             199     
  dcd C.1.1.1.3                                              50 (37.6%)    53 (37.6%)      42 (33.3%)     145 (36.2%) 
cl C.2                                                                                                                
  Total number of patients with at least one adverse event   50 (37.6%)    65 (46.1%)      50 (39.7%)     165 (41.2%) 
  Total number of events                                         67            87              63             217     
  dcd C.2.1.2.1                                              50 (37.6%)    65 (46.1%)      50 (39.7%)     165 (41.2%) 
cl D.1                                                                                                                
  Total number of patients with at least one adverse event   74 (55.6%)    95 (67.4%)      72 (57.1%)     241 (60.2%) 
  Total number of events                                         120           158            112             390     
  dcd D.1.1.1.1                                              37 (27.8%)    59 (41.8%)      35 (27.8%)     131 (32.8%) 
  dcd D.1.1.4.2                                              54 (40.6%)    63 (44.7%)      48 (38.1%)     165 (41.2%) 
cl D.2                                                                                                                
  Total number of patients with at least one adverse event   43 (32.3%)    54 (38.3%)      56 (44.4%)     153 (38.2%) 
  Total number of events                                         59            72              73             204     
  dcd D.2.1.5.3                                              43 (32.3%)    54 (38.3%)      56 (44.4%)     153 (38.2%) 
```

``` r
vads %>% apply_filter("SER_SE") %>% t_ae()
```

    Filter 'SE' matched target ADSL.
    400/400 records matched the filter condition `SAFFL == 'Y'`.

    Filter 'SER' matched target ADAE.

    581/1967 records matched the filter condition `AESER == 'Y'`.

``` 
Body System or Organ Class                                   A: Drug X    B: Placebo    C: Combination   All Patients
  Dictionary-Derived Term                                     (N=133)       (N=141)        (N=126)         (N=400)   
—————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
Total number of patients with at least one adverse event     93 (69.9%)   110 (78.0%)     98 (77.8%)     301 (75.2%) 
Overall total number of events                                  248           280            246             774     
cl A.1                                                                                                               
  Total number of patients with at least one adverse event   42 (31.6%)   47 (33.3%)      44 (34.9%)     133 (33.2%) 
  Total number of events                                         54           63              58             175     
  dcd A.1.1.1.2                                              42 (31.6%)   47 (33.3%)      44 (34.9%)     133 (33.2%) 
cl B.1                                                                                                               
  Total number of patients with at least one adverse event   47 (35.3%)   49 (34.8%)      59 (46.8%)     155 (38.8%) 
  Total number of events                                         73           63              75             211     
  dcd B.1.1.1.1                                              47 (35.3%)   49 (34.8%)      59 (46.8%)     155 (38.8%) 
cl B.2                                                                                                               
  Total number of patients with at least one adverse event   48 (36.1%)   59 (41.8%)      44 (34.9%)     151 (37.8%) 
  Total number of events                                         74           78              65             217     
  dcd B.2.2.3.1                                              48 (36.1%)   59 (41.8%)      44 (34.9%)     151 (37.8%) 
cl D.1                                                                                                               
  Total number of patients with at least one adverse event   37 (27.8%)   59 (41.8%)      35 (27.8%)     131 (32.8%) 
  Total number of events                                         47           76              48             171     
  dcd D.1.1.1.1                                              37 (27.8%)   59 (41.8%)      35 (27.8%)     131 (32.8%) 
```


## (Current) Limitations

The filters you created using `add_filter()` only persist for the
duration of your `R` session. That means that whenever you restart your
`R` session you will have to re-create them. The simplest way to do so
is by putting all your filter definitions inside a file `filters.yml`
file as described above and call `load_filters("path/to/filters.yml")`
before creating outputs.

If you pass an existing filter that does not match your target dataset
no warning or error is thrown. Instead `apply_filter()` only tells you
which filters it actually used. Thus, checking that only valid filters
are passed to `apply_filter()` is up to you.

``` r
add_filter(
  id = "INFCT",
  title = "Infections and Infestations",
  target = "ADAE",
  condition = AEBODSYS == "INFECTIONS AND INFESTATIONS"
)
adsl_filtered <- apply_filter(adsl, "DIABP_IT")
```

    Filter 'IT' matched target ADSL.

    400/400 records matched the filter condition `ITTFL == 'Y'`.

## How Does it Work?

Internally, `{filters}` stores the filter definitions inside the
`.filters` environment defined in `R/zzz.R`. When you add a filter with
`add_filter()` a new variable with the name of the ID is created inside
this environment. This variable is a list that stores the title, target
and condition as a quoted expression. When you use `apply_filter()` the
function looks for variables in `.filters` matching the provided
suffixes. It then maps the filters to their target datasets and finally
builds a call to `subset()` with the dataset as first and condition for
the filters as second argument. This call is then evaluated using
`eval()` and the result is returned.
