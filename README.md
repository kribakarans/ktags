# Ktags: Source code tagging and navigation tool

Ktags makes it easy to use traditional source code tagging systems such as Cscope, Ctags, GNU Global's Gtags, Gscope and Htags.
Ktags use GNU Global's `htags-server` for HTML source code navugation.

## Usage: 
### `ktags [options]...`

## Command line options:
```
    -a  --all      -- Generate Ctags and Gtags
    -b  --browse   -- Start webserver and open browser to explore source code
    -c  --ctags    -- Generate only the Ctags
    -g  --gtags    -- Generate only the Gtags
    -D  --deploy   -- Deploy Ktags files into local webserver
    -d  --delete   -- Delete Ktags database files
    -V  --verbose  -- Enable verbose mode
    -v  --version  -- Print Ktags version
    -h  --help     -- Show this help menu
                   -- Running Ktags without arguments will generate
                      Ctags and Cscope databases
```
