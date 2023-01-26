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
    -a  --all       -- Generate both Ctags and Gtags symbols
    -b  --browse    -- Instantly explore the source code in web-browser at http://localhost:8888
    -c  --ctags     -- Generate tags with Ctags tool
    -g  --gtags     -- Generate tags eith Gtags tool
    -d  --delete    -- Delete tags database files in current path
    -i  --install   -- First time initialisation to install bash and vim scripts to the local user
    -u  --uninstall -- Uninstall the bash and vim scripts of the local user
    -v  --version   -- Print package version
    -V  --verbose   -- Enable debug mode
    -h  --help      -- Show this help menu
                    -- Running application without arguments will generate
                       Ctags and Cscope databases
```
### Generate Ktags cross-references (Xref)
Simply run `ktags --all` to generate Xref at current path

### Explore Xref with terminal
Run `cs` to start cscope session

### Explore Xref with browser
Run `ktags --browse` and explore the Xref at <http://localhost:8888>

### Clear Xref
Run `ktags --delete` to clear Ktags entries
