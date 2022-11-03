# Ktags: Source code tagging and navigation tool

Ktags makes it easy to use traditional source code tagging systems such as Cscope, Ctags, GNU Global's Gscope Gtags and Htags.

With `--browse` option allows you to explore C/C++ code in web-browser with syntax higlighting and cross references.<br>
GNU Global's `htags-server` web-server helps to explore the code in web-browser at <http://localhost:8888>.

## Requirements:
`cscope`, `ctags` and `global`.

## Usage: 
### `ktags [options]...`

**Command line options:**
```
    -a  --all      -- Generate both Ctags and Gtags symbols
    -b  --browse   -- Instantly explore the source code in web-browser at http://localhost:8888
    -c  --ctags    -- Generate tags with Ctags tool
    -g  --gtags    -- Generate tags eith Gtags tool
    -d  --delete   -- Delete tags database files in current path
    -V  --verbose  -- Enable debug mode
    -v  --version  -- Print package version
    -h  --help     -- Show this help menu
                   -- Running application without arguments will generate
                      Ctags and Cscope databases
```
