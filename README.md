filters
================

A "snake_case" filter system to `R`.

## Installation

``` r
if (!requireNamespace("remotes")) {
  install.packages("remotes")
}
remotes::install_github(
  repo = "pharmaverse/filters",
  upgrade = "never"
)
```

## Features

``` r
library(filters)
library(magrittr)
library(random.cdisc.data)
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
  
  tern::t_events_per_term_id(
    terms = anl[, c("AEBODSYS", "AEDECOD")],
    id = anl$USUBJID,
    col_by = anl$ACTARM,
    col_N = table(datasets$adsl$ACTARM)
  )
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
                                                            A: Drug X             B: Placebo          C: Combination
                                                             (N=133)               (N=141)               (N=126)    
--------------------------------------------------------------------------------------------------------------------
- Any event -
  Total number of patients with at least one event         121 (90.98%)          128 (90.78%)          120 (95.24%) 
  Total number of events                                       601                   721                   645      

cl A.1
  Total number of patients with at least one event         73 (54.89%)           85 (60.28%)           69 (54.76%)  
  Total number of events                                       110                   144                   123      
  dcd A.1.1.1.1                                            45 (33.83%)           55 (39.01%)            47 (37.3%)  
  dcd A.1.1.1.2                                            41 (30.83%)           51 (36.17%)           45 (35.71%)  

cl B.1
  Total number of patients with at least one event         47 (35.34%)            43 (30.5%)            47 (37.3%)  
  Total number of events                                        65                    56                    62      
  dcd B.1.1.1.1                                            47 (35.34%)            43 (30.5%)            47 (37.3%)  

cl B.2
  Total number of patients with at least one event         65 (48.87%)           82 (58.16%)           82 (65.08%)  
  Total number of events                                       107                   133                   140      
  dcd B.2.1.2.1                                            46 (34.59%)           48 (34.04%)            47 (37.3%)  
  dcd B.2.2.3.1                                            37 (27.82%)           56 (39.72%)            48 (38.1%)  

cl C.1
  Total number of patients with at least one event         40 (30.08%)           45 (31.91%)           55 (43.65%)  
  Total number of events                                        53                    58                    73      
  dcd C.1.1.1.3                                            40 (30.08%)           45 (31.91%)           55 (43.65%)  

cl C.2
  Total number of patients with at least one event         47 (35.34%)           60 (42.55%)           60 (47.62%)  
  Total number of events                                        62                    87                    75      
  dcd C.2.1.2.1                                            47 (35.34%)           60 (42.55%)           60 (47.62%)  

cl D.1
  Total number of patients with at least one event         75 (56.39%)           88 (62.41%)           73 (57.94%)  
  Total number of events                                       124                   163                   122      
  dcd D.1.1.1.1                                            53 (39.85%)           62 (43.97%)            47 (37.3%)  
  dcd D.1.1.4.2                                            40 (30.08%)           58 (41.13%)           43 (34.13%)  

cl D.2
  Total number of patients with at least one event         57 (42.86%)           59 (41.84%)           40 (31.75%)  
  Total number of events                                        80                    80                    50      
  dcd D.2.1.5.3                                            57 (42.86%)           59 (41.84%)           40 (31.75%)  
```

``` r
vads %>% apply_filter("SER_SE") %>% t_ae()
```

    Filter 'SE' matched target ADSL.
    400/400 records matched the filter condition `SAFFL == 'Y'`.

    Filter 'SER' matched target ADAE.

    581/1967 records matched the filter condition `AESER == 'Y'`.

``` 
                                                            A: Drug X             B: Placebo          C: Combination
                                                             (N=133)               (N=141)               (N=126)    
--------------------------------------------------------------------------------------------------------------------
- Any event -
  Total number of patients with at least one event         88 (66.17%)           100 (70.92%)          93 (73.81%)  
  Total number of events                                       165                   228                   188      

cl A.1
  Total number of patients with at least one event         41 (30.83%)           51 (36.17%)           45 (35.71%)  
  Total number of events                                        52                    68                    62      
  dcd A.1.1.1.2                                            41 (30.83%)           51 (36.17%)           45 (35.71%)  

cl B.2
  Total number of patients with at least one event         37 (27.82%)           56 (39.72%)            48 (38.1%)  
  Total number of events                                        47                    73                    63      
  dcd B.2.2.3.1                                            37 (27.82%)           56 (39.72%)            48 (38.1%)  

cl D.1
  Total number of patients with at least one event         53 (39.85%)           62 (43.97%)            47 (37.3%)  
  Total number of events                                        66                    87                    63      
  dcd D.1.1.1.1                                            53 (39.85%)           62 (43.97%)            47 (37.3%)  
```

``` r
vads %>% apply_filter("CTC34_REL_SE") %>% t_ae()
```

    Filter 'SE' matched target ADSL.

    400/400 records matched the filter condition `SAFFL == 'Y'`.

    Filters 'CTC34', 'REL' matched target ADAE.

    367/1967 records matched the filter condition `AETOXGR %in% c('4', '5') & AREL == 'Y'`.

``` 
                                                            A: Drug X             B: Placebo          C: Combination
                                                             (N=133)               (N=141)               (N=126)    
--------------------------------------------------------------------------------------------------------------------
- Any event -
  Total number of patients with at least one event         72 (54.14%)           70 (49.65%)            79 (62.7%)  
  Total number of events                                       118                   114                   135      

cl B.1
  Total number of patients with at least one event         47 (35.34%)            43 (30.5%)            47 (37.3%)  
  Total number of events                                        65                    56                    62      
  dcd B.1.1.1.1                                            47 (35.34%)            43 (30.5%)            47 (37.3%)  

cl C.1
  Total number of patients with at least one event         40 (30.08%)           45 (31.91%)           55 (43.65%)  
  Total number of events                                        53                    58                    73      
  dcd C.1.1.1.3                                            40 (30.08%)           45 (31.91%)           55 (43.65%)  
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
