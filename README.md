# Sensu plugin for monitoring real memory and swap usage

A sensu plugin to monitor real memory and swap usage.

## Usage

The plugin accepts the following command line options:

```
        --available                  Check thresholds against memory available
    -c, --crit <PERCENTAGE>          Critical if PERCENTAGE exceeds current memory available/used
        --swap                       Check SWAP rather than real memory (default: false)
        --used                       Check thresholds against memory used
    -w, --warn <PERCENTAGE>          Warn if PERCENTAGE exceeds current memory available/used
```

## Author
Matteo Cerutti - <matteo.cerutti@hotmail.co.uk>
